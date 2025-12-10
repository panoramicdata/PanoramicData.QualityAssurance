# Playwright MCP Integration

This folder contains Playwright-based browser automation tools and configurations for the Quality Assurance team.

## Overview

[Playwright MCP](https://github.com/microsoft/playwright-mcp) is a Model Context Protocol server that enables AI assistants (like Merlin/GitHub Copilot) to interact with web browsers for testing and automation tasks.

## Prerequisites

- **Node.js** 18.x or later
- **npm** (comes with Node.js)
- **VS Code** with GitHub Copilot extension

## Installation

### 1. Install Playwright MCP globally (optional)

```powershell
npm install -g @playwright/mcp
```

Or run directly with npx (no installation required):

```powershell
npx @playwright/mcp@latest --help
```

### 2. Configure VS Code MCP Settings

Add the Playwright MCP server to your VS Code settings. Create or edit `.vscode/mcp.json` in your workspace:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"],
      "env": {}
    }
  }
}
```

#### Alternative: Headed Mode (Visible Browser)

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--browser", "chrome"],
      "env": {}
    }
  }
}
```

### 3. Verify Installation

Run the following command to verify Playwright MCP is working:

```powershell
npx @playwright/mcp@latest --help
```

You should see a list of available options.

## Configuration Options

### Browser Selection

```powershell
# Use different browsers
npx @playwright/mcp@latest --browser chrome
npx @playwright/mcp@latest --browser firefox
npx @playwright/mcp@latest --browser webkit
npx @playwright/mcp@latest --browser msedge
```

### Headless vs Headed Mode

```powershell
# Headless (default for MCP) - no visible browser window
npx @playwright/mcp@latest --headless

# Headed - visible browser window (useful for debugging)
npx @playwright/mcp@latest  # (headed is default when not using MCP)
```

### Device Emulation

```powershell
# Emulate mobile devices
npx @playwright/mcp@latest --device "iPhone 15"
npx @playwright/mcp@latest --device "Pixel 7"
```

### Screenshot and Vision Capabilities

```powershell
# Enable vision capabilities for screenshots
npx @playwright/mcp@latest --caps vision
```

### Tracing and Recording

```powershell
# Save session traces for debugging
npx @playwright/mcp@latest --save-trace --output-dir ./traces

# Record video of session
npx @playwright/mcp@latest --save-video=1280x720 --output-dir ./videos
```

### Proxy Configuration

```powershell
# Use a proxy server
npx @playwright/mcp@latest --proxy-server "http://myproxy:3128"
```

## VS Code MCP Configuration Examples

### Basic Configuration

Create `.vscode/mcp.json`:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

### Chrome with Vision Capabilities

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--browser", "chrome",
        "--caps", "vision"
      ]
    }
  }
}
```

### Full Featured Configuration

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--browser", "chrome",
        "--caps", "vision",
        "--save-trace",
        "--output-dir", "./playwright/traces",
        "--viewport-size", "1920x1080"
      ]
    }
  }
}
```

### Mobile Testing Configuration

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--device", "iPhone 15",
        "--caps", "vision"
      ]
    }
  }
}
```

## Common Use Cases for QA

### 1. UI Testing for Magic Suite

Use Playwright MCP to:

- Navigate to Magic Suite pages
- Verify UI elements are displayed correctly
- Test form submissions and interactions
- Capture screenshots for bug reports

### 2. AlertMagic Testing

- Navigate to `https://alert.magicsuite.net`
- Verify payload displays
- Test filtering and sorting
- Validate incident creation/update workflows

### 3. Cross-Browser Compatibility

- Test the same workflows in Chrome, Firefox, and Edge
- Verify responsive layouts
- Check mobile device emulation

### 4. Regression Testing

- Automate repetitive UI checks
- Capture traces for comparison
- Document UI state with screenshots

## Folder Structure

```text
playwright/
├── README.md           # This file
├── magic suite/        # Magic Suite specific tests and recordings
├── traces/             # Playwright trace files (gitignored)
└── screenshots/        # Captured screenshots (gitignored)
```

## Troubleshooting

### MCP Server Not Starting

1. Verify Node.js is installed: `node --version`
2. Clear npm cache: `npm cache clean --force`
3. Reinstall: `npm install -g @playwright/mcp`

### Browser Not Launching

1. Install browser dependencies:

   ```powershell
   npx playwright install
   ```

2. Install specific browser:

   ```powershell
   npx playwright install chrome
   ```

### Timeout Issues

Increase timeouts in MCP arguments:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--timeout-navigation", "120000",
        "--timeout-action", "30000"
      ]
    }
  }
}
```

### SSL/Certificate Errors

For internal sites with self-signed certificates:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--ignore-https-errors"
      ]
    }
  }
}
```

## Integration with JIRA

When using Playwright for testing JIRA issues:

1. Capture screenshots of bugs using `--caps vision`
2. Save traces for complex reproduction steps
3. Include Playwright trace files in bug reports when relevant
4. Reference test execution in JIRA comments

## Related Documentation

- [Playwright MCP GitHub](https://github.com/microsoft/playwright-mcp)
- [Playwright Documentation](https://playwright.dev/docs/intro)
- [VS Code MCP Extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-dev)
- [Root README](../README.md)
- [Copilot Instructions](../.github/copilot-instructions.md)

---

**Last Updated**: December 2025
**Maintained By**: Panoramic Data QA Team
