import Markdown

/// Converts markdown to an HTML fragment by walking the swift-markdown syntax tree.
///
/// All text is escaped, and raw HTML written in the markdown is shown as text rather than passed through.
nonisolated struct MarkdownHTMLRenderer: MarkupVisitor {
    typealias Result = String

    private static let defaultListStart: UInt = 1

    /// Parses markdown and returns the HTML for the page body.
    static func renderBody(from markdown: String) -> String {
        var renderer = MarkdownHTMLRenderer()
        return renderer.visit(Document(parsing: markdown))
    }

    // MARK: - Shared helpers

    mutating func defaultVisit(_ markup: Markup) -> String {
        renderChildren(of: markup)
    }

    private mutating func renderChildren(of markup: Markup) -> String {
        markup.children.map { visit($0) }.joined()
    }

    /// Returns ` title="…"`, or nothing when there is no title.
    private func titleAttribute(_ title: String?) -> String {
        guard let title, !title.isEmpty else { return "" }
        return " title=\"\(HTMLEscaper.escape(title))\""
    }

    // MARK: - Blocks

    mutating func visitDocument(_ document: Document) -> String {
        renderChildren(of: document)
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        "<h\(heading.level)>\(renderChildren(of: heading))</h\(heading.level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        "<p>\(renderChildren(of: paragraph))</p>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        "<blockquote>\n\(renderChildren(of: blockQuote))</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let code = HTMLEscaper.escape(codeBlock.code)
        // The first word of the info string is the language; anything after it is extra metadata.
        guard let language = codeBlock.language?.split(whereSeparator: \.isWhitespace).first else {
            return "<pre><code>\(code)</code></pre>\n"
        }
        return "<pre><code class=\"language-\(HTMLEscaper.escape(String(language)))\">\(code)</code></pre>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        "<pre class=\"raw-html\">\(HTMLEscaper.escape(html.rawHTML))</pre>\n"
    }

    // MARK: - Lists

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        "<ul>\n\(renderItems(of: unorderedList))</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let startAttribute = orderedList.startIndex == Self.defaultListStart ? "" : " start=\"\(orderedList.startIndex)\""
        return "<ol\(startAttribute)>\n\(renderItems(of: orderedList))</ol>\n"
    }

    private mutating func renderItems(of list: some ListItemContainer) -> String {
        let isLoose = ListSpacing.isLoose(list)
        return list.children.compactMap { $0 as? ListItem }.map { renderListItem($0, isLoose: isLoose) }.joined()
    }

    private mutating func renderListItem(_ listItem: ListItem, isLoose: Bool) -> String {
        guard let checkbox = listItem.checkbox else {
            return "<li>\(renderListItemContent(of: listItem, isLoose: isLoose, leading: ""))</li>\n"
        }
        let checkedAttribute = checkbox == .checked ? " checked" : ""
        let checkboxHTML = "<input type=\"checkbox\" disabled\(checkedAttribute)> "
        let content = renderListItemContent(of: listItem, isLoose: isLoose, leading: checkboxHTML)
        return "<li class=\"task-list-item\">\(content)</li>\n"
    }

    /// A tight list shows paragraph text directly in the item, and a loose list wraps each paragraph in `<p>`.
    /// `leading` goes at the very start, inside the first paragraph, so a checkbox stays on the same line as its text.
    private mutating func renderListItemContent(of listItem: ListItem, isLoose: Bool, leading: String) -> String {
        var html = ""
        for (index, child) in listItem.children.enumerated() {
            let prefix = index == 0 ? leading : ""
            if let paragraph = child as? Paragraph {
                let text = prefix + renderChildren(of: paragraph)
                html += isLoose ? "<p>\(text)</p>\n" : text
            } else {
                html += prefix + visit(child)
            }
        }
        return html
    }

    // MARK: - Tables

    // Cells are rendered here, not in `visitTableCell`, because a cell needs its column's alignment from the table.
    mutating func visitTable(_ table: Table) -> String {
        let alignments = table.columnAlignments
        let headerCells = renderCells(of: table.head, tag: "th", alignments: alignments)
        var html = "<table>\n<thead>\n<tr>\(headerCells)</tr>\n</thead>\n"

        var bodyRows = ""
        for row in table.body.rows {
            bodyRows += "<tr>\(renderCells(of: row, tag: "td", alignments: alignments))</tr>\n"
        }
        if !bodyRows.isEmpty {
            html += "<tbody>\n\(bodyRows)</tbody>\n"
        }
        return html + "</table>\n"
    }

    private mutating func renderCells(
        of container: some TableCellContainer,
        tag: String,
        alignments: [Table.ColumnAlignment?]
    ) -> String {
        container.cells.enumerated().map { column, cell in
            let alignment = column < alignments.count ? alignments[column] : nil
            return "<\(tag)\(alignmentAttribute(for: alignment))>\(renderChildren(of: cell))</\(tag)>"
        }.joined()
    }

    private func alignmentAttribute(for alignment: Table.ColumnAlignment?) -> String {
        switch alignment {
        case .left: " style=\"text-align: left\""
        case .center: " style=\"text-align: center\""
        case .right: " style=\"text-align: right\""
        case nil: ""
        }
    }

    // MARK: - Inline content

    mutating func visitText(_ text: Text) -> String {
        HTMLEscaper.escape(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        "<em>\(renderChildren(of: emphasis))</em>"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        "<strong>\(renderChildren(of: strong))</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        "<del>\(renderChildren(of: strikethrough))</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(HTMLEscaper.escape(inlineCode.code))</code>"
    }

    mutating func visitLink(_ link: Link) -> String {
        let destination = HTMLEscaper.escape(link.destination ?? "")
        return "<a href=\"\(destination)\"\(titleAttribute(link.title))>\(renderChildren(of: link))</a>"
    }

    // The source is written as-is: the web view resolves relative paths against the open file's folder.
    mutating func visitImage(_ image: Image) -> String {
        let source = HTMLEscaper.escape(image.source ?? "")
        let altText = HTMLEscaper.escape(image.plainText)
        return "<img src=\"\(source)\" alt=\"\(altText)\"\(titleAttribute(image.title))>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        HTMLEscaper.escape(inlineHTML.rawHTML)
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }
}
