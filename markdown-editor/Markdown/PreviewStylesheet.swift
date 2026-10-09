/// The preview's CSS: a small GitHub-like style that follows the system light or dark appearance.
nonisolated enum PreviewStylesheet {
    static let css = """
    :root {
      color-scheme: light dark;
      --text: #1f2328;
      --muted: #59636e;
      --background: #ffffff;
      --border: #d1d9e0;
      --code-background: #f6f8fa;
      --link: #0969da;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --text: #f0f6fc;
        --muted: #9198a1;
        --background: #0d1117;
        --border: #3d444d;
        --code-background: #151b23;
        --link: #4493f8;
      }
    }

    html { background: var(--background); }
    body {
      max-width: 880px;
      margin: 0 auto;
      padding: 24px 32px 48px;
      color: var(--text);
      background: var(--background);
      font: 16px/1.5 -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
      overflow-wrap: break-word;
    }
    body > :first-child { margin-top: 0; }

    h1, h2, h3, h4, h5, h6 { margin: 1.5em 0 16px; font-weight: 600; line-height: 1.25; }
    h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
    h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid var(--border); }
    h3 { font-size: 1.25em; }
    h4 { font-size: 1em; }
    h5 { font-size: 0.875em; }
    h6 { font-size: 0.85em; color: var(--muted); }

    p, ul, ol, blockquote, pre, table { margin: 0 0 16px; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    img { max-width: 100%; }
    hr { height: 0.25em; margin: 24px 0; padding: 0; background: var(--border); border: 0; }

    ul, ol { padding-left: 2em; }
    li + li { margin-top: 0.25em; }
    li > ul, li > ol { margin: 0.25em 0 0; }
    li > p { margin: 16px 0 0; }
    li:first-child > p:first-child { margin-top: 0; }
    .task-list-item { list-style: none; }
    .task-list-item input { margin: 0 0.4em 0.25em -1.4em; vertical-align: middle; }

    code {
      padding: 0.2em 0.4em;
      font: 85% ui-monospace, SFMono-Regular, Menlo, monospace;
      background: var(--code-background);
      border-radius: 6px;
    }
    pre {
      padding: 16px;
      overflow: auto;
      font: 85%/1.45 ui-monospace, SFMono-Regular, Menlo, monospace;
      background: var(--code-background);
      border-radius: 6px;
    }
    pre code { padding: 0; font-size: 100%; background: transparent; }

    blockquote { padding: 0 1em; color: var(--muted); border-left: 0.25em solid var(--border); }
    blockquote > :last-child { margin-bottom: 0; }

    table { display: block; width: max-content; max-width: 100%; overflow: auto; border-collapse: collapse; }
    th, td { padding: 6px 13px; border: 1px solid var(--border); }
    th { font-weight: 600; }
    tbody tr:nth-child(even) { background: var(--code-background); }
    """
}
