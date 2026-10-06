import Foundation
import Testing
@testable import markdown_editor

/// A `WorkspaceStore` opened on a temporary folder, with a stub prompter that records its questions.
struct WorkspaceFixture {
    let folder: TemporaryFolder
    let prompter: StubPrompter
    let store: WorkspaceStore

    /// Creates the given files (path to contents) and opens their folder in a new store.
    init(files: [String: String] = [:]) throws {
        folder = try TemporaryFolder()
        for (path, contents) in files {
            try folder.makeFile(path, contents: contents)
        }
        prompter = StubPrompter()
        store = WorkspaceStore(prompter: prompter)

        prompter.folderToChoose = folder.url
        store.chooseFolder()
    }

    /// Opens a file in the folder through the store, like clicking it in the tree.
    func open(_ relativePath: String) {
        store.openFile(at: folder.url(for: relativePath))
    }

    /// The listing node for a direct child of the root folder.
    func rootChild(named name: String) throws -> FileNode {
        try #require(store.children(of: folder.url).first { $0.name == name })
    }
}
