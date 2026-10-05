import Foundation

/// Lists folders and reads and writes markdown files. Every failure is thrown as a `FileServiceError`.
nonisolated enum FileService {
    private static let markdownPathExtension = "md"

    // MARK: - Folders

    /// Lists the subfolders and markdown files directly inside a folder, folders first.
    ///
    /// Only one level is read, so large folder trees are never scanned up front.
    static func contents(ofFolder folderURL: URL) throws -> [FileNode] {
        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw FileServiceError.cannotListFolder(folderURL, underlying: error)
        }
        return urls.compactMap(makeNode(for:)).sorted(by: isOrderedBefore)
    }

    /// Returns a node for a folder or markdown file, or `nil` for anything else.
    private static func makeNode(for url: URL) -> FileNode? {
        let isFolder = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let isMarkdownFile = url.pathExtension.lowercased() == markdownPathExtension
        guard isFolder || isMarkdownFile else { return nil }
        return FileNode(url: url, isFolder: isFolder)
    }

    private static func isOrderedBefore(_ first: FileNode, _ second: FileNode) -> Bool {
        if first.isFolder != second.isFolder {
            return first.isFolder
        }
        return first.name.localizedStandardCompare(second.name) == .orderedAscending
    }

    // MARK: - Files

    /// Reads a UTF-8 text file.
    static func readText(at fileURL: URL) throws -> String {
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw FileServiceError.cannotRead(fileURL, underlying: error)
        }
    }

    /// Writes UTF-8 text to a file, replacing its contents in one step so a failed save can't leave a half-written file.
    static func writeText(_ text: String, to fileURL: URL) throws {
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw FileServiceError.cannotWrite(fileURL, underlying: error)
        }
    }
}
