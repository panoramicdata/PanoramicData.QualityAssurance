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
├── README.md              # This file
├── package.json           # Node.js dependencies
├── playwright.config.ts   # Playwright configuration
├── Magic Suite/           # Magic Suite application tests
│   ├── Www/               # Main portal tests
│   ├── Docs/              # DocMagic tests
│   ├── DataMagic/         # DataMagic tests
│   ├── AlertMagic/        # AlertMagic tests
│   ├── Admin/             # Admin console tests
│   ├── Connect/           # Connect service tests
│   └── ReportMagic/       # ReportMagic tests
├── traces/                # Playwright trace files (gitignored)
└── screenshots/           # Captured screenshots (gitignored)
```

## Running Regression Tests

### First Time Setup

```powershell
# Navigate to playwright directory
cd playwright

# Install dependencies
npm install

# Install browsers
npx playwright install
```

### Using the PowerShell Script (Recommended)

```powershell
# Run all tests on alpha environment
.\.github\tools\RunRegressionTests.ps1 -Environment alpha

# Run specific app tests
.\.github\tools\RunRegressionTests.ps1 -Environment staging -Apps AlertMagic,DataMagic

# Run with visible browser
.\.github\tools\RunRegressionTests.ps1 -Environment test -Headed

# Run production tests
.\.github\tools\RunRegressionTests.ps1 -Environment production
```

## Finding Test Videos 🎬

After running tests, videos are automatically recorded and organized by test run session:

### 🚀 Automatic Video Report with Run History (NEW!)
After each test run, an **HTML report with clickable video links** opens automatically!
- **Location**: `test-results/test-videos.html` (always shows latest run)
- **Archive**: Each run is saved to `test-results/video-reports/run-<timestamp>/`
- **History**: View last 10 test runs directly in the HTML report
- **Shows**: All videos organized by status (❌ Failed, ⚠️ Flaky, ✅ Passed)
- **Compare**: Easy access to previous test runs for comparison

### 📅 Multiple Test Runs
Running tests multiple times? No problem!
- Each test run gets a unique timestamp ID (e.g., `run-2026-01-15T10-30-00`)
- Videos are automatically archived for each session
- Compare results across different runs
- Last 50 runs are kept in the history

### 💻 Quick PowerShell Commands
```powershell
# List all recent videos from latest run
.\Get-TestVideos.ps1

# View all test run sessions with timestamps
.\Get-TestVideos.ps1 -Action list-runs

# Open a specific test run report
.\Get-TestVideos.ps1 -Action open-run -RunId "run-2026-01-15T10-30-00"

# Open the most recent video
.\Get-TestVideos.ps1 -Action open-latest

# Open all failed test videos (great for debugging!)
.\Get-TestVideos.ps1 -Action open-failed

# Open the latest HTML video report
.\Get-TestVideos.ps1 -Action open-report

# Open videos folder in Windows Explorer
explorer test-results
```

### ⚡ PowerShell Profile Functions (Even Faster!)
If you've sourced the `video-functions.ps1` file:
```powershell
Get-TestVideos           # or 'gtv' - List recent videos
Get-TestRunHistory       # or 'gtrh' - View all test runs
Open-TestRun "<run-id>"  # or 'open-run' - Open specific run
Open-LatestTestVideo     # or 'latest-video' - Open most recent
Open-FailedTestVideos    # or 'failed-videos' - Open failed tests
Open-TestVideoReport     # Open latest HTML report
```

### 📁 Manual Access
Videos are stored in: `test-results/<test-name>/video.webm`
- Each test gets its own folder
- Videos are in WebM format (playable in Chrome, Edge, Firefox)
- Automatically organized by test run session
- Both Markdown and HTML reports generated for each run
- History maintained in `test-results/video-reports/runs-index.json`

---

## 📂 Project Structure

```
playwright/
├── setup/                      # Setup scripts (auth, etc.)
│   ├── auth.setup.ts          # All authentication setups
│   └── README.md
├── .auth/                     # Saved authentication states
│   ├── user.json              # Default user
│   ├── super-admin.json       # Super admin
│   ├── tenant-admin.json      # Tenant admin
│   └── regular-user.json      # Regular user
├── Magic Suite/               # Test files organized by product
│   ├── Admin/                 # Admin Portal tests
│   ├── DataMagic/             # DataMagic tests
│   ├── ReportMagic/           # ReportMagic tests
│   ├── AlertMagic/            # AlertMagic tests
│   ├── Connect/               # Connect Portal tests
│   ├── Docs/                  # Documentation tests
│   ├── NCalc101/              # NCalc 101 tests
│   ├── Www/                   # Main Portal tests
│   ├── tests/                 # Special test suites
│   │   └── deep-link-validation.spec.ts
│   └── utils/                 # Shared utilities
│       ├── urls.ts
│       └── magic-suite-urls.ts
├── test-results/              # Test outputs, videos, reports
├── playwright.config.ts       # Playwright configuration
├── package.json               # Dependencies
├── DEEP-LINKS-REFERENCE.md    # URL reference guide
└── README.md                  # This file
```

---

## Using npm Scripts

```powershell
cd playwright

# === DEFAULT (Chromium Only - Fast) ===
# Run all tests on Chromium (default, recommended)
npm test

# === ALL BROWSERS ===
# Run tests on ALL 6 browsers (comprehensive, slower)
npm run test:all-browsers

# Run on all desktop browsers (Chromium, Firefox, WebKit)
npm run test:desktop

# Run on mobile viewports (Mobile Chrome, Mobile Safari)
npm run test:mobile

# === DEBUGGING ===
# Run with visible browser window
npm run test:headed

# Open Playwright UI mode (interactive)
npm run test:ui

# Debug mode with step-through
npm run test:debug

# View last test report
npm run report

# === INSTALL BROWSERS ===
# Install all Playwright browsers (Firefox, WebKit, Chromium)
npm run install-browsers
```

### Test Strategy

| Test Type | Command | Browsers | When to Use |
|-----------|---------|----------|-------------|
| Default | `npm test` | Chromium only | Development, daily testing |
| All Browsers | `npm run test:all-browsers` | All 6 browsers | Release validation, cross-browser check |
| Desktop Only | `npm run test:desktop` | Chrome, Firefox, Safari | Desktop browser compatibility |
| Mobile Only | `npm run test:mobile` | Mobile Chrome, Mobile Safari | Mobile responsiveness testing |

**Default behavior**: All tests run on **Chromium only** for fast feedback during development.

**Multi-browser testing**: Use `npm run test:all-browsers` when you need to validate cross-browser compatibility (e.g., before releases).

**Efficient tests**: Each test file now uses a single consolidated test that checks multiple things (HTTP status, title, console errors) in one page load for maximum efficiency.

### Using VS Code Testing Panel

1. **Open Testing Sidebar**: Click the beaker icon in the Activity Bar
2. **View Tests**: Tests appear under "PLAYWRIGHT" section
3. **Run Individual Tests**: Click the play button next to any test
4. **Run All Tests**: Click "Run All Tests" at the top
5. **Debug Tests**: Right-click a test and select "Debug Test"

### Environment Selection

Set the `MS_ENV` environment variable to target different environments:

```powershell
$env:MS_ENV = 'staging'
npm test
```

Valid environments: `alpha`, `alpha2`, `test`, `test2`, `beta`, `staging`, `ps`, `production`

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
