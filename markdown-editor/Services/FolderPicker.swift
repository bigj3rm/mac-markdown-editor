import AppKit

/// Shows the system panel for choosing the folder to open.
@MainActor
enum FolderPicker {
    /// Returns the chosen folder, or `nil` if the user cancelled.
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder of markdown files"
        panel.prompt = "Open"
        return panel.runModal() == .OK ? panel.url : nil
    }
}
