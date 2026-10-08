import AppKit

/// Owns the workspace and stops the app from quitting while there are unsaved edits.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let workspace = WorkspaceStore()

    // Another program may have changed the files while this app was in the background.
    func applicationDidBecomeActive(_ notification: Notification) {
        workspace.refreshFromDisk()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        workspace.confirmDiscardingChanges() ? .terminateNow : .terminateCancel
    }

    // The app has one window, so closing it quits, which runs the unsaved-changes check above.
    // The close button asks to quit before the window closes (see `QuitOnCloseButton`).
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
