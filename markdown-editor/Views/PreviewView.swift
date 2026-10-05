import AppKit
import SwiftUI
import WebKit

/// Shows rendered HTML in a web view and keeps the scroll position when the content refreshes.
struct PreviewView: NSViewRepresentable {
    let bodyHTML: String
    /// The open file. Relative image paths in the markdown are resolved against its folder.
    let fileURL: URL?
    /// Images are only loaded from inside this folder.
    let allowedFolderURL: URL?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.imageHandler, forURLScheme: LocalImageSchemeHandler.scheme)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.imageHandler.allowedFolderURL = allowedFolderURL
        context.coordinator.display(bodyHTML: bodyHTML, fileURL: fileURL, in: webView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    /// Loads pages into the web view, restores the scroll position, and sends link clicks to the browser.
    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let imageHandler = LocalImageSchemeHandler()

        private static let externalLinkSchemes: Set<String> = ["http", "https", "mailto"]

        private var shownHTML: String?
        private var shownFileURL: URL?
        private var lastScrollOffset = 0.0

        /// Loads new content. Within the same file the scroll position is kept; a different file starts at the top.
        func display(bodyHTML: String, fileURL: URL?, in webView: WKWebView) {
            guard bodyHTML != shownHTML || fileURL != shownFileURL else { return }

            let keepsScrollPosition = shownHTML != nil && fileURL == shownFileURL
            shownHTML = bodyHTML
            shownFileURL = fileURL

            guard keepsScrollPosition else {
                load(bodyHTML, fileURL: fileURL, scrollOffset: 0, in: webView)
                return
            }
            // A page that is still loading hasn't scrolled yet, so its position can't be trusted.
            guard !webView.isLoading else {
                load(bodyHTML, fileURL: fileURL, scrollOffset: lastScrollOffset, in: webView)
                return
            }
            Task {
                // Reloading resets the page to the top, so the position is read first.
                let offset = try? await webView.evaluateJavaScript("window.scrollY") as? Double
                // Skip if a newer update arrived while waiting.
                guard bodyHTML == shownHTML, fileURL == shownFileURL else { return }
                load(bodyHTML, fileURL: fileURL, scrollOffset: offset ?? lastScrollOffset, in: webView)
            }
        }

        private func load(_ bodyHTML: String, fileURL: URL?, scrollOffset: Double, in webView: WKWebView) {
            lastScrollOffset = scrollOffset
            let page = HTMLPage.make(body: bodyHTML, initialScrollOffset: scrollOffset)
            let baseURL = fileURL.flatMap { LocalImageSchemeHandler.baseURL(forFilesIn: $0.deletingLastPathComponent()) }
            webView.loadHTMLString(page, baseURL: baseURL)
        }

        // MARK: - WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated else { return .allow }

            // Clicked links never replace the preview; web and mail links open in their usual app instead.
            if let url = navigationAction.request.url, Self.externalLinkSchemes.contains(url.scheme ?? "") {
                NSWorkspace.shared.open(url)
            }
            return .cancel
        }
    }
}
