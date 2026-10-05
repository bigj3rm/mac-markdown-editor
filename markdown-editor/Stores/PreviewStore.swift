import Foundation
import Observation

/// The preview pane's state: whether it is shown and the HTML it displays.
///
/// After a keystroke it waits briefly before re-rendering, so typing stays smooth.
@MainActor
@Observable
final class PreviewStore {
    var isVisible = false
    private(set) var bodyHTML = ""

    private static let debounceInterval = Duration.milliseconds(250)

    private var pendingRender: Task<Void, Never>?
    private var lastDocumentID: URL?

    /// Re-renders for an edit. A different file is shown at once; typing waits for a pause.
    func update(for markdown: String, documentID: URL?) {
        guard isVisible else { return }
        let delay = documentID == lastDocumentID ? Self.debounceInterval : nil
        lastDocumentID = documentID
        startRendering(markdown, after: delay)
    }

    /// Re-renders immediately, for when the preview is first shown.
    func updateNow(for markdown: String, documentID: URL?) {
        lastDocumentID = documentID
        startRendering(markdown, after: nil)
    }

    private func startRendering(_ markdown: String, after delay: Duration?) {
        pendingRender?.cancel()
        pendingRender = Task {
            if let delay {
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    return // A newer edit replaced this one.
                }
            }
            // Rendering runs off the main thread so a long document can't stall typing.
            let html = await Task.detached { MarkdownHTMLRenderer.renderBody(from: markdown) }.value
            guard !Task.isCancelled else { return }
            bodyHTML = html
        }
    }
}
