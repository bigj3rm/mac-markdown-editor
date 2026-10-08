import Foundation
import Testing
@testable import markdown_editor

/// That the highlighted tree row always ends up on the file that is actually open.
struct WorkspaceStoreTreeSelectionTests {
    /// Clicks a file the way the sidebar does: the highlight moves first, then the store is told.
    private func click(_ relativePath: String, in fixture: WorkspaceFixture) {
        fixture.store.treeSelection = fixture.folder.url(for: relativePath)
        fixture.store.treeSelectionChanged()
    }

    @Test func clickingAFileOpensItAndLeavesTheHighlightOnIt() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])

        click("a.md", in: fixture)

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    @Test func cancellingTheSavePromptMovesTheHighlightBackToTheOpenFile() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        click("a.md", in: fixture)
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .cancel

        click("b.md", in: fixture)

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    @Test func discardingAtTheSavePromptMovesTheHighlightToTheNewFile() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        click("a.md", in: fixture)
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .discard

        click("b.md", in: fixture)

        #expect(fixture.store.selectedFileName == "b.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "b.md"))
    }

    @Test func aFileThatFailsToOpenMovesTheHighlightBackToTheOpenFile() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B"])
        click("a.md", in: fixture)
        try fixture.folder.removeItem("b.md")

        click("b.md", in: fixture)

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    @Test func deselectingKeepsTheOpenFileHighlighted() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])
        click("a.md", in: fixture)

        fixture.store.treeSelection = nil
        fixture.store.treeSelectionChanged()

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    // MARK: - Folders

    @Test func clickingAFolderKeepsItHighlightedWithoutAnAlertOrAChangeToTheEditor() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "sub/deep.md": "deep"])
        click("a.md", in: fixture)
        let subfolder = try fixture.rootChild(named: "sub")

        fixture.store.treeSelection = subfolder.url
        fixture.store.treeSelectionChanged()

        #expect(fixture.store.treeSelection == subfolder.url)
        #expect(fixture.store.presentedAlert == nil)
        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.text == "A")
    }

    @Test func clickingAFolderNeverAsksAboutUnsavedEdits() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "sub/deep.md": "deep"])
        click("a.md", in: fixture)
        fixture.store.text = "edited"
        let subfolder = try fixture.rootChild(named: "sub")

        fixture.store.treeSelection = subfolder.url
        fixture.store.treeSelectionChanged()

        #expect(fixture.prompter.unsavedChangesQuestions.isEmpty)
        #expect(fixture.store.text == "edited")
        #expect(fixture.store.hasUnsavedChanges)
    }

    @Test func clickingAFolderWithNoFileOpenIsAlsoQuiet() throws {
        let fixture = try WorkspaceFixture(files: ["sub/deep.md": "deep"])
        let subfolder = try fixture.rootChild(named: "sub")

        fixture.store.treeSelection = subfolder.url
        fixture.store.treeSelectionChanged()

        #expect(fixture.store.treeSelection == subfolder.url)
        #expect(fixture.store.presentedAlert == nil)
        #expect(fixture.store.selectedFileURL == nil)
    }

    @Test func clickingAFileAfterAFolderOpensItNormally() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "sub/deep.md": "deep"])
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.treeSelection = subfolder.url
        fixture.store.treeSelectionChanged()

        click("a.md", in: fixture)

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    @Test func cancellingASwitchMovesTheHighlightBackToTheOpenFileNotTheFolder() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A", "b.md": "B", "sub/deep.md": "deep"])
        click("a.md", in: fixture)
        let subfolder = try fixture.rootChild(named: "sub")
        fixture.store.treeSelection = subfolder.url
        fixture.store.treeSelectionChanged()
        fixture.store.text = "edited"
        fixture.prompter.unsavedChangesAnswer = .cancel

        click("b.md", in: fixture)

        #expect(fixture.store.selectedFileName == "a.md")
        #expect(fixture.store.treeSelection == fixture.folder.url(for: "a.md"))
    }

    @Test func openingAFolderClearsTheHighlight() throws {
        let fixture = try WorkspaceFixture(files: ["a.md": "A"])
        click("a.md", in: fixture)
        let otherFolder = try TemporaryFolder()
        fixture.prompter.folderToChoose = otherFolder.url
        fixture.prompter.unsavedChangesAnswer = .discard

        fixture.store.chooseFolder()

        #expect(fixture.store.treeSelection == nil)
        #expect(fixture.store.selectedFileURL == nil)
    }
}
