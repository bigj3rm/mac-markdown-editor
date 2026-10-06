import SwiftUI

/// The center pane: the text editor for the open file, or a hint when no file is open.
struct EditorView: View {
    @Bindable var workspace: WorkspaceStore

    var body: some View {
        if let fileName = workspace.selectedFileName {
            VStack(spacing: 0) {
                if workspace.isMissingOnDisk {
                    MissingFileBanner(fileName: fileName) {
                        workspace.saveCurrentFile()
                    }
                    Divider()
                }
                MarkdownTextView(
                    text: $workspace.text,
                    documentID: workspace.selectedFileURL,
                    revision: workspace.documentRevision
                )
            }
        } else {
            ContentUnavailableView(
                "No File Open",
                systemImage: "doc.text",
                description: Text("Choose a markdown file from the sidebar.")
            )
        }
    }
}
