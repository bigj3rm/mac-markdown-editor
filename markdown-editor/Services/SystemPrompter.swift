import AppKit

/// Asks the workspace's questions with the system's open panel and alerts.
@MainActor
struct SystemPrompter: WorkspacePrompting {
    func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder of markdown files"
        panel.prompt = "Open"
        return panel.runModal() == .OK ? panel.url : nil
    }

    func askAboutUnsavedChanges(fileName: String) -> UnsavedChangesChoice {
        let alert = NSAlert()
        alert.messageText = "Do you want to save the changes to “\(fileName)”?"
        alert.informativeText = "Your changes will be lost if you don’t save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don’t Save")

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .save
        case .alertSecondButtonReturn: return .cancel
        default: return .discard
        }
    }

    func askAboutExternalChange(fileName: String, hasUnsavedEdits: Bool) -> ExternalChangeChoice {
        let alert = NSAlert()
        alert.messageText = "“\(fileName)” was changed by another program."

        // The safe, non-destructive answer is always the default button.
        if hasUnsavedEdits {
            alert.informativeText = """
                You also have unsaved changes here. Reload to use the version on disk and lose your changes, \
                or keep your version. Saving will then replace the version on disk.
                """
            alert.addButton(withTitle: "Keep My Version")
            alert.addButton(withTitle: "Reload")
            alert.buttons[1].hasDestructiveAction = true
            return alert.runModal() == .alertFirstButtonReturn ? .keepMine : .reload
        }

        alert.informativeText = "Do you want to reload it? Keep Current Text continues with what is shown here."
        alert.addButton(withTitle: "Reload")
        alert.addButton(withTitle: "Keep Current Text")
        return alert.runModal() == .alertFirstButtonReturn ? .reload : .keepMine
    }
}
