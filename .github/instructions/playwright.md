# Playwright Testing Instructions

## Critical Rules
- **ALWAYS use Firefox** as default browser: `--project=firefox`
- **NEVER omit --project flag** when running tests
- **ALWAYS authenticate first** before running tests
- **Store screenshots** in `playwright/screenshots/` with descriptive names

## Setup & Authentication

### Initial Setup
```powershell
# Navigate to playwright folder
cd playwright

# Install dependencies (first time only)
npm install

# Install browsers (first time only)
npx playwright install
```

### Authentication
**CRITICAL**: Always run authentication setup before tests!

```powershell
# Firefox (default)
npx playwright test auth.setup --project=firefox

# Chromium (if needed)
npx playwright test auth.setup --project=chromium
```

Authentication saves to `.auth/user.json` and is reused by all tests.

## Running Tests

### Single Test File
```powershell
# Run specific test with Firefox
npx playwright test "Magic Suite/DataMagic/datamagic-basic.spec.ts" --project=firefox

# Run with UI mode for debugging
npx playwright test "Magic Suite/DataMagic/datamagic-basic.spec.ts" --project=firefox --ui
```

### Multiple Tests
```powershell
# Run all tests in a folder
npx playwright test "Magic Suite/DataMagic/" --project=firefox

# Run all Magic Suite tests
npx playwright test "Magic Suite/" --project=firefox
```

### Headed Mode (See Browser)
```powershell
# Show browser during test
npx playwright test --project=firefox --headed

# Show browser with slow motion
npx playwright test --project=firefox --headed --slow-mo=1000
```

### Debug Mode
```powershell
# Open Playwright Inspector
npx playwright test --project=firefox --debug

# Debug specific test
npx playwright test "Magic Suite/DataMagic/test.spec.ts" --project=firefox --debug
```

## Test Structure

### File Organization
```
playwright/
  ├── Magic Suite/
  │   ├── Admin/
  │   ├── AlertMagic/
  │   ├── Connect/
  │   ├── DataMagic/
  │   ├── Docs/
  │   ├── NCalc101/
  │   ├── ReportMagic/
  │   └── Www/
  ├── playwright/
  ├── playwright-report/
  ├── screenshots/
  ├── test-results/
  └── traces/
```

### Test File Template
```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to starting page
    await page.goto('https://test2.magicsuite.net/datamagic');
  });

  test('should do something', async ({ page }) => {
    // Test steps
    await page.click('button#submit');
    
    // Assertions
    await expect(page.locator('.success-message')).toBeVisible();
    
    // Screenshot
    await page.screenshot({ 
      path: 'screenshots/feature-test-success.png',
      fullPage: true 
    });
  });
});
```

## Test Environment Confirmation

**CRITICAL**: Before running any test, ALWAYS confirm which environment you're testing against!

### Standard Confirmation Pattern
```
⚠️ TEST ENVIRONMENT CONFIRMATION REQUIRED

I'm about to run tests against: test2.magicsuite.net
Application: DataMagic
Test Type: UI regression tests
Expected Duration: ~5 minutes

Is this the correct test environment? Please confirm before I proceed.
```

**Do NOT proceed with tests until user confirms!**

## Screenshots & Artifacts

### Taking Screenshots
```typescript
// Full page screenshot
await page.screenshot({ 
  path: 'playwright/screenshots/test-name.png',
  fullPage: true 
});

// Element screenshot
await page.locator('.specific-element').screenshot({ 
  path: 'playwright/screenshots/element.png'
});

// With annotations
await page.locator('.error').screenshot({ 
  path: 'playwright/screenshots/error-state.png',
  animations: 'disabled'
});
```

### Screenshot Naming Convention
Format: `[app]-[feature]-[state]-[date].png`

Examples:
- `datamagic-query-builder-success-20260113.png`
- `reportmagic-scheduler-error-20260113.png`
- `admin-users-list-20260113.png`

### Viewing Test Reports
```powershell
# Open HTML report
npx playwright show-report

# Generate report after test run
npx playwright test --project=firefox --reporter=html
```

