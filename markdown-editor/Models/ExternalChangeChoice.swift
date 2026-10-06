/// The user's answer when a file changed outside the editor.
nonisolated enum ExternalChangeChoice {
    /// Show what is on disk now, discarding any edits made here.
    case reload
    /// Keep the text in the editor and ignore what changed on disk.
    case keepMine
}
