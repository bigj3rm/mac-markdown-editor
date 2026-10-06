import AppKit
import SwiftUI

/// An AppKit text view for editing markdown as plain monospaced text, with undo.
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    /// Identifies the open file. When it changes, the editor starts at the top of the new file.
    let documentID: URL?
    /// Changes when the text is replaced from disk. With `documentID`, it clears the undo history so Undo can't mix old and new text.
    let revision: Int

    private static let fontSize: CGFloat = 13
    private static let textInset = NSSize(width: 12, height: 12)

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: Self.fontSize, weight: .regular)
        textView.textContainerInset = Self.textInset
        textView.allowsUndo = true
        textView.isRichText = false
        // Smart substitutions would silently change markdown characters such as quotes and dashes.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let coordinator = context.coordinator
        coordinator.text = $text

        // Skipping equal text keeps the caret and undo history intact while the user types.
        if textView.string != text {
            textView.string = text
        }

        let isNewDocument = coordinator.documentID != documentID
        if isNewDocument || coordinator.revision != revision {
            coordinator.documentID = documentID
            coordinator.revision = revision
            textView.undoManager?.removeAllActions()
        }
        if isNewDocument {
            textView.scrollToBeginningOfDocument(nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, documentID: documentID, revision: revision)
    }

    // MARK: - Coordinator

    /// Passes the user's edits from the text view back to the `text` binding.
    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var documentID: URL?
        var revision: Int

        init(text: Binding<String>, documentID: URL?, revision: Int) {
            self.text = text
            self.documentID = documentID
            self.revision = revision
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
