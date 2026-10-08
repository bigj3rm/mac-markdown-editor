import AppKit
import Testing
@testable import markdown_editor

/// How the dialogs' button responses are read, above all that nothing unexpected can discard the user's work.
struct SystemPrompterTests {
    // MARK: - Unsaved changes alert (Save, Cancel, Don't Save)

    @Test func eachButtonOfTheUnsavedChangesAlertMapsToItsChoice() {
        #expect(SystemPrompter.unsavedChangesChoice(for: .alertFirstButtonReturn) == .save)
        #expect(SystemPrompter.unsavedChangesChoice(for: .alertSecondButtonReturn) == .cancel)
        #expect(SystemPrompter.unsavedChangesChoice(for: .alertThirdButtonReturn) == .discard)
    }

    /// AppKit aborts an alert that is started in the middle of a layout pass. That once threw edits away.
    @Test(arguments: [NSApplication.ModalResponse.abort, .stop, .continue, .cancel, .OK])
    func anythingElseFromTheUnsavedChangesAlertCountsAsCancel(response: NSApplication.ModalResponse) {
        #expect(SystemPrompter.unsavedChangesChoice(for: response) == .cancel)
    }

    // MARK: - Outside change alert

    @Test func reloadIsTheFirstButtonWhenThereAreNoUnsavedEdits() {
        #expect(SystemPrompter.externalChangeChoice(for: .alertFirstButtonReturn, hasUnsavedEdits: false) == .reload)
        #expect(SystemPrompter.externalChangeChoice(for: .alertSecondButtonReturn, hasUnsavedEdits: false) == .keepMine)
    }

    @Test func reloadIsTheSecondButtonWhenThereAreUnsavedEdits() {
        #expect(SystemPrompter.externalChangeChoice(for: .alertFirstButtonReturn, hasUnsavedEdits: true) == .keepMine)
        #expect(SystemPrompter.externalChangeChoice(for: .alertSecondButtonReturn, hasUnsavedEdits: true) == .reload)
    }

    @Test(arguments: [true, false])
    func anAbortedOutsideChangeAlertNeverReloads(hasUnsavedEdits: Bool) {
        #expect(SystemPrompter.externalChangeChoice(for: .abort, hasUnsavedEdits: hasUnsavedEdits) == .keepMine)
    }
}
