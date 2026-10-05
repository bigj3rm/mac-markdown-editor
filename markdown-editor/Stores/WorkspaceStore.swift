import Foundation
import Observation

/// The state of the one open workspace: the folder, the file being edited, and its text.
///
/// Views read this and call its methods; all file reading and writing goes through `FileService`.
@MainActor
@Observable
final class WorkspaceStore {
    /// The text in the editor, which may differ from what is saved on disk.
    var text = ""
    var presentedAlert: AlertMessage?

    private(set) var rootFolder: FileNode?
    private(set) var selectedFileURL: URL?

    private var savedText = ""
    private var childrenByFolder: [URL: [FileNode]] = [:]

    var hasUnsavedChanges: Bool {
        selectedFileURL != nil && text != savedText
    }

    var selectedFileName: String? {
        selectedFileURL?.lastPathComponent
    }

    // MARK: - Folders

    /// Lets the user pick a folder and shows it as the root of the tree.
    func chooseFolder() {
        guard confirmDiscardingChanges() else { return }
        guard let folderURL = FolderPicker.chooseFolder() else { return }

        do {
            let nodes = try FileService.contents(ofFolder: folderURL)
            rootFolder = FileNode(url: folderURL, isFolder: true)
            childrenByFolder = [folderURL: nodes]
            closeFile()
        } catch {
            presentedAlert = AlertMessage(error: error)
        }
    }

    /// The loaded contents of a folder, or an empty list if it hasn't been expanded yet.
    func children(of folderURL: URL) -> [FileNode] {
        childrenByFolder[folderURL] ?? []
    }

    /// Reads a folder's contents the first time it is expanded.
    func loadChildren(of folderURL: URL) {
        guard childrenByFolder[folderURL] == nil else { return }

        do {
            childrenByFolder[folderURL] = try FileService.contents(ofFolder: folderURL)
        } catch {
            presentedAlert = AlertMessage(error: error)
        }
    }

    // MARK: - Files

    /// Opens a file in the editor, first asking what to do with unsaved edits to the current one.
    func openFile(at fileURL: URL) {
        guard fileURL != selectedFileURL else { return }
        guard confirmDiscardingChanges() else { return }

        do {
            let contents = try FileService.readText(at: fileURL)
            selectedFileURL = fileURL
            text = contents
            savedText = contents
        } catch {
            presentedAlert = AlertMessage(error: error)
        }
    }

    /// Writes the editor text to the open file. Returns `false` if there was an error, which is also shown to the user.
    @discardableResult
    func saveCurrentFile() -> Bool {
        guard let fileURL = selectedFileURL else { return true }

        do {
            try FileService.writeText(text, to: fileURL)
            savedText = text
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

        switch UnsavedChangesPrompt.ask(fileName: fileName) {
        case .save: return saveCurrentFile()
        case .discard: return true
        case .cancel: return false
        }
    }

    private func closeFile() {
        selectedFileURL = nil
        text = ""
        savedText = ""
    }
}
