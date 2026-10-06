import Foundation

/// A uniquely named folder for one test, deleted when the test no longer holds it.
final class TemporaryFolder {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("markdown-editor-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    /// The URL of an item inside the folder, whether or not it exists yet.
    func url(for relativePath: String) -> URL {
        url.appendingPathComponent(relativePath)
    }

    /// Creates a file, along with any missing parent folders.
    @discardableResult
    func makeFile(_ relativePath: String, contents: String = "") throws -> URL {
        let fileURL = url(for: relativePath)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    @discardableResult
    func makeFolder(_ relativePath: String) throws -> URL {
        let folderURL = url(for: relativePath)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    func removeItem(_ relativePath: String) throws {
        try FileManager.default.removeItem(at: url(for: relativePath))
    }

    /// Reads a file in the folder back as text.
    func contents(of relativePath: String) throws -> String {
        try String(contentsOf: url(for: relativePath), encoding: .utf8)
    }
}
