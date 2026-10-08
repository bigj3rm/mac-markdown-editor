import Foundation
import Testing
@testable import markdown_editor

/// Creating a new markdown file: which folder it goes in, name handling, and that nothing else is disturbed.
struct WorkspaceStoreNewFileTests {
    /// Highlights a row the way the sidebar does when it is clicked.
    private func highlight(_ url: URL, in fixture: WorkspaceFixture) {
        fixture.store.treeSelection = url
        fixture.store.treeSelectionChanged()
    }

    private func listedNames(in folderURL: URL, of fixture: WorkspaceFixture) -> [String] {
        fixture.store.children(of: folderURL).map(\.name)
    }

    // MARK: - Which folder

    @Test func withNothingHighlightedTheFileGoesInTheRootFolder() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": ""])
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(try fixture.folder.contents(of: "fresh.md") == "")
        #expect(listedNames(in: fixture.folder.url, of: fixture) == ["a.md", "fresh.md"])
        #expect(fixture.prompter.newFileNameQuestions.first?.folderName == fixture.folder.url.lastPathComponent)
    }

    @Test func aHighlightedFolderGetsTheFile() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        highlight(subfolder.url, in: fixture)
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(try fixture.folder.contents(of: "sub/fresh.md") == "")
        #expect(!FileManager.default.fileExists(atPath: fixture.folder.url(for: "fresh.md").path))
        #expect(listedNames(in: subfolder.url, of: fixture) == ["deep.md", "fresh.md"])
        #expect(fixture.prompter.newFileNameQuestions.first?.folderName == "sub")
    }

    @Test func aHighlightedFileInASubfolderGetsTheFileInThatSubfolder() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.reloadChildren(of: subfolder.url)
        let deepFile = try #require(fixture.store.children(of: subfolder.url).first)
        highlight(deepFile.url, in: fixture)
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(try fixture.folder.contents(of: "sub/fresh.md") == "")
        #expect(listedNames(in: subfolder.url, of: fixture) == ["deep.md", "fresh.md"])
    }

    @Test func aHighlightedFileInTheRootGetsTheFileInTheRoot() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "", "sub/deep.md": ""])
        highlight(fixture.folder.url(for: "a.md"), in: fixture)
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(try fixture.folder.contents(of: "fresh.md") == "")
        #expect(!FileManager.default.fileExists(atPath: fixture.folder.url(for: "sub/fresh.md").path))
    }

    @Test func aFolderThatWasNeverExpandedStillShowsTheNewFileWhenItIsOpened() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        highlight(subfolder.url, in: fixture)
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(listedNames(in: subfolder.url, of: fixture).contains("fresh.md"))
    }

    // MARK: - Doing nothing

    @Test func withNoFolderOpenNothingIsAskedOrCreated() {
        let prompter = StubPrompter()
        let store = WorkspaceStore(prompter: prompter)

        store.createMarkdownFile()

        #expect(!store.hasOpenFolder)
        #expect(prompter.newFileNameQuestions.isEmpty)
        #expect(store.presentedAlert == nil)
    }

    @Test func cancellingCreatesNothing() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": ""])
        fixture.prompter.newFileNameAnswers = [nil]

        fixture.store.createMarkdownFile()

        #expect(fixture.prompter.newFileNameQuestions.count == 1)
        #expect(listedNames(in: fixture.folder.url, of: fixture) == ["a.md"])
        #expect(fixture.store.presentedAlert == nil)
    }

    @Test func theOpenFileItsEditsAndTheHighlightAreLeftAlone() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])
        fixture.open("a.md")
        fixture.store.text = "unsaved edit"
        let highlightBefore = fixture.store.treeSelection
        fixture.prompter.newFileNameAnswers = ["fresh"]

        fixture.store.createMarkdownFile()

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.text == "unsaved edit")
        #expect(fixture.store.hasUnsavedChanges)
        #expect(fixture.store.treeSelection == highlightBefore)
        #expect(fixture.prompter.unsavedChangesQuestions.isEmpty)
    }

    // MARK: - Names

    @Test func theMarkdownExtensionIsAddedButNeverDoubled() throws {
        let fixture = try WorkspaceFixture()
        fixture.prompter.newFileNameAnswers = ["plain", "already.md"]

        fixture.store.createMarkdownFile()
        fixture.store.createMarkdownFile()

        #expect(listedNames(in: fixture.folder.url, of: fixture) == ["already.md", "plain.md"])
    }

    @Test func aTakenNameAsksAgainWithTheTextKeptAndNeverOverwrites() throws {
        let fixture = try WorkspaceFixture(files: ["taken.md": "precious"])
        fixture.prompter.newFileNameAnswers = ["taken", "second try"]

        fixture.store.createMarkdownFile()

        let questions = fixture.prompter.newFileNameQuestions
        #expect(questions.count == 2)
        #expect(questions[0].notice == nil)
        #expect(questions[1].suggestedText == "taken")
        #expect(questions[1].notice?.contains("already exists") == true)
        #expect(try fixture.folder.contents(of: "taken.md") == "precious")
        #expect(try fixture.folder.contents(of: "second try.md") == "")
    }

    @Test func aNameThatCannotBeUsedAsksAgain() throws {
        let fixture = try WorkspaceFixture()
        fixture.prompter.newFileNameAnswers = ["a/b", "fine"]

        fixture.store.createMarkdownFile()

        let questions = fixture.prompter.newFileNameQuestions
        #expect(questions.count == 2)
        #expect(questions[1].suggestedText == "a/b")
        #expect(questions[1].notice != nil)
        #expect(listedNames(in: fixture.folder.url, of: fixture) == ["fine.md"])
    }

    @Test func cancellingTheSecondAskCreatesNothing() throws {
        let fixture = try WorkspaceFixture(files: ["taken.md": ""])
        fixture.prompter.newFileNameAnswers = ["taken", nil]

        fixture.store.createMarkdownFile()

        #expect(listedNames(in: fixture.folder.url, of: fixture) == ["taken.md"])
        #expect(fixture.store.presentedAlert == nil)
    }

    // MARK: - Failures

    @Test func aFolderThatIsGoneShowsAnAlertAndDoesNotAskAgain() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": ""])
        let subfolder = try fixture.rootChild(named: "sub")
        highlight(subfolder.url, in: fixture)
        try fixture.folder.removeItem("sub")
        fixture.prompter.newFileNameAnswers = ["fresh", "unused"]

        fixture.store.createMarkdownFile()

        #expect(fixture.store.presentedAlert != nil)
        #expect(fixture.prompter.newFileNameQuestions.count == 1)
    }
}
