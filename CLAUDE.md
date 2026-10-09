# Markdown Editor

## Project

A macOS markdown editor built with SwiftUI in this Xcode project, targeting the current macOS. The swift-markdown package (the `Markdown` library) is already added. Do not add any other dependencies.

The app is local-only: it never uses the network, and images in markdown must be stored locally. The sandbox's network entitlement is on only because WKWebView's content process won't start without it; the preview's Content-Security-Policy and link handling keep the app offline.

Features:
- Three-pane layout: folder tree on the left (the opened folder is the root row; subfolders load when expanded), editor in the center, optional live preview on the right toggled from the toolbar.
- Editor: an `NSTextView` wrapped in `NSViewRepresentable`, monospaced, with undo, fully editable while the preview is open.
- Preview: a `WKWebView` loading HTML through `loadHTMLString`. The HTML comes from parsing with swift-markdown and a `MarkupVisitor`. All text is HTML-escaped, and raw HTML in the markdown is escaped rather than passed through. Styled by a small embedded GitHub-like CSS string with light and dark mode. No external CSS or JS files.
- Preview updates are debounced, and the preview keeps its scroll position when it refreshes.
- Save from the toolbar and Cmd+S. An unsaved-changes indicator, and a prompt before switching files or quitting with unsaved edits.

## Code quality and style

- Follow Apple's Swift API Design Guidelines for naming: clear, descriptive names, no abbreviations unless they're standard.
- Keep it understandable for a Swift beginner. Prefer simple, direct code over clever tricks. Avoid deep nesting and long functions; if a function does more than one thing, split it up.
- One main type per file, named after the type. Group files into folders such as `Views/`, `Models/`, and `Markdown/` (the HTML renderer).
- Separate concerns: views only display things. A view model or store object holds state (open folder, current file, unsaved-changes flag). File I/O and markdown-to-HTML live in their own types, not in views.
- Use `///` doc comments on every type and on any function that isn't obvious from its name. Use inline `//` comments only to explain why, not what. Use `// MARK: -` to divide sections in larger files. No commented-out code, no filler comments. Don't be overly verbose.
- Avoid force unwraps (`!`) and `try!`. Handle file errors with `throws` and show the user a clear alert when a read or save fails.
- Use `let` over `var`, structs over classes unless reference semantics are needed, and named constants instead of magic numbers or strings.
- Mark UI-touching code `@MainActor` where appropriate. Fix all compiler warnings before finishing.

## Project facts

- Build: `xcodebuild -project markdown-editor.xcodeproj -scheme markdown-editor -destination 'platform=macOS' build`
- Test: the same command with `test` instead of `build`. Tests are written with Swift Testing and live in `markdown-editorTests/`, hosted in the app. Add or update tests with every behavior change.
- Sources live in `markdown-editor/` and tests in `markdown-editorTests/`, both synchronized folders: new files and subfolders are picked up by Xcode automatically, so the `.pbxproj` needs no file entries.
- Folders: `Models/` (plain data and state rules), `Services/` (file I/O, dialogs, the local image scheme handler), `Stores/` (observable state), `Markdown/` (HTML rendering), `Views/` (SwiftUI and AppKit wrappers).
- Ask the user questions only through `WorkspacePrompting` (the real dialogs are in `SystemPrompter`), never by showing an `NSAlert` or panel from a store, so the store logic stays testable with `StubPrompter`.
- The state rules for the open file (what counts as unsaved, missing, or reloaded) live in `OpenDocument`; `WorkspaceStore` does the reading, writing and asking around it.
- Never show a dialog from inside a SwiftUI `onChange`, `body` or other view update: those run in AppKit's layout pass, where a modal alert is aborted at once (response `-1001`). Defer with `Task { … }` first, as `FolderTreeView` does. `SystemPrompter` maps any unexpected response to the safe answer (Cancel, or keep my text), never to discard.
- The window's red close button is redirected to quit (`QuitOnCloseButton`) so the unsaved-changes prompt appears while the window is still open. If the window were closed first, cancelling would make AppKit ask to quit again endlessly.
- File → New Markdown… (Cmd+N) asks for a name and creates an empty `.md` file in the folder the tree has highlighted (the highlighted folder, the folder of the highlighted file, or the root). It never overwrites, adds `.md` when missing, asks again for a bad or taken name, and leaves the open file and the editor alone. Name rules live in `MarkdownFileName`.
- List spacing follows CommonMark. swift-markdown doesn't say whether a list is loose, so `ListSpacing` works it out from the source line ranges (a list item's own range runs over the blank line after it, so measure from its last child). Tight lists show item text directly; loose lists wrap it in `<p>`. Lettered lists (`a.`) are not part of the standard and render as text.
- Files changed outside the editor are detected by comparing contents, when the app becomes active and just before saving. A deleted file keeps its text in the editor and counts as unsaved until it is saved again.
- The target uses default `MainActor` isolation, so every type is `@MainActor` unless marked otherwise. Mark pure types (models, file I/O, the renderer) `nonisolated`.
- The app is sandboxed with user-selected files set to read-write and outgoing connections enabled (required for WKWebView to run at all). Entitlements come from build settings (`ENABLE_*`), not an entitlements file.
- Preview pages load under the custom `local-image://` scheme (`LocalImageSchemeHandler`), which serves image files from inside the opened folder only. Keep the Content-Security-Policy in `HTMLPage` restricted to that scheme so markdown can never trigger a network request.
