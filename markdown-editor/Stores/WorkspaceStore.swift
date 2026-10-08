import Foundation
import Observation

/// The state of the one open workspace: the folder, the file being edited, and its text.
///
/// Views read this and call its methods; all file reading and writing goes through `FileService`,
/// and every question to the user goes through the `WorkspacePrompting` it was given.
@MainActor
@Observable
final class WorkspaceStore {
    var presentedAlert: AlertMessage?

    /// The row highlighted in the tree. It follows clicks, then returns to the open file if that file didn't open.
    var treeSelection: URL?

    private(set) var rootFolder: FileNode?

    private var document: OpenDocument?
    private var childrenByFolder: [URL: [FileNode]] = [:]
    private let prompter: any WorkspacePrompting
    /// Dialogs run their own event loop, which can deliver more checks (such as the app becoming active) while one is open.
    private var isAskingUser = false

    init(prompter: any WorkspacePrompting) {
        self.prompter = prompter
    }

    /// Creates a store that asks its questions with system dialogs.
    convenience init() {
        self.init(prompter: SystemPrompter())
    }

    // MARK: - Open file state

    /// The text in the editor, which may differ from what is saved on disk.
    var text: String {
        get { document?.text ?? "" }
        set { document?.text = newValue }
    }

    var selectedFileURL: URL? {
        document?.url
    }

    var selectedFileName: String? {
        document?.url.lastPathComponent
    }

    var hasUnsavedChanges: Bool {
        document?.hasUnsavedChanges ?? false
    }

    /// True when the open file was deleted or moved outside the editor. Its text is still here.
    var isMissingOnDisk: Bool {
        document?.isMissingOnDisk ?? false
    }

    /// Changes whenever the text is replaced from disk, so the editor can reset its undo history.
    var documentRevision: Int {
        document?.revision ?? 0
    }

    // MARK: - Folders

    /// Lets the user pick a folder and shows it as the root of the tree.
    func chooseFolder() {
        guard confirmDiscardingChanges() else { return }
        guard let folderURL = ask({ prompter.chooseFolder() }) else { return }

        do {
            let nodes = try FileService.contents(ofFolder: folderURL)
            rootFolder = FileNode(url: folderURL, isFolder: true)
            childrenByFolder = [folderURL: nodes]
            document = nil
            treeSelection = nil
        } catch {
            presentedAlert = AlertMessage(error: error)
        }
    }

    /// The loaded contents of a folder, or an empty list if it hasn't been expanded yet.
    func children(of folderURL: URL) -> [FileNode] {
        childrenByFolder[folderURL] ?? []
    }

    /// Re-reads a folder's contents. A folder is read each time it is expanded, so its list is never stale.
    func reloadChildren(of folderURL: URL) {
        do {
            childrenByFolder[folderURL] = try FileService.contents(ofFolder: folderURL)
        } catch {
            presentedAlert = AlertMessage(error: error)
        }
    }

    /// Re-reads every folder already loaded, so files added or removed elsewhere appear.
    ///
    /// This runs on its own, so a folder that can't be read is dropped without an alert.
    private func refreshLoadedFolders() {
        for folderURL in Array(childrenByFolder.keys) {
            childrenByFolder[folderURL] = try? FileService.contents(ofFolder: folderURL)
        }
    }

    // MARK: - Tree selection

    /// Opens the file the user clicked in the tree.
    ///
    /// A clicked folder just stays highlighted and nothing else happens. Otherwise the highlight ends up on
    /// the open file, so a cancelled or failed switch snaps back.
    func treeSelectionChanged() {
        if let clickedURL = treeSelection, isFolder(clickedURL) {
            return
        }
        if let clickedURL = treeSelection {
            openFile(at: clickedURL)
        }
        treeSelection = selectedFileURL
    }

