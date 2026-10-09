import Foundation
import Testing
@testable import markdown_editor

/// Lists as the CommonMark standard defines them: bullets, numbers, nesting, and tight versus loose.
struct MarkdownListRenderingTests {
    private func render(_ markdown: String) -> String {
        MarkdownHTMLRenderer.renderBody(from: markdown)
    }

    // MARK: - Bullets

    @Test(arguments: ["-", "*", "+"])
    func eachBulletMarkerMakesAnUnorderedList(marker: String) {
        let html = render("\(marker) one\n\(marker) two")

        #expect(html.contains("<ul>\n<li>one</li>\n<li>two</li>\n</ul>"))
    }

    @Test func changingTheBulletMarkerStartsANewList() {
        let html = render("- a\n* b")

        #expect(html.components(separatedBy: "<ul>").count == 3)
    }

    // MARK: - Numbers

    @Test(arguments: ["1.", "1)"])
    func bothNumberStylesMakeAnOrderedList(marker: String) {
        let html = render("\(marker) one\n\(marker) two")

        #expect(html.contains("<ol>\n<li>one</li>\n<li>two</li>\n</ol>"))
    }

    @Test func aListKeepsTheNumberItStartsAt() {
        #expect(render("3. three\n4. four").contains("<ol start=\"3\">"))
        #expect(render("0. zero").contains("<ol start=\"0\">"))
    }

    // MARK: - Letters

    /// CommonMark has no lettered lists, so these are ordinary text, exactly as on GitHub.
    @Test func letterMarkersAreNotListsInTheMarkdownStandard() {
        let html = render("a. first\nb. second")

        #expect(!html.contains("<ol"))
        #expect(!html.contains("<li"))
        #expect(html.contains("a. first"))
    }

    @Test func lettersUnderANumberedItemStayPartOfThatItem() {
        let html = render("1. one\n   a. letter\n2. two")

        #expect(html.components(separatedBy: "<ol").count == 2)
        #expect(html.contains("a. letter"))
    }

    // MARK: - Nesting

    @Test(arguments: ["-", "*", "+"], ["  ", "   ", "    ", "\t"])
    func bulletsNestUnderABulletWhetherIndentedByASingleTabOrSpaces(marker: String, indent: String) {
        let html = render("\(marker) parent\n\(indent)\(marker) child")

        #expect(html.contains("<li>parent<ul>\n<li>child</li>\n</ul>\n</li>"))
    }

    @Test(arguments: ["1.", "1)"], ["   ", "    ", "\t"])
    func numbersNestUnderANumberWhetherIndentedByASingleTabOrSpaces(marker: String, indent: String) {
        let html = render("\(marker) parent\n\(indent)\(marker) child")

        #expect(html.contains("<li>parent<ol>\n<li>child</li>\n</ol>\n</li>"))
    }

    @Test func aNumberedListCanNestInsideABulletAndTheOtherWayRound() {
        #expect(render("- bullet\n\t1. number").contains("<li>bullet<ol>\n<li>number</li>\n</ol>\n</li>"))
        #expect(render("1. number\n\t- bullet").contains("<li>number<ul>\n<li>bullet</li>\n</ul>\n</li>"))
    }

    @Test func differentMarkersCanNestInsideEachOther() {
        let html = render("* star\n\t+ plus\n\t\t- dash")

        #expect(html.contains("<li>star<ul>\n<li>plus<ul>\n<li>dash</li>\n</ul>\n</li>\n</ul>\n</li>"))
    }

    @Test func itemsAfterANestedListReturnToTheOuterLevel() {
        let html = render("- a\n\t- b\n\t\t- c\n\t- d\n- e")

        #expect(html.contains("<li>b<ul>\n<li>c</li>\n</ul>\n</li>\n<li>d</li>"))
        #expect(html.hasSuffix("<li>e</li>\n</ul>\n"))
    }

    // MARK: - Tight and loose

    @Test func aTightListHasNoParagraphTags() {
        #expect(!render("- a\n- b").contains("<p>"))
    }

    @Test func aBlankLineBetweenItemsMakesTheListLoose() {
        let html = render("- a\n\n- b")

        #expect(html.contains("<li><p>a</p>\n</li>"))
        #expect(html.contains("<li><p>b</p>\n</li>"))
    }

    @Test func aBlankLineBetweenBlocksInsideAnItemMakesTheListLoose() {
        let html = render("- a\n\n  more\n- b")

        #expect(html.contains("<li><p>a</p>\n<p>more</p>\n</li>"))
        #expect(html.contains("<li><p>b</p>\n</li>"))
    }

    @Test func aLooseNumberedListIsLooseToo() {
        #expect(render("1. a\n\n2. b").contains("<li><p>a</p>\n</li>"))
    }

    @Test func aLooseListDoesNotMakeItsTightChildLoose() {
        let html = render("- a\n\n  - child\n\n- b")

        #expect(html.contains("<li><p>a</p>\n<ul>\n<li>child</li>\n</ul>\n</li>"))
    }

    @Test func aLooseChildDoesNotMakeItsTightParentLoose() {
        let html = render("- a\n  - x\n\n  - y\n- b")

        #expect(html.contains("<li>a<ul>\n<li><p>x</p>\n</li>\n<li><p>y</p>\n</li>\n</ul>\n</li>"))
        #expect(html.contains("<li>b</li>"))
    }

    @Test func aBlankLineInsideACodeBlockDoesNotMakeAListLoose() {
        let html = render("- a\n  ```\n  x\n\n  y\n  ```\n- b")

        #expect(!html.contains("<p>"))
    }

    @Test func aLooseTaskListKeepsTheCheckboxOnTheSameLineAsItsText() {
        let html = render("- [ ] todo\n\n- [x] done")

        #expect(html.contains("<li class=\"task-list-item\"><p><input type=\"checkbox\" disabled> todo</p>"))
        #expect(html.contains("<li class=\"task-list-item\"><p><input type=\"checkbox\" disabled checked> done</p>"))
    }
}
