import Foundation

/// A name typed for a new markdown file, checked for characters that can't be used and given its `.md` extension.
nonisolated struct MarkdownFileName: Equatable {
    /// The full file name, always ending in `.md`.
    let value: String

    private static let pathExtension = ".md"
    private static let hiddenFilePrefix = "."
    // A slash separates folders, and a colon shows up as a slash in Finder.
    private static let forbiddenCharacters = CharacterSet(charactersIn: "/:").union(.controlCharacters)
    private static let maximumByteCount = 255

    /// Returns `nil` when the text can't be used: it is empty, contains a forbidden character, is too long,
    /// or starts with a dot (the tree hides such files, so the new file would seem to vanish).
    init?(typedText: String) {
        let trimmed = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.hasPrefix(Self.hiddenFilePrefix),
              trimmed.rangeOfCharacter(from: Self.forbiddenCharacters) == nil else { return nil }

        let hasExtension = trimmed.lowercased().hasSuffix(Self.pathExtension)
        let name = hasExtension ? trimmed : trimmed + Self.pathExtension
        guard name.utf8.count <= Self.maximumByteCount else { return nil }
        value = name
    }
}
