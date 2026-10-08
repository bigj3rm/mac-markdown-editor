import SwiftUI

/// The File menu items: Open Folder (Cmd+O), New Markdown (Cmd+N) and Save (Cmd+S).
struct EditorCommands: Commands {
    let workspace: WorkspaceStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Folder…") {
                workspace.chooseFolder()
            }
            .keyboardShortcut("o")

            Button("New Markdown…") {
                workspace.createMarkdownFile()
            }
            .keyboardShortcut("n")
            .disabled(!workspace.hasOpenFolder)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                workspace.saveCurrentFile()
            }
            .keyboardShortcut("s")
            .disabled(!workspace.hasUnsavedChanges)
        }
    }
}
