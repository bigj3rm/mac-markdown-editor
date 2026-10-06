import Foundation

/// The file being edited: its text, and what is known to be on disk.
///
/// This type only tracks state. Reading, writing and asking the user are left to `WorkspaceStore`.
nonisolated struct OpenDocument: Equatable {
    let url: URL
    /// The editor's text, which may differ from what is on disk.
    var text: String

    /// The text as last read from or written to disk.
    private(set) var savedText: String
    /// True when the file was deleted or moved after it was opened. The text stays so it can still be copied or saved again.
    private(set) var isMissingOnDisk = false
    /// Goes up each time the text is replaced from disk, so the editor knows to reset its undo history.
    private(set) var revision = 0

    init(url: URL, text: String) {
        self.url = url
        self.text = text
        savedText = text
    }

    /// A missing file counts as unsaved so the text is protected until it is saved again.
    var hasUnsavedChanges: Bool {
        isMissingOnDisk || text != savedText
    }

    // MARK: - Changes

    /// Records that the editor text is now on disk, which also recreates a missing file.
    mutating func markSaved() {
        savedText = text
        isMissingOnDisk = false
    }

    /// Replaces the editor text with what is on disk, discarding any edits.
    mutating func replaceWithDiskText(_ diskText: String) {
        text = diskText
        savedText = diskText
        isMissingOnDisk = false
        revision += 1
    }

    /// Keeps the editor text and treats the current disk contents as the new baseline.
    ///
    /// This stops the same outside change from being reported again. If the text differs, it counts as unsaved.
    mutating func keepEdits(againstDiskText diskText: String) {
        savedText = diskText
        isMissingOnDisk = false
    }

    mutating func markMissing() {
        isMissingOnDisk = true
    }
}
