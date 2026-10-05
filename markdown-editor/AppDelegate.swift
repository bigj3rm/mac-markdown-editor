import AppKit

/// Owns the workspace and stops the app from quitting while there are unsaved edits.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let workspace = WorkspaceStore()

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        workspace.confirmDiscardingChanges() ? .terminateNow : .terminateCancel
    }

    // The app has one window, so closing it quits, which runs the unsaved-changes check above.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
