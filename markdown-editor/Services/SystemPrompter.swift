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
        return Self.unsavedChangesChoice(for: alert.runModal())
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
        } else {
            alert.informativeText = "Do you want to reload it? Keep Current Text continues with what is shown here."
            alert.addButton(withTitle: "Reload")
            alert.addButton(withTitle: "Keep Current Text")
        }
        return Self.externalChangeChoice(for: alert.runModal(), hasUnsavedEdits: hasUnsavedEdits)
    }

    // MARK: - Reading the user's answer

    /// Turns the unsaved-changes alert's response into a choice.
    ///
    /// Only the Save and Don't Save buttons act. Anything else, such as the alert being aborted before
    /// the user answered, counts as Cancel so edits are never thrown away by accident.
    static func unsavedChangesChoice(for response: NSApplication.ModalResponse) -> UnsavedChangesChoice {
        switch response {
        case .alertFirstButtonReturn: .save
        case .alertThirdButtonReturn: .discard
        default: .cancel
        }
    }

    /// Turns the outside-change alert's response into a choice.
    ///
    /// Only the Reload button reloads. Anything else, including an aborted alert, keeps the editor's text.
    static func externalChangeChoice(for response: NSApplication.ModalResponse, hasUnsavedEdits: Bool) -> ExternalChangeChoice {
        // Reload is the first button when there is nothing to lose, and the second when there are unsaved edits.
        let reloadResponse: NSApplication.ModalResponse = hasUnsavedEdits ? .alertSecondButtonReturn : .alertFirstButtonReturn
        return response == reloadResponse ? .reload : .keepMine
    }
}
