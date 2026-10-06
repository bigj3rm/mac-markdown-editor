import Foundation
import Testing
@testable import markdown_editor

/// Opening folders and files, saving, and the prompt shown before leaving unsaved edits.
struct WorkspaceStoreTests {
    // MARK: - Folders

    @Test func choosingAFolderShowsItAsTheRootWithOnlyItsTopLevelContents() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "", "sub/deep.md": ""])
        let store = fixture.store

        #expect(store.rootFolder?.url == fixture.folder.url)
        #expect(store.children(of: fixture.folder.url).map(\.name) == ["sub", "a.md"])

        let subfolder = try fixture.rootChild(named: "sub")
        #expect(store.children(of: subfolder.url).isEmpty)
    }

    @Test func expandingAFolderLoadsItsContents() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")

        fixture.store.reloadChildren(of: subfolder.url)

        #expect(fixture.store.children(of: subfolder.url).map(\.name) == ["deep.md"])
    }

    @Test func expandingAFolderAgainPicksUpFilesAddedInTheMeantime() throws {
        let fixture = try WorkspaceFixture(files: ["sub/one.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.reloadChildren(of: subfolder.url)

        try fixture.folder.makeFile("sub/two.md")
        fixture.store.reloadChildren(of: subfolder.url)

        #expect(fixture.store.children(of: subfolder.url).map(\.name) == ["one.md", "two.md"])
    }

    @Test func cancellingTheFolderPanelChangesNothing() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": ""])
        fixture.prompter.folderToChoose = nil

        fixture.store.chooseFolder()

        #expect(fixture.store.rootFolder?.url == fixture.folder.url)
    }

    @Test func aFolderThatCannotBeListedShowsAnAlertAndKeepsTheCurrentOne() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": ""])
        fixture.prompter.folderToChoose = fixture.folder.url(for: "missing")

        fixture.store.chooseFolder()

        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.store.rootFolder?.url == fixture.folder.url)
    }

    // MARK: - Opening files

    @Test func openingAFileShowsItsText() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "# A"])

        fixture.open("a.md")

        #expect(fixture.store.text == "# A")
        #expect(fixture.store.selectedFileName == "a.md")
        #expect(!fixture.store.hasUnsavedChanges)
    }

    @Test func switchingFilesAlwaysShowsTheLatestTextFromDisk() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "old A", "b.md": "B"])
        fixture.open("a.md")
        fixture.open("b.md")

        try fixture.folder.makeFile("a.md", contents: "new A")
        fixture.open("a.md")

        #expect(fixture.store.text == "new A")
    }

    @Test func openingAFileThatCannotBeReadShowsAnAlertAndKeepsTheCurrentFile() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        fixture.open("a.md")
        try fixture.folder.removeItem("b.md")

        fixture.open("b.md")

        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.text == "A")
    }

    // MARK: - Saving

    @Test func savingWritesTheEditorTextAndClearsTheUnsavedFlag() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])
        fixture.open("a.md")
        fixture.store.text = "edited"
        #expect(fixture.store.hasUnsavedChanges)

        let saved = fixture.store.saveCurrentFile()

        #expect(saved)
        #expect(!fixture.store.hasUnsavedChanges)
        #expect(try fixture.folder.contents(of: "a.md") == "edited")
    }

    @Test func aFailedSaveShowsAnAlertAndKeepsTheText() throws {
        let fixture = try WorkspaceFixture(files: ["sub/a.md": "A"])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.reloadChildren(of: subfolder.url)
        fixture.open("sub/a.md")
        fixture.store.text = "edited"
        try fixture.folder.removeItem("sub")

        let saved = fixture.store.saveCurrentFile()

        #expect(!saved)
        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.store.text == "edited")
        #expect(fixture.store.hasUnsavedChanges)
    }

    // MARK: - Unsaved edits when switching

    @Test func switchingFilesWithoutEditsNeverAsks() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        fixture.open("a.md")

        fixture.open("b.md")

        #expect(fixture.prompter.unsavedChangesQuestions.isEmpty)
        #expect(fixture.store.selectedFileName == "b.md")
    }

    @Test func cancellingTheSwitchPromptKeepsTheCurrentFileAndItsEdits() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        fixture.open("a.md")
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .cancel

        fixture.open("b.md")

        #expect(fixture.prompter.unsavedChangesQuestions == ["a.md"])
        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.text == "edited")
    }

    @Test func discardingAtTheSwitchPromptOpensTheOtherFileWithoutSaving() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        fixture.open("a.md")
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .discard

        fixture.open("b.md")

        #expect(fixture.store.selectedFileName == "b.md")
        #expect(fixture.store.text == "B")
        #expect(try fixture.folder.contents(of: "a.md") == "A")
    }

    @Test func savingAtTheSwitchPromptWritesTheEditsThenOpensTheOtherFile() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        fixture.open("a.md")
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .save

        fixture.open("b.md")

        #expect(try fixture.folder.contents(of: "a.md") == "edited")
        #expect(fixture.store.selectedFileName == "b.md")
    }

    @Test func aFailedSaveAtTheSwitchPromptStaysOnTheCurrentFile() throws {
        let fixture = try WorkspaceFixture(files: ["sub/a.md": "A", "b.md": "B"])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.reloadChildren(of: subfolder.url)
        fixture.open("sub/a.md")
        fixture.store.text = "edited"
        try fixture.folder.removeItem("sub")
        fixture.prompter.unsavedChangesAnswer = .save

        fixture.open("b.md")

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.text == "edited")
    }

    @Test func choosingAnotherFolderWithUnsavedEditsAsksFirst() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])
        let otherFolder = try TemporaryFolder()
        fixture.open("a.md")
        fixture.store.text = "edited"
        fixture.prompter.folderToChoose = otherFolder.url
        fixture.prompter.unsavedChangesAnswer = .cancel

        fixture.store.chooseFolder()

        #expect(fixture.prompter.unsavedChangesQuestions == ["a.md"])
        #expect(fixture.store.rootFolder?.url == fixture.folder.url)
        #expect(fixture.store.text == "edited")
    }
}
