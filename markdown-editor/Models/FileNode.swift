import Foundation

/// One row in the folder tree: either a folder or a markdown file.
nonisolated struct FileNode: Identifiable, Hashable, Sendable {
    let url: URL
    let isFolder: Bool

    var id: URL { url }
    var name: String { url.lastPathComponent }
}
