import SwiftUI

/// The app's entry point: a single window and the menu commands.
@main
struct MarkdownEditorApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    private static let defaultWindowWidth: CGFloat = 1100
    private static let defaultWindowHeight: CGFloat = 700

    var body: some Scene {
        Window("Markdown Editor", id: "main") {
            ContentView(workspace: appDelegate.workspace)
        }
        .defaultSize(width: Self.defaultWindowWidth, height: Self.defaultWindowHeight)
        .commands {
            EditorCommands(workspace: appDelegate.workspace)
        }
    }
}
