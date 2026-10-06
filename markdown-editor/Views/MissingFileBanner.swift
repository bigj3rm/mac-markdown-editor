import SwiftUI

/// Tells the user the open file was deleted or moved outside the editor, and offers to save it again.
struct MissingFileBanner: View {
    let fileName: String
    let onSave: () -> Void

    /// Spacing and color values for the banner.
    private enum Layout {
        static let spacing: CGFloat = 12
        static let padding: CGFloat = 10
        static let backgroundOpacity = 0.18
    }

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Label {
                Text("“\(fileName)” was deleted or moved outside the editor. Your text is still here: copy it, or save to create the file again.")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
            Spacer(minLength: 0)
            Button("Save", action: onSave)
        }
        .padding(Layout.padding)
        .background(Color.yellow.opacity(Layout.backgroundOpacity))
    }
}
