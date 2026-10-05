import SwiftUI

/// The File menu items: Open Folder (Cmd+O) and Save (Cmd+S).
struct EditorCommands: Commands {
    let workspace: WorkspaceStore

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Folder…") {
                workspace.chooseFolder()
            }
            .keyboardShortcut("o")
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
