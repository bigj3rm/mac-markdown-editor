import Foundation

/// The questions the workspace asks the user. The app shows system dialogs; tests give canned answers.
@MainActor
protocol WorkspacePrompting {
    /// Returns the folder to open, or `nil` if the user cancelled.
    func chooseFolder() -> URL?

    /// Asks what to do with unsaved edits to the named file.
    func askAboutUnsavedChanges(fileName: String) -> UnsavedChangesChoice

    /// Asks whether to reload the named file after another program changed it.
    func askAboutExternalChange(fileName: String, hasUnsavedEdits: Bool) -> ExternalChangeChoice
}
