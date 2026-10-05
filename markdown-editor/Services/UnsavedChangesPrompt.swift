import AppKit

/// Asks the user what to do with edits that haven't been saved.
@MainActor
enum UnsavedChangesPrompt {
    /// The user's answer to the prompt.
    enum Choice {
        case save
        case discard
        case cancel
    }

    static func ask(fileName: String) -> Choice {
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
}
