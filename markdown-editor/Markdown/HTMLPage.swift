import Foundation

/// Wraps rendered body HTML in a complete page: the styles, a security policy, and the starting scroll position.
nonisolated enum HTMLPage {
    /// Builds the page. `initialScrollOffset` keeps the preview where it was when it reloads.
    static func make(body: String, initialScrollOffset: Double = 0) -> String {
        // The nonce lets only our own script run, even if some markup were ever to slip through unescaped.
        let nonce = UUID().uuidString
        let scrollY = Int(exactly: initialScrollOffset.rounded()) ?? 0

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="\(contentSecurityPolicy(scriptNonce: nonce))">
        <style>
        \(PreviewStylesheet.css)
        </style>
        </head>
        <body>
        \(body)
        <script nonce="\(nonce)">window.scrollTo(0, \(scrollY));</script>
        </body>
        </html>
        """
    }

    /// Allows nothing except inline styles, our script, and images from the local image scheme, so a
    /// markdown file can never make the preview contact the network.
    private static func contentSecurityPolicy(scriptNonce: String) -> String {
        [
            "default-src 'none'",
            "style-src 'unsafe-inline'",
            "script-src 'nonce-\(scriptNonce)'",
            "img-src \(LocalImageSchemeHandler.scheme):"
        ].joined(separator: "; ")
    }
}
