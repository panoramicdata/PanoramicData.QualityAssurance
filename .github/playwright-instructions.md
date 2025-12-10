# Playwright Test Instructions for Magic Suite

This document provides task-specific instructions for Merlin (AI Assistant) when working with Playwright tests for Magic Suite applications.

## Magic Suite Applications

The following applications are part of the Magic Suite platform and require testing:

| Application | URL Prefix | Description |
|-------------|------------|-------------|
| **Www** | `www` | Main Magic Suite website/portal |
| **Docs** | `docs` | Documentation portal (DocMagic) |
| **DataMagic** | `data` | Data visualization and database components |
| **AlertMagic** | `alert` | Alerting and notification system |
| **Admin** | `admin` | Administration console |
| **Connect** | `connect` | Integration and connectivity services |
| **ReportMagic** | `report` | Reporting and analytics |

## URL Structure

### Non-Production Environments

URLs follow the pattern:

```text
https://<app>.<env>.magicsuite.net/
```

Where:

- `<app>` is the application prefix (www, docs, data, alert, admin, connect, report)
- `<env>` is the environment name

### Supported Environments

| Environment | Description |
|-------------|-------------|
| `alpha` | Alpha testing environment |
| `alpha2` | Secondary alpha environment |
| `test` | Primary test environment |
| `test2` | Secondary test environment |
| `beta` | Beta testing environment |
| `staging` | Pre-production staging |
| `ps` | Professional services environment |

**Example URLs:**

- `https://alert.alpha.magicsuite.net/` - AlertMagic on Alpha
- `https://data.staging.magicsuite.net/` - DataMagic on Staging
- `https://docs.test.magicsuite.net/` - DocMagic on Test

### Production Environment

Production URLs follow a simplified pattern (no environment segment):

```text
https://<app>.magicsuite.net/
```

**Example Production URLs:**

- `https://docs.magicsuite.net/` - DocMagic Production
- `https://alert.magicsuite.net/` - AlertMagic Production
- `https://data.magicsuite.net/` - DataMagic Production
- `https://admin.magicsuite.net/` - Admin Production

## Test Folder Structure

Tests are organized under `playwright/Magic Suite/`:

```text
playwright/
└── Magic Suite/
    ├── Www/           # Main website tests
    ├── Docs/          # DocMagic tests
    ├── DataMagic/     # DataMagic tests
    ├── AlertMagic/    # AlertMagic tests
    ├── Admin/         # Admin console tests
    ├── Connect/       # Connect service tests
    └── ReportMagic/   # ReportMagic tests
```

## Test Naming Conventions

- Test files: `<TestName>.spec.ts` or `<TestName>.test.ts`
- Home page tests: `HomePage.spec.ts`
- Smoke tests: `Smoke.spec.ts`
- Regression tests: `Regression.spec.ts`

## Running Tests

### Using RunRegressionTests.ps1

The primary way to run tests is via the PowerShell script:

```powershell
# Run all tests on alpha environment
.\.github\tools\RunRegressionTests.ps1 -Environment alpha

# Run specific app tests
.\.github\tools\RunRegressionTests.ps1 -Environment staging -Apps AlertMagic,DataMagic

# Run production tests
.\.github\tools\RunRegressionTests.ps1 -Environment production

# Run with headed browser (visible)
.\.github\tools\RunRegressionTests.ps1 -Environment test -Headed
```

### Using VS Code Playwright Extension

1. Open the Testing sidebar (beaker icon)
2. Tests appear under "Playwright" section
3. Click play button to run individual tests
4. Use "Run All Tests" for full suite

## Creating New Tests

When creating new tests for Magic Suite:

1. **Identify the application** - Determine which app (AlertMagic, DataMagic, etc.)
2. **Create test file** - Add to appropriate folder under `playwright/Magic Suite/`
3. **Use environment configuration** - Tests should accept environment parameter
4. **Follow naming conventions** - Use descriptive test names
5. **Include console error checking** - All tests should verify no console errors

### Test Template

```typescript
import { test, expect } from '@playwright/test';

// Get environment from environment variable or default to 'alpha'
const env = process.env.MS_ENV || 'alpha';
const baseUrl = env === 'production' 
  ? 'https://<app>.magicsuite.net'
  : `https://<app>.${env}.magicsuite.net`;

test.describe('<AppName> Tests', () => {
  test('Home page loads without console errors', async ({ page }) => {
    const consoleErrors: string[] = [];
    
    // Known non-critical errors to ignore (CSP issues with analytics, etc.)
    const ignoredPatterns = [
      /Content Security Policy/i,
      /google-analytics/i,
      /gtag/i,
    ];
    
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        const isIgnored = ignoredPatterns.some(pattern => pattern.test(text));
        if (!isIgnored) {
          consoleErrors.push(text);
        }
      }
    });

    await page.goto(baseUrl);
    await expect(page).toHaveTitle(/<Expected Title>/);
    
    expect(consoleErrors).toHaveLength(0);
  });
});
```

## Guidance for Merlin

When working with Playwright tests:

1. **Check existing tests** before creating new ones
2. **Use consistent patterns** across all applications
3. **Environment awareness** - Always consider which environment is being tested
4. **Console error checking** - Include in all tests, but filter known non-critical errors (CSP, analytics)
5. **Update this document** when adding new applications or environments
6. **Run tests locally** before committing
7. **Document failures** in JIRA using the standard workflow

### Running Tests as Background Processes

When running Playwright tests, use background mode to avoid blocking:

```powershell
# Run as background process
cd playwright
$env:MS_ENV = 'alpha'
npx playwright test --project=chromium --reporter=list &

# Check terminal output periodically for results
```

**Key Points:**
- Use `--reporter=list` for cleaner output
- Tests typically take 20-30 seconds for the full suite
- Check terminal output after execution completes
- Failed tests include screenshots and videos in `test-results/`

### Known Test Behaviors

| Application | Notes |
|-------------|-------|
| DataMagic | Has CSP errors for Google Analytics (filtered as non-critical) |
| Docs | Home page title is "Getting Started" |
| ReportMagic | May redirect to login (empty title expected) |
| Connect | Requires authentication for full access |

## Related Documentation

- [Playwright README](../playwright/README.md) - MCP setup and configuration
- [Copilot Instructions](./copilot-instructions.md) - General guidance for Merlin
- [Test Plans](../test-plans/README.md) - Manual test plan documentation

---

**Last Updated**: December 2025
**Maintained By**: Panoramic Data QA Team
