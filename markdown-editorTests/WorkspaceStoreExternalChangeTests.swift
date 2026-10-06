import Foundation
import Testing
@testable import markdown_editor

/// What the store does when files or folders change outside the editor.
struct WorkspaceStoreExternalChangeTests {
    /// A fixture with `note.md` already open.
    private func makeFixtureWithOpenNote(contents: String = "original") throws -> WorkspaceFixture {
        let fixture = try WorkspaceFixture(files: ["note.md": contents])
        fixture.open("note.md")
        return fixture
    }

    // MARK: - File changed outside

    @Test func anUnchangedFileIsNotReportedWhenTheAppReturns() throws {
        let fixture = try makeFixtureWithOpenNote()

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions.isEmpty)
        #expect(!fixture.store.hasUnsavedChanges)
    }

    @Test func reloadingShowsTheNewDiskTextAndClearsTheUndoHistory() throws {
        let fixture = try makeFixtureWithOpenNote()
        let revisionBefore = fixture.store.documentRevision
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.prompter.externalChangeAnswer = .reload

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions == [.init(fileName: "note.md", hasUnsavedEdits: false)])
        #expect(fixture.store.text == "edited elsewhere")
        #expect(!fixture.store.hasUnsavedChanges)
        #expect(fixture.store.documentRevision == revisionBefore + 1)
    }

    @Test func keepingTheCurrentTextAfterAnOutsideChangeLeavesTheEditorAsItWasButUnsaved() throws {
        let fixture = try makeFixtureWithOpenNote()
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.prompter.externalChangeAnswer = .keepMine

        fixture.store.refreshFromDisk()

        #expect(fixture.store.text == "original")
        #expect(fixture.store.hasUnsavedChanges)
    }

    @Test func aChangeThatWasKeptIsNotReportedAgainOnTheNextReturn() throws {
        let fixture = try makeFixtureWithOpenNote()
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.store.refreshFromDisk()

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions.count == 1)
    }

    @Test func aSecondOutsideChangeAfterKeepingIsReportedAgain() throws {
        let fixture = try makeFixtureWithOpenNote()
        try fixture.folder.makeFile("note.md", contents: "first change")
        fixture.store.refreshFromDisk()

        try fixture.folder.makeFile("note.md", contents: "second change")
        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions.count == 2)
    }

    @Test func theQuestionMentionsUnsavedEditsWhenThereAreSome() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions == [.init(fileName: "note.md", hasUnsavedEdits: true)])
    }

    @Test func reloadingDiscardsUnsavedEdits() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.prompter.externalChangeAnswer = .reload

        fixture.store.refreshFromDisk()

        #expect(fixture.store.text == "edited elsewhere")
        #expect(!fixture.store.hasUnsavedChanges)
    }

    @Test func keepingUnsavedEditsLetsTheNextSaveReplaceTheDiskVersionWithoutAskingAgain() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.store.refreshFromDisk()

        let saved = fixture.store.saveCurrentFile()

        #expect(saved)
        #expect(try fixture.folder.contents(of: "note.md") == "my edits")
        #expect(fixture.prompter.externalChangeQuestions.count == 1)
    }

    @Test func restoringTheFileWithExactlyTheTextOnScreenAsksNothing() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "same on both sides"
        try fixture.folder.makeFile("note.md", contents: "same on both sides")

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions.isEmpty)
        #expect(!fixture.store.hasUnsavedChanges)
    }

    // MARK: - Checking at save time

    @Test func savingAfterAnOutsideChangeAsksFirstAndKeepingContinuesTheSave() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.prompter.externalChangeAnswer = .keepMine

        let saved = fixture.store.saveCurrentFile()

        #expect(saved)
        #expect(fixture.prompter.externalChangeQuestions.count == 1)
        #expect(try fixture.folder.contents(of: "note.md") == "my edits")
    }

    @Test func savingAfterAnOutsideChangeAndChoosingReloadCancelsTheSave() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        fixture.prompter.externalChangeAnswer = .reload

        let saved = fixture.store.saveCurrentFile()

        #expect(!saved)
        #expect(fixture.store.text == "edited elsewhere")
        #expect(try fixture.folder.contents(of: "note.md") == "edited elsewhere")
    }

    @Test func aFileThatCannotBeReadAsTextShowsAnAlertAndTheSaveDoesNotOverwriteIt() throws {
        let fixture = try makeFixtureWithOpenNote()
        fixture.store.text = "my edits"
        let noteURL = fixture.folder.url(for: "note.md")
        try Data([0xFF, 0xFE, 0x00]).write(to: noteURL)

        let saved = fixture.store.saveCurrentFile()

        #expect(!saved)
        #expect(fixture.store.presentedAlert != nil)
        #expect(try Data(contentsOf: noteURL) == Data([0xFF, 0xFE, 0x00]))
    }

    // MARK: - Dialogs that arrive while another is open

    @Test func returningToTheAppWhileAQuestionIsOpenDoesNotStackASecondQuestion() throws {
        let fixture = try makeFixtureWithOpenNote()
        try fixture.folder.makeFile("note.md", contents: "edited elsewhere")
        let store = fixture.store
        fixture.prompter.duringQuestion = { store.refreshFromDisk() }

        store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions.count == 1)
    }

    // MARK: - File deleted or moved

    @Test func aDeletedFileKeepsItsTextOnScreenAndCountsAsUnsaved() throws {
        let fixture = try makeFixtureWithOpenNote(contents: "precious words")
        try fixture.folder.removeItem("note.md")

        fixture.store.refreshFromDisk()

        #expect(fixture.store.isMissingOnDisk)
        #expect(fixture.store.text == "precious words")
        #expect(fixture.store.hasUnsavedChanges)
        #expect(fixture.prompter.externalChangeQuestions.isEmpty)
        #expect(fixture.store.presentedAlert == nil)
    }

    @Test func savingRecreatesTheDeletedFileWithTheTextOnScreen() throws {
        let fixture = try makeFixtureWithOpenNote(contents: "precious words")
        fixture.store.text = "precious words, edited"
        try fixture.folder.removeItem("note.md")
        fixture.store.refreshFromDisk()

        let saved = fixture.store.saveCurrentFile()

        #expect(saved)
        #expect(try fixture.folder.contents(of: "note.md") == "precious words, edited")
        #expect(!fixture.store.isMissingOnDisk)
        #expect(!fixture.store.hasUnsavedChanges)
    }

    @Test func savingWhenTheFolderIsAlsoGoneShowsAnAlertAndKeepsTheText() throws {
        let fixture = try WorkspaceFixture(files: ["sub/note.md": "precious words"])
        fixture.open("sub/note.md")
        try fixture.folder.removeItem("sub")
        fixture.store.refreshFromDisk()

        let saved = fixture.store.saveCurrentFile()

        #expect(!saved)
        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.store.text == "precious words")
        #expect(fixture.store.isMissingOnDisk)
    }

    @Test func switchingAwayFromADeletedFileAsksSoTheTextIsNotLostByAccident() throws {
        let fixture = try WorkspaceFixture(files: ["note.md": "precious words", "other.md": "other"])
        fixture.open("note.md")
        try fixture.folder.removeItem("note.md")
        fixture.store.refreshFromDisk()
        fixture.prompter.unsavedChangesAnswer = .cancel

        fixture.open("other.md")

        #expect(fixture.prompter.unsavedChangesQuestions == ["note.md"])
        #expect(fixture.store.selectedFileName == "note.md")
    }

    @Test func choosingSaveWhenSwitchingAwayFromADeletedFileRecreatesItFirst() throws {
        let fixture = try WorkspaceFixture(files: ["note.md": "precious words", "other.md": "other"])
        fixture.open("note.md")
        try fixture.folder.removeItem("note.md")
        fixture.store.refreshFromDisk()
        fixture.prompter.unsavedChangesAnswer = .save

        fixture.open("other.md")

        #expect(try fixture.folder.contents(of: "note.md") == "precious words")
        #expect(fixture.store.selectedFileName == "other.md")
    }

    @Test func aDeletedFileThatComesBackIdenticalClearsTheWarningQuietly() throws {
        let fixture = try makeFixtureWithOpenNote(contents: "same")
        try fixture.folder.removeItem("note.md")
        fixture.store.refreshFromDisk()
        try fixture.folder.makeFile("note.md", contents: "same")

        fixture.store.refreshFromDisk()

        #expect(!fixture.store.isMissingOnDisk)
        #expect(!fixture.store.hasUnsavedChanges)
        #expect(fixture.prompter.externalChangeQuestions.isEmpty)
    }

    @Test func aDeletedFileThatComesBackDifferentAsksWhatToDo() throws {
        let fixture = try makeFixtureWithOpenNote(contents: "before")
        try fixture.folder.removeItem("note.md")
        fixture.store.refreshFromDisk()
        try fixture.folder.makeFile("note.md", contents: "different")

        fixture.store.refreshFromDisk()

        #expect(fixture.prompter.externalChangeQuestions == [.init(fileName: "note.md", hasUnsavedEdits: true)])
        #expect(!fixture.store.isMissingOnDisk)
    }

    // MARK: - Folder listings

    @Test func returningToTheAppShowsFilesAddedAndRemovedInLoadedFolders() throws {
        let fixture = try WorkspaceFixture(files: ["keep.md": "", "gone.md": ""])
        try fixture.folder.makeFile("new.md")
        try fixture.folder.removeItem("gone.md")

        fixture.store.refreshFromDisk()

        #expect(fixture.store.children(of: fixture.folder.url).map(\.name) == ["keep.md", "new.md"])
    }

    @Test func foldersThatWereNeverExpandedStayUnloaded() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")

        fixture.store.refreshFromDisk()

        #expect(fixture.store.children(of: subfolder.url).isEmpty)
    }

    @Test func aLoadedFolderThatWasDeletedIsDroppedWithoutAnAlert() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.reloadChildren(of: subfolder.url)
        try fixture.folder.removeItem("sub")

        fixture.store.refreshFromDisk()

        #expect(fixture.store.children(of: subfolder.url).isEmpty)
        #expect(fixture.store.children(of: fixture.folder.url).isEmpty)
        #expect(fixture.store.presentedAlert == nil)
    }

    @Test func openingAFileThatNoLongerExistsRefreshesTheStaleRow() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "", "b.md": ""])
        try fixture.folder.removeItem("b.md")

        fixture.open("b.md")

        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.store.children(of: fixture.folder.url).map(\.name) == ["a.md"])
    }
}
