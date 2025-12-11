# Playwright Screenshots

This folder stores screenshots captured during Playwright MCP sessions.

Screenshot files are gitignored and not committed to the repository.

## Capturing Screenshots

Enable vision capabilities in your MCP configuration:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--caps", "vision"]
    }
  }
}
```

Then use the screenshot tools available in the Playwright MCP toolset.

## Using Screenshots for JIRA

When documenting bugs:

1. Capture screenshots of the issue
2. Save to this folder with descriptive names (e.g., `MS-12345-bug-screenshot.png`)
3. Reference in JIRA ticket comments
4. Attach to JIRA if needed
