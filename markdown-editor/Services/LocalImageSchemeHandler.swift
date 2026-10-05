import UniformTypeIdentifiers
import WebKit

/// Serves images from the opened folder to the preview, which has no network access.
///
/// Preview pages load under a custom URL scheme, so a relative image path such as `images/a.png`
/// arrives here instead of going to the network. Only image files inside the opened folder are served.
@MainActor
final class LocalImageSchemeHandler: NSObject, WKURLSchemeHandler {
    nonisolated static let scheme = "local-image"
    private static let host = "local"
    private static let fallbackMIMEType = "application/octet-stream"

    /// The folder images may be read from.
    var allowedFolderURL: URL?

    /// The base URL for a page whose relative image paths start in `directoryURL`.
    static func baseURL(forFilesIn directoryURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        // The trailing slash makes relative paths resolve inside the folder rather than beside it.
        components.path = directoryURL.path + "/"
        return components.url
    }

    // MARK: - WKURLSchemeHandler

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        let requestURL = urlSchemeTask.request.url
        guard let requestURL,
              let fileURL = servableFileURL(for: requestURL),
              let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let response = URLResponse(
            url: requestURL,
            mimeType: mimeType(for: fileURL),
            expectedContentLength: data.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

    // MARK: - Access checks

    /// Maps a request to a file on disk, or returns `nil` if the file isn't an image inside the allowed folder.
    private func servableFileURL(for requestURL: URL) -> URL? {
        guard requestURL.scheme == Self.scheme, let allowedFolderURL else { return nil }

        // Resolving symlinks stops a link inside the folder from reaching files outside it.
        let fileURL = URL(fileURLWithPath: requestURL.path).resolvingSymlinksInPath()
        let folderPath = allowedFolderURL.resolvingSymlinksInPath().path
        guard fileURL.path.hasPrefix(folderPath + "/") else { return nil }

        guard let type = UTType(filenameExtension: fileURL.pathExtension), type.conforms(to: .image) else {
            return nil
        }
        return fileURL
    }

    private func mimeType(for fileURL: URL) -> String {
        UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? Self.fallbackMIMEType
    }
}
