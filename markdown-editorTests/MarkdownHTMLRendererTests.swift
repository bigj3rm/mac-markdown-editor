import Testing
@testable import markdown_editor

/// The HTML the renderer produces, especially that nothing from the markdown is passed through unescaped.
struct MarkdownHTMLRendererTests {
    private func render(_ markdown: String) -> String {
        MarkdownHTMLRenderer.renderBody(from: markdown)
    }

    // MARK: - Escaping

    @Test func inlineHTMLInTextIsEscaped() {
        let html = render("Hello <script>alert(1)</script> & <img src=x onerror=alert(1)>")

        #expect(!html.contains("<script>"))
        #expect(!html.contains("<img"))
        #expect(html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"))
        #expect(html.contains("&amp;"))
    }

    @Test func blockHTMLIsShownAsEscapedText() {
        let html = render("<div onclick=\"evil()\">block</div>")

        #expect(!html.contains("<div"))
        #expect(html.contains("&lt;div onclick=&quot;evil()&quot;&gt;block&lt;/div&gt;"))
    }

    @Test func quotesInLinkDestinationsCannotBreakOutOfTheAttribute() {
        let html = render("[link](x\"onmouseover=\"y)")

        #expect(!html.contains("\"onmouseover=\""))
        #expect(html.contains("&quot;onmouseover=&quot;"))
    }

    @Test func codeBlockContentsAreEscapedAndTheLanguageBecomesAClass() {
        let html = render("```swift\nlet x = 1 < 2\n```")

        #expect(html.contains("<code class=\"language-swift\">let x = 1 &lt; 2"))
    }

    // MARK: - Structure

    @Test func headingsUseTheirLevel() {
        #expect(render("## Title").contains("<h2>Title</h2>"))
    }

    @Test func orderedListsKeepTheirStartNumberOnlyWhenItIsNotOne() {
        #expect(render("3. three").contains("<ol start=\"3\">"))
        #expect(render("1. one").contains("<ol>"))
    }

    @Test func taskListItemsGetDisabledCheckboxes() {
        let html = render("- [ ] todo\n- [x] done")

        #expect(html.contains("<input type=\"checkbox\" disabled> todo"))
        #expect(html.contains("<input type=\"checkbox\" disabled checked> done"))
    }

    @Test func tableColumnsGetTheirAlignment() {
        let html = render("| L | C | R | N |\n|:--|:-:|--:|---|\n| a | b | c | d |")

        #expect(html.contains("<th style=\"text-align: left\">L</th>"))
        #expect(html.contains("<th style=\"text-align: center\">C</th>"))
        #expect(html.contains("<td style=\"text-align: right\">c</td>"))
        #expect(html.contains("<td>d</td>"))
    }

    @Test func imageSourcesAreLeftAsWrittenSoTheyResolveAgainstTheFilesFolder() {
        let html = render("![Alt text](images/cat.png \"Cat\")")

        #expect(html.contains("<img src=\"images/cat.png\" alt=\"Alt text\" title=\"Cat\">"))
    }

    @Test func strikethroughAndInlineCodeAreRendered() {
        let html = render("~~gone~~ and `a < b`")

        #expect(html.contains("<del>gone</del>"))
        #expect(html.contains("<code>a &lt; b</code>"))
    }
}
