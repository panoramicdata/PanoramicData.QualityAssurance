# Playwright Traces

This folder stores Playwright trace files for debugging test sessions.

Trace files are gitignored and not committed to the repository.

## Creating Traces

To save traces during a Playwright MCP session, use the `--save-trace` option:

```powershell
npx @playwright/mcp@latest --save-trace --output-dir ./playwright/traces
```

## Viewing Traces

Open trace files in the Playwright Trace Viewer:

```powershell
npx playwright show-trace ./playwright/traces/trace.zip
```

Or view online at: <https://trace.playwright.dev/>
