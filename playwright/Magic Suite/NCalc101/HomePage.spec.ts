import { test, expect } from '@playwright/test';

/**
 * NCalc 101 Home Page Tests
 * Tests the NCalc expression language learning portal
 * 
 * REQUIRES AUTHENTICATION:
 * Run 'npx playwright test auth.setup' first to create login session
 */

// NCalc 101 uses the same auth as other Magic Suite apps
const baseUrl = 'https://ncalc101.magicsuite.net';

// Known non-critical errors to ignore (CSP issues with analytics, etc.)
const ignoredPatterns = [
  /Content Security Policy/i,
  /google-analytics/i,
  /gtag/i,
];

test.describe('NCalc 101 Home Page', () => {
  // Ensure we're authenticated before each test
  test.beforeEach(async ({ page }) => {
    // Set generous timeout for potential manual login
    test.setTimeout(300000); // 5 minutes
    
    // Navigate to NCalc 101 - auth state should be loaded from .auth/user.json
    await page.goto(baseUrl);
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check if login is required - by URL or page content
    const currentUrl = page.url();
    const pageText = await page.textContent('body') || '';
    const needsLogin = currentUrl.includes('login') || 
                       currentUrl.includes('auth') || 
                       currentUrl.includes('identity') ||
                       currentUrl.includes('microsoftonline') ||
                       pageText.includes('Log In to use') ||
                       pageText.includes('Pick an account') ||
                       pageText.includes('Sign in');
    
    if (needsLogin) {
      console.log('\n=================================================================');
      console.log('MANUAL LOGIN REQUIRED');
      console.log('=================================================================');
      console.log('1. Log in manually in the browser window');
      console.log('2. After logging in, click "Resume" in the Playwright Inspector');
      console.log('=================================================================\n');
      
      // Pause for manual login - user clicks Resume when done
      await page.pause();
      
      // After resume, navigate to the target page
      await page.goto(baseUrl);
      await page.waitForLoadState('networkidle');
      
      // Wait for app to fully load after login
      await page.waitForTimeout(2000);
    }
  });

  test('should load correctly', async ({ page }) => {
    const consoleErrors: string[] = [];
    
    // Collect console errors (excluding known non-critical ones)
    page.on('console', msg => {
      if (msg.type() === 'error') {
        const text = msg.text();
        const isIgnored = ignoredPatterns.some(pattern => pattern.test(text));
        if (!isIgnored) {
          consoleErrors.push(text);
        }
      }
    });

    // Navigate to the home page
    const response = await page.goto(baseUrl);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('load');
    
    // 1. Verify HTTP response is successful
    expect(response?.status(), 'HTTP response should be successful').toBeLessThan(400);
    
    // 2. Verify page has correct title
    await expect(page, 'Page should have correct title').toHaveTitle(/NCalc|101|Expression|Magic Suite/i);
    
    // 3. Verify no console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no console errors').toHaveLength(0);
  });

  test('should have main navigation elements', async ({ page }) => {
    await page.goto(baseUrl);
    await page.waitForLoadState('load');
    
    // Verify key navigation or content elements exist
    // NCalc 101 should have documentation content about NCalc expressions
    const mainContent = page.locator('main, .content, #content, article').first();
    await expect(mainContent, 'Page should have main content area').toBeVisible();
  });

  test('should have NCalc-related content', async ({ page }) => {
    // Page already loaded via beforeEach
    
    // Check that page contains NCalc-related text
    const pageContent = await page.textContent('body');
    expect(pageContent?.toLowerCase(), 'Page should mention NCalc or expressions').toMatch(/ncalc|expression|function|operator/i);
  });

  test('should evaluate 2 + 2 and return 4', async ({ page }) => {
    // Page already loaded and authenticated via beforeEach
    
    // Wait for the app UI to fully initialize
    await page.waitForTimeout(2000);
    
    // The NCalc 101 UI has three panels:
    // - Left: Variables panel (shows Name, Type, Value)
    // - Center: Expression editor (CodeMirror - shows line numbers like "1" and code)
    // - Right: Result output (shows line numbers and result)
    
    // Find the expression editor - it's a CodeMirror instance
    // Look for the editable content area in the center panel
    const editorSelectors = [
      '.cm-content[contenteditable="true"]',
      '.cm-editor .cm-content',
      '.cm-line',
      '[role="textbox"]',
      'textarea'
    ];
    
    let editorFound = false;
    for (const selector of editorSelectors) {
      const locator = page.locator(selector).first();
      try {
        if (await locator.isVisible({ timeout: 2000 })) {
          console.log(`Found editor with selector: ${selector}`);
          await locator.click();
          editorFound = true;
          break;
        }
      } catch {
        // Try next selector
      }
    }
    
    if (!editorFound) {
      // Try clicking on line number "1" area to focus the editor
      const lineNumber = page.locator('text="1"').first();
      if (await lineNumber.isVisible({ timeout: 1000 }).catch(() => false)) {
        await lineNumber.click();
      }
    }
    
    // Select all and type the expression
    await page.keyboard.press('Control+a');
    await page.keyboard.type('2 + 2');
    
    // Wait for evaluation to complete
    await page.waitForTimeout(1500);
    
    // Verify the result "4" appears on the page
    // The right panel should show the result
    const pageContent = await page.textContent('body');
    expect(pageContent, 'Page should contain result 4').toContain('4');
    
    // Verify Output Type shows Int32 (visible in the toolbar)
    await expect(page.getByText('Int32'), 'Output type should be Int32').toBeVisible({ timeout: 5000 });
  });
});
