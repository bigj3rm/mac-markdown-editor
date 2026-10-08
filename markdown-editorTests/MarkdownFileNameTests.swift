import Testing
@testable import markdown_editor

/// Which typed names are accepted for a new markdown file, and how `.md` is added.
struct MarkdownFileNameTests {
    // MARK: - Extension

    @Test func addsTheMarkdownExtensionWhenItIsLeftOff() {
        #expect(MarkdownFileName(typedText: "notes")?.value == "notes.md")
    }

    @Test(arguments: ["notes.md", "notes.MD", "Notes.Md"])
    func keepsAnExtensionThatIsAlreadyThere(typedText: String) {
        #expect(MarkdownFileName(typedText: typedText)?.value == typedText)
    }

    @Test func otherExtensionsAreNotReplacedSoTheFileStillShowsInTheTree() {
        #expect(MarkdownFileName(typedText: "notes.txt")?.value == "notes.txt.md")
    }

    // MARK: - Allowed names

    @Test func spacesAndNonLatinLettersAreFine() {
        #expect(MarkdownFileName(typedText: "meeting notes 2026")?.value == "meeting notes 2026.md")
        #expect(MarkdownFileName(typedText: "メモ")?.value == "メモ.md")
    }

    @Test func surroundingWhitespaceIsTrimmed() {
        #expect(MarkdownFileName(typedText: "  notes  \n")?.value == "notes.md")
    }

    // MARK: - Rejected names

    @Test(arguments: ["", "   ", "\n"])
    func emptyNamesAreRejected(typedText: String) {
        #expect(MarkdownFileName(typedText: typedText) == nil)
    }

    @Test(arguments: ["a/b", "folder/", "a:b", "../escape"])
    func namesWithPathSeparatorsAreRejected(typedText: String) {
        #expect(MarkdownFileName(typedText: typedText) == nil)
    }

    @Test(arguments: [".hidden", ".md", "..", "."])
    func namesStartingWithADotAreRejectedBecauseTheTreeHidesThem(typedText: String) {
        #expect(MarkdownFileName(typedText: typedText) == nil)
    }

    @Test func controlCharactersAreRejected() {
        #expect(MarkdownFileName(typedText: "two\nlines") == nil)
        #expect(MarkdownFileName(typedText: "tab\there") == nil)
    }

    @Test func namesLongerThanTheFileSystemAllowsAreRejected() {
        let tooLong = String(repeating: "a", count: 253)
        let justFits = String(repeating: "a", count: 252)

        #expect(MarkdownFileName(typedText: tooLong) == nil)
        #expect(MarkdownFileName(typedText: justFits)?.value.utf8.count == 255)
    }
}
