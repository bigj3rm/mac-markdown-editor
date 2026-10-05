import SwiftUI

/// The sidebar: the opened folder as the top row, with its subfolders and markdown files beneath it.
struct FolderTreeView: View {
    let workspace: WorkspaceStore

    var body: some View {
        if let rootFolder = workspace.rootFolder {
            List(selection: selectedFileURL) {
                FolderRowView(node: rootFolder, workspace: workspace, startsExpanded: true)
            }
            // A new identity per folder resets which rows are expanded.
            .id(rootFolder.url)
        } else {
            ContentUnavailableView {
                Label("No Folder Open", systemImage: "folder")
            } description: {
                Text("Open a folder to see its markdown files.")
            } actions: {
                Button("Open Folder…") {
                    workspace.chooseFolder()
                }
            }
        }
    }

    /// Selecting a row opens that file. If the user cancels the unsaved-changes prompt, the old selection stays.
    private var selectedFileURL: Binding<URL?> {
        Binding(
            get: { workspace.selectedFileURL },
            set: { newURL in
                if let newURL {
                    workspace.openFile(at: newURL)
                }
            }
        )
    }
}