    /// Whether the tree shows this URL as a folder. Rows come from the listings, so this needs no disk access.
    private func isFolder(_ url: URL) -> Bool {
        if rootFolder?.url == url {
            return true
        }
        return childrenByFolder.values.contains { listing in
            listing.contains { $0.url == url && $0.isFolder }
        }
    }

    // MARK: - Files

    /// Opens a file in the editor, first asking what to do with unsaved edits to the current one.
    func openFile(at fileURL: URL) {
        guard fileURL != selectedFileURL else { return }
        guard confirmDiscardingChanges() else { return }

        do {
            let contents = try FileService.readText(at: fileURL)
            document = OpenDocument(url: fileURL, text: contents)
            treeSelection = fileURL
        } catch {
            presentedAlert = AlertMessage(error: error)
            // The tree may still list a file that has since been deleted.
            refreshLoadedFolders()
        }
    }

    /// Writes the editor text to the open file. Returns `false` if nothing was written, in which case the user has been told why.
    ///
    /// If the file changed on disk since it was last read, the user is asked first. A missing file is created again.
    @discardableResult
    func saveCurrentFile() -> Bool {
        guard let openDocument = document else { return true }
        guard resolveExternalChanges() else { return false }

        do {
            try FileService.writeText(openDocument.text, to: openDocument.url)
            document?.markSaved()
            return true
        } catch {
            presentedAlert = AlertMessage(error: error)
            return false
        }
    }

    /// Returns `true` when it is safe to replace or close the current file.
    ///
    /// With unsaved edits it asks the user first, and saves if they choose to.
    func confirmDiscardingChanges() -> Bool {
        guard hasUnsavedChanges, let fileName = selectedFileName else { return true }

        let choice = ask { prompter.askAboutUnsavedChanges(fileName: fileName) }
        switch choice {
        case .save: return saveCurrentFile()
        case .discard: return true
        case .cancel: return false
        }
    }

    // MARK: - Changes made outside the editor

    /// Brings the tree and the open file up to date with the disk. Called when the app returns to the front.
    func refreshFromDisk() {
        refreshLoadedFolders()
        resolveExternalChanges()
    }

    /// Compares the open file with the disk and deals with any difference.
    ///
    /// Returns `false` when a pending save should stop: the user chose to reload, or the file couldn't be checked.
    @discardableResult
    private func resolveExternalChanges() -> Bool {
        guard let openDocument = document, !isAskingUser else { return true }

        do {
            switch try FileService.diskState(of: openDocument.url, comparedTo: openDocument.savedText) {
            case .unchanged:
                if openDocument.isMissingOnDisk {
                    // The file is back exactly as it was last saved.
                    document?.keepEdits(againstDiskText: openDocument.savedText)
                }
                return true
            case .missing:
                document?.markMissing()
                return true
            case .changed(let diskText):
                return resolveChange(toDiskText: diskText, in: openDocument)
            }
        } catch {
            presentedAlert = AlertMessage(error: error)
            return false
        }
    }

    /// Applies the user's choice for a file whose disk contents differ from what the editor last saw.
    private func resolveChange(toDiskText diskText: String, in openDocument: OpenDocument) -> Bool {
        // The disk already matches what is on screen, for example because the file was restored, so there is nothing to ask.
        if diskText == openDocument.text {
            document?.keepEdits(againstDiskText: diskText)
            return true
        }

        let choice = ask {
            prompter.askAboutExternalChange(
                fileName: openDocument.url.lastPathComponent,
                hasUnsavedEdits: openDocument.hasUnsavedChanges
            )
        }
        switch choice {
        case .reload:
            document?.replaceWithDiskText(diskText)
            return false
        case .keepMine:
            document?.keepEdits(againstDiskText: diskText)
            return true
        }
    }

    // MARK: - Dialogs

    /// Runs a question to the user while recording that one is open.
    private func ask<Answer>(_ question: () -> Answer) -> Answer {
        isAskingUser = true
        defer { isAskingUser = false }
        return question()
    }
}