### Viewing Traces
```powershell
# View trace for failed test
npx playwright show-trace test-results/[test-name]/trace.zip
```

## Common Selectors

### By Role
```typescript
// Button
await page.getByRole('button', { name: 'Submit' }).click();

// Link
await page.getByRole('link', { name: 'Dashboard' }).click();

// Text input
await page.getByRole('textbox', { name: 'Search' }).fill('query');
```

### By Test ID
```typescript
// Use data-testid attribute
await page.getByTestId('submit-button').click();
```

### By Text
```typescript
// Exact text
await page.getByText('Login').click();

// Partial text
await page.getByText(/Log/, { exact: false }).click();
```

### CSS Selectors
```typescript
// ID
await page.locator('#submit-button').click();

// Class
await page.locator('.btn-primary').click();

// Nested
await page.locator('div.form > button.submit').click();
```

## Assertions

### Visibility
```typescript
// Element is visible
await expect(page.locator('.success')).toBeVisible();

// Element is hidden
await expect(page.locator('.error')).toBeHidden();
```

### Text Content
```typescript
// Contains text
await expect(page.locator('.message')).toContainText('Success');

// Exact text
await expect(page.locator('.title')).toHaveText('Dashboard');
```

### Attributes
```typescript
// Has attribute
await expect(page.locator('input')).toHaveAttribute('disabled');

// Attribute value
await expect(page.locator('a')).toHaveAttribute('href', '/dashboard');
```

### Count
```typescript
// Number of elements
await expect(page.locator('.list-item')).toHaveCount(5);
```

## Waits & Timeouts

### Wait for Element
```typescript
// Wait for element to be visible
await page.waitForSelector('.loading', { state: 'hidden' });

// Wait for navigation
await page.waitForURL('**/dashboard');

// Wait for load state
await page.waitForLoadState('networkidle');
```

### Custom Timeout
```typescript
// Longer timeout for slow operations
await page.locator('.slow-element').click({ timeout: 30000 });

// Wait with custom timeout
await page.waitForSelector('.result', { timeout: 60000 });
```

## Common Pitfalls

### Missing --project Flag
- ❌ **Wrong**: `npx playwright test auth.setup`
- ✅ **Correct**: `npx playwright test auth.setup --project=firefox`
- **Result**: Without flag, both chromium AND firefox open simultaneously

### Not Authenticating First
- ❌ **Wrong**: Running tests without auth.setup
- ✅ **Correct**: Always run `auth.setup` before tests
- **Result**: Tests fail with authentication errors

### Wrong File Paths
- ❌ **Wrong**: `npx playwright test tests/auth.setup.spec.ts`
- ✅ **Correct**: `npx playwright test auth.setup`
- **Result**: Test pattern matching works better than full paths

### Not Confirming Environment
- ❌ **Wrong**: Running tests immediately without confirmation
- ✅ **Correct**: Always ask which environment before running tests
- **Result**: Tests might run against wrong environment (e.g., production!)

### Screenshot Locations
- ❌ **Wrong**: Saving screenshots outside playwright folder
- ✅ **Correct**: Save to `playwright/screenshots/`
- **Result**: Screenshots not tracked or easily accessible

## Test Environments

| Environment | URL | Purpose |
|-------------|-----|---------|
| test2 (default) | test2.magicsuite.net | Primary testing |
| test | test.magicsuite.net | Secondary testing |
| alpha2 | alpha2.magicsuite.net | Alpha testing |
| alpha | alpha.magicsuite.net | Early alpha |
| beta | beta.magicsuite.net | Beta testing |
| staging | staging.magicsuite.net | Pre-production |
| production | magicsuite.net | Live environment |

**ALWAYS confirm environment before running tests!**

## Configuration

Located in `playwright.config.ts`:
- Base URL configuration
- Test timeout settings
- Browser projects (firefox, chromium)
- Screenshot/trace settings
- Reporter configuration

To modify:
1. Edit `playwright.config.ts`
2. Restart any running test processes
3. Test changes with simple test first
