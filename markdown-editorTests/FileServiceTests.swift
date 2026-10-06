import Foundation
import Testing
@testable import markdown_editor

/// Folder listing, file reading and writing, and comparing a file with the editor's text.
struct FileServiceTests {
    // MARK: - Listing folders

    @Test func listsFoldersFirstThenMarkdownFilesInNameOrder() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("b.md")
        try folder.makeFile("a.md")
        try folder.makeFolder("zeta")
        try folder.makeFolder("alpha")

        let names = try FileService.contents(ofFolder: folder.url).map(\.name)

        #expect(names == ["alpha", "zeta", "a.md", "b.md"])
    }

    @Test func skipsHiddenItemsAndFilesThatAreNotMarkdown() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("notes.md")
        try folder.makeFile("notes.txt")
        try folder.makeFile(".hidden.md")

        let names = try FileService.contents(ofFolder: folder.url).map(\.name)

        #expect(names == ["notes.md"])
    }

    @Test func readsOnlyOneLevel() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("sub/deep.md")

        let names = try FileService.contents(ofFolder: folder.url).map(\.name)

        #expect(names == ["sub"])
    }

    @Test func listingAMissingFolderThrows() throws {
        let folder = try TemporaryFolder()

        #expect(throws: FileServiceError.self) {
            try FileService.contents(ofFolder: folder.url(for: "missing"))
        }
    }

    // MARK: - Reading and writing

    @Test func writtenTextReadsBack() throws {
        let folder = try TemporaryFolder()
        let fileURL = folder.url(for: "note.md")

        try FileService.writeText("# Hello", to: fileURL)

        #expect(try FileService.readText(at: fileURL) == "# Hello")
    }

    @Test func readingAMissingFileThrows() throws {
        let folder = try TemporaryFolder()

        #expect(throws: FileServiceError.self) {
            try FileService.readText(at: folder.url(for: "missing.md"))
        }
    }

    @Test func writingIntoAMissingFolderThrows() throws {
        let folder = try TemporaryFolder()

        #expect(throws: FileServiceError.self) {
            try FileService.writeText("text", to: folder.url(for: "missing/note.md"))
        }
    }

    // MARK: - Comparing with the disk

    @Test func aFileWithTheKnownTextIsUnchanged() throws {
        let folder = try TemporaryFolder()
        let fileURL = try folder.makeFile("note.md", contents: "known")

        #expect(try FileService.diskState(of: fileURL, comparedTo: "known") == .unchanged)
    }

    @Test func rewritingAFileWithIdenticalTextIsStillUnchanged() throws {
        let folder = try TemporaryFolder()
        let fileURL = try folder.makeFile("note.md", contents: "known")

        try folder.makeFile("note.md", contents: "known")

        #expect(try FileService.diskState(of: fileURL, comparedTo: "known") == .unchanged)
    }

    @Test func aFileWithDifferentTextIsChangedAndCarriesTheDiskText() throws {
        let folder = try TemporaryFolder()
        let fileURL = try folder.makeFile("note.md", contents: "edited elsewhere")

        let state = try FileService.diskState(of: fileURL, comparedTo: "known")

        #expect(state == .changed(diskText: "edited elsewhere"))
    }

    @Test func aDeletedFileIsMissing() throws {
        let folder = try TemporaryFolder()
        let fileURL = try folder.makeFile("note.md", contents: "known")
        try folder.removeItem("note.md")

        #expect(try FileService.diskState(of: fileURL, comparedTo: "known") == .missing)
    }

    @Test func aFileWhoseFolderWasDeletedIsMissing() throws {
        let folder = try TemporaryFolder()
        let fileURL = try folder.makeFile("sub/note.md", contents: "known")
        try folder.removeItem("sub")

        #expect(try FileService.diskState(of: fileURL, comparedTo: "known") == .missing)
    }

    @Test func aFileThatCannotBeReadAsTextThrowsInsteadOfBeingCalledMissing() throws {
        let folder = try TemporaryFolder()
        let fileURL = folder.url(for: "binary.md")
        try Data([0xFF, 0xFE, 0x00]).write(to: fileURL)

        #expect(throws: FileServiceError.self) {
            try FileService.diskState(of: fileURL, comparedTo: "known")
        }
    }
}
