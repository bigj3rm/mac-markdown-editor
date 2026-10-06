/// How a file on disk compares with the text the editor last read from or wrote to it.
nonisolated enum FileDiskState: Equatable {
    case unchanged
    case changed(diskText: String)
    /// The file was deleted or moved, or its folder was.
    case missing
}
