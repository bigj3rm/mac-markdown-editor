import Foundation
@testable import markdown_editor

/// A `WorkspacePrompting` that gives canned answers and records what it was asked.
///
/// It is a class so tests can read back what the store asked after the fact.
final class StubPrompter: WorkspacePrompting {
    /// One question about a file that changed outside the editor.
    struct ExternalChangeQuestion: Equatable {
        let fileName: String
        let hasUnsavedEdits: Bool
    }

    /// The folder `chooseFolder()` returns; `nil` acts like the user cancelling.
    var folderToChoose: URL?
    /// The default is `.cancel`, so a prompt a test didn't expect never discards anything.
    var unsavedChangesAnswer = UnsavedChangesChoice.cancel
    /// The default keeps the editor's text, so a prompt a test didn't expect never discards anything.
    var externalChangeAnswer = ExternalChangeChoice.keepMine
    /// Runs at the start of every question, to simulate things that happen while a dialog is open.
    var duringQuestion: (() -> Void)?

    /// The file names of every unsaved-changes question asked, in order.
    private(set) var unsavedChangesQuestions: [String] = []
    private(set) var externalChangeQuestions: [ExternalChangeQuestion] = []

    func chooseFolder() -> URL? {
        duringQuestion?()
        return folderToChoose
    }

    func askAboutUnsavedChanges(fileName: String) -> UnsavedChangesChoice {
        unsavedChangesQuestions.append(fileName)
        duringQuestion?()
        return unsavedChangesAnswer
    }

    func askAboutExternalChange(fileName: String, hasUnsavedEdits: Bool) -> ExternalChangeChoice {
        externalChangeQuestions.append(ExternalChangeQuestion(fileName: fileName, hasUnsavedEdits: hasUnsavedEdits))
        duringQuestion?()
        return externalChangeAnswer
    }
}
