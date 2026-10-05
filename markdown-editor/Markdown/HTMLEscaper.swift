import Foundation

/// Replaces the characters that HTML treats as markup, so text is shown literally and never run as HTML.
nonisolated enum HTMLEscaper {
    private static let replacements: [Character: String] = [
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#39;"
    ]

    /// Safe for both element text and quoted attribute values.
    static func escape(_ text: String) -> String {
        var result = ""
        for character in text {
            result += replacements[character] ?? String(character)
        }
        return result
    }
}
