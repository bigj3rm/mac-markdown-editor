import SwiftUI

/// The main window: folder tree, editor and optional live preview, with a toolbar and error alerts.
struct ContentView: View {
    @Bindable var workspace: WorkspaceStore
    @State private var preview = PreviewStore()

    /// Pane sizes for the window layout.
    private enum Layout {
        static let sidebarMinWidth: CGFloat = 180
        static let sidebarIdealWidth: CGFloat = 240
        static let sidebarMaxWidth: CGFloat = 400
        static let paneMinWidth: CGFloat = 250
    }

    /// What the preview shows. Watching both values together means one change triggers one update.
    private struct PreviewInput: Equatable {
        let text: String
        let documentID: URL?
    }

    var body: some View {
        NavigationSplitView {
            FolderTreeView(workspace: workspace)
                .navigationSplitViewColumnWidth(
                    min: Layout.sidebarMinWidth,
                    ideal: Layout.sidebarIdealWidth,
                    max: Layout.sidebarMaxWidth
                )
        } detail: {
            HSplitView {
                EditorView(workspace: workspace)
                    .frame(minWidth: Layout.paneMinWidth)
                if preview.isVisible {
                    PreviewView(
                        bodyHTML: preview.bodyHTML,
                        fileURL: workspace.selectedFileURL,
                        allowedFolderURL: workspace.rootFolder?.url
                    )
                    .frame(minWidth: Layout.paneMinWidth)
                }
            }
        }
        .navigationTitle(workspace.selectedFileName ?? "Markdown Editor")
        .navigationSubtitle(workspace.hasUnsavedChanges ? "Edited" : "")
        .toolbar { toolbarContent }
        .background(QuitOnCloseButton())
        .onChange(of: previewInput) { _, input in
            preview.update(for: input.text, documentID: input.documentID)
        }
        .onChange(of: preview.isVisible) { _, isVisible in
            if isVisible {
                preview.updateNow(for: workspace.text, documentID: workspace.selectedFileURL)
            }
        }
        .alert(
            workspace.presentedAlert?.title ?? "",
            isPresented: isAlertPresented,
            presenting: workspace.presentedAlert
        ) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button("Open Folder", systemImage: "folder") {
                workspace.chooseFolder()
            }
            .help("Open a folder")
        }
        ToolbarItem {
            Button("Save", systemImage: "square.and.arrow.down") {
                workspace.saveCurrentFile()
            }
            .disabled(!workspace.hasUnsavedChanges)
            .help("Save the current file")
        }
        ToolbarItem {
            Toggle("Preview", systemImage: "sidebar.right", isOn: $preview.isVisible)
                .help("Show or hide the live preview")
        }
    }

    // MARK: - Bindings

    private var previewInput: PreviewInput {
        PreviewInput(text: workspace.text, documentID: workspace.selectedFileURL)
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { workspace.presentedAlert != nil },
            set: { isPresented in
                if !isPresented {
                    workspace.presentedAlert = nil
                }
            }
        )
    }
}
