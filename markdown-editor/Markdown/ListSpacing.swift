import Markdown

/// Decides whether a markdown list is "loose", which changes how its items are spaced and wrapped.
///
/// swift-markdown doesn't report this, so it is worked out from the source lines using the CommonMark rule:
/// a list is loose if any of its items are separated by a blank line, or if any item directly contains two
/// blocks separated by a blank line. Blank lines inside a single block, such as a code block, don't count.
nonisolated enum ListSpacing {
    static func isLoose(_ list: some ListItemContainer) -> Bool {
        let items = Array(list.children)
        return hasBlankLineBetweenNeighbors(items)
            || items.contains { hasBlankLineBetweenNeighbors(Array($0.children)) }
    }

    private static func hasBlankLineBetweenNeighbors(_ blocks: [any Markup]) -> Bool {
        zip(blocks, blocks.dropFirst()).contains { hasBlankLine(between: $0, and: $1) }
    }

    private static func hasBlankLine(between first: any Markup, and second: any Markup) -> Bool {
        guard let firstEndLine = lastContentLine(of: first),
              let secondStartLine = second.range?.lowerBound.line else { return false }
        return secondStartLine - firstEndLine > 1
    }

    /// The last line of a block that has content on it.
    ///
    /// A list item's own range runs on over the blank line after it, so for a block that holds other blocks
    /// the answer comes from its last child instead.
    private static func lastContentLine(of block: any Markup) -> Int? {
        let holdsBlocks = block is any BlockContainer || block is any ListItemContainer
        if holdsBlocks, let lastChild = block.children.map({ $0 }).last {
            return lastContentLine(of: lastChild)
        }
        return block.range?.upperBound.line
    }
}
