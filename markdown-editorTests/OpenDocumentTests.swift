import Foundation
import Testing
@testable import markdown_editor

/// The rules for what counts as unsaved, missing, or reloaded.
struct OpenDocumentTests {
    private let fileURL = URL(fileURLWithPath: "/notes/note.md")

    private func makeDocument(text: String = "saved") -> OpenDocument {
        OpenDocument(url: fileURL, text: text)
    }

    @Test func newDocumentHasNoUnsavedChanges() {
        #expect(!makeDocument().hasUnsavedChanges)
    }

    @Test func editingMakesItUnsavedAndEditingBackClearsIt() {
        var document = makeDocument(text: "saved")

        document.text = "edited"
        #expect(document.hasUnsavedChanges)

        document.text = "saved"
        #expect(!document.hasUnsavedChanges)
    }

    @Test func markSavedRecordsTheTextAsOnDisk() {
        var document = makeDocument()
        document.text = "edited"

        document.markSaved()

        #expect(!document.hasUnsavedChanges)
        #expect(document.savedText == "edited")
    }

    @Test func aMissingFileCountsAsUnsavedEvenWhenTheTextIsUnchanged() {
        var document = makeDocument()

        document.markMissing()

        #expect(document.isMissingOnDisk)
        #expect(document.hasUnsavedChanges)
    }

    @Test func savingClearsTheMissingFlag() {
        var document = makeDocument()
        document.markMissing()

        document.markSaved()

        #expect(!document.isMissingOnDisk)
        #expect(!document.hasUnsavedChanges)
    }

    @Test func replacingWithDiskTextDiscardsEditsAndBumpsTheRevision() {
        var document = makeDocument()
        document.text = "edited"
        let revisionBefore = document.revision

        document.replaceWithDiskText("from disk")

        #expect(document.text == "from disk")
        #expect(!document.hasUnsavedChanges)
        #expect(document.revision == revisionBefore + 1)
    }

    @Test func keepingEditsTreatsTheNewDiskTextAsTheBaseline() {
        var document = makeDocument(text: "saved")
        document.text = "my edit"

        document.keepEdits(againstDiskText: "changed elsewhere")

        #expect(document.text == "my edit")
        #expect(document.savedText == "changed elsewhere")
        #expect(document.hasUnsavedChanges)
        #expect(document.revision == 0)
    }

    @Test func keepingEditsThatMatchTheDiskLeavesNothingUnsaved() {
        var document = makeDocument()
        document.text = "same"

        document.keepEdits(againstDiskText: "same")

        #expect(!document.hasUnsavedChanges)
    }

    @Test func keepingEditsClearsTheMissingFlag() {
        var document = makeDocument()
        document.markMissing()

        document.keepEdits(againstDiskText: "restored")

        #expect(!document.isMissingOnDisk)
    }
}
