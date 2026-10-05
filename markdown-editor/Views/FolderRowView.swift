import SwiftUI

/// One row of the folder tree. A folder shows its contents when expanded, loading them the first time.
struct FolderRowView: View {
    let node: FileNode
    let workspace: WorkspaceStore
    @State private var isExpanded: Bool

    init(node: FileNode, workspace: WorkspaceStore, startsExpanded: Bool = false) {
        self.node = node
        self.workspace = workspace
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        if node.isFolder {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(workspace.children(of: node.url)) { child in
                    FolderRowView(node: child, workspace: workspace)
                }
            } label: {
                Label(node.name, systemImage: "folder")
            }
            .onChange(of: isExpanded) { _, expanded in
                if expanded {
                    workspace.loadChildren(of: node.url)
                }
            }
        } else {
            Label(node.name, systemImage: "doc.text")
                .tag(node.url)
        }
    }
}
