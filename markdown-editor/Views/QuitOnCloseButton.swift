import AppKit
import SwiftUI

/// Makes the window's red close button quit the app, so the unsaved-changes check runs before anything closes.
///
/// Closing the window first and asking afterwards doesn't work: with no window left, cancelling
/// makes AppKit ask to quit again, over and over. Quitting from the button leaves the window open until the user agrees.
struct QuitOnCloseButton: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        HookView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    /// Redirects the close button as soon as this view is in a window. The view must stay alive, since the button doesn't retain its target.
    private final class HookView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let closeButton = window?.standardWindowButton(.closeButton) else { return }
            closeButton.target = self
            closeButton.action = #selector(quit)
        }

        @objc private func quit() {
            NSApp.terminate(nil)
        }
    }
}
