import SwiftUI

/// The sidebar: the opened folder as the top row, with its subfolders and markdown files beneath it.
struct FolderTreeView: View {
    @Bindable var workspace: WorkspaceStore

    var body: some View {
        if let rootFolder = workspace.rootFolder {
            List(selection: $workspace.treeSelection) {
                FolderRowView(node: rootFolder, workspace: workspace, startsExpanded: true)
            }
            // The store opens the clicked file, then moves the highlight back if the file didn't open.
            .onChange(of: workspace.treeSelection) {
                workspace.treeSelectionChanged()
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
}
