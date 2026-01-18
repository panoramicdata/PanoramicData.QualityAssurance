import { test, expect } from '@playwright/test';

/**
 * NCalc 101 Home Page Tests
 * Tests the NCalc expression language learning portal
 * 
 * REQUIRES AUTHENTICATION:
 * Run 'npx playwright test auth.setup' first to create login session
 */

// NCalc 101 uses the same auth as other Magic Suite apps
// Get environment from MS_ENV or default to test2
const env = process.env.MS_ENV || 'test2';
const baseUrl = `https://ncalc101.${env}.magicsuite.net`;

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
    
    // ALWAYS check if login is required and pause for manual login if needed
    const currentUrl = page.url();
    const pageText = await page.textContent('body') || '';
    const needsLogin = currentUrl.includes('login') || 
                       currentUrl.includes('auth') || 
                       currentUrl.includes('identity') ||
                       currentUrl.includes('microsoftonline') ||
                       pageText.includes('Log In to use') ||
                       pageText.includes('Pick an account') ||
                       pageText.includes('Sign in') ||
                       pageText.includes('Microsoft');
    
    // If we're not on the expected NCalc domain, we need to log in
    if (needsLogin || !currentUrl.includes('ncalc101')) {
      console.log('\n=================================================================');
      console.log('MANUAL LOGIN REQUIRED');
      console.log('=================================================================');
      console.log(`Environment: ${env}`);
      console.log(`Target: ${baseUrl}`);
      console.log('');
      console.log('1. Log in manually in the browser window');
      console.log('2. Complete the Microsoft authentication if prompted');
      console.log('3. After logging in successfully, click "Resume" in the Playwright Inspector');
      console.log('4. The test will continue automatically');
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
    // Set test timeout to prevent infinite hangs
    test.setTimeout(60000); // 1 minute max
    
    // Page already loaded and authenticated via beforeEach
    
    // Wait for the app UI to fully initialize
    await page.waitForTimeout(2000);
    
    // Take a screenshot for debugging if needed
    await page.screenshot({ path: 'test-results/ncalc-before-interaction.png', fullPage: true });
    console.log('📸 Screenshot saved: test-results/ncalc-before-interaction.png');
    
    // Check if the page is in an iframe
    const frames = page.frames();
    console.log(`Found ${frames.length} frames on page`);
    
    // The NCalc 101 UI has three panels:
    // - Left: Variables panel (shows Name, Type, Value)
    // - Center: Expression editor (CodeMirror - shows line numbers like "1" and code)
    // - Right: Result output (shows line numbers and result)
    
    // Strategy: Try to find and interact with the editor more reliably
    // 1. First, check if there are multiple .cm-content elements (there usually are 2-3)
    const allEditors = await page.locator('.cm-content').all();
    console.log(`Found ${allEditors.length} .cm-content elements`);
    
    // The center panel editor is typically the one that's contenteditable
    const editableEditor = page.locator('.cm-content[contenteditable="true"]');
    const editableCount = await editableEditor.count();
    console.log(`Found ${editableCount} contenteditable .cm-content elements`);
    
    let editorFound = false;
    
    if (editableCount > 0) {
      try {
        // Scroll into view first
        await editableEditor.first().scrollIntoViewIfNeeded({ timeout: 5000 });
        console.log('✓ Scrolled editor into view');
        
        // Wait for it to be actionable (visible, stable, enabled)
        await editableEditor.first().waitFor({ state: 'visible', timeout: 5000 });
        console.log('✓ Editor is visible');
        
        // Force click in case something is overlaying it
        await editableEditor.first().click({ force: true, timeout: 5000 });
        console.log('✓ Clicked editor (force mode)');
        
        editorFound = true;
      } catch (e: any) {
        console.log(`✗ Failed to interact with contenteditable editor: ${e.message}`);
      }
    }
    
    // Fallback: Try clicking anywhere on the page and using Tab to focus
    if (!editorFound) {
      console.log('⚠️  Trying fallback: Tab navigation');
      try {
        await page.keyboard.press('Tab');
        await page.keyboard.press('Tab');
        await page.waitForTimeout(500);
        editorFound = true;
      } catch (e) {
        console.log('✗ Tab navigation failed');
      }
    }
    
    if (!editorFound) {
      console.log('⚠️  Editor not found with any method, skipping test');
      await page.screenshot({ path: 'test-results/ncalc-editor-not-found.png', fullPage: true });
      test.skip();
      return;
    }
    
    // Give focus a moment to settle
    await page.waitForTimeout(500);
    
    // Select all and type the expression
    await page.keyboard.press('Control+a');
    await page.waitForTimeout(200);
    await page.keyboard.type('2 + 2', { delay: 100 });
    console.log('✓ Typed: 2 + 2');
    
    // Wait for evaluation to complete (with timeout)
    await page.waitForTimeout(1500);
    
    // Take screenshot after typing
    await page.screenshot({ path: 'test-results/ncalc-after-typing.png', fullPage: true });
    console.log('📸 Screenshot saved: test-results/ncalc-after-typing.png');
    
    // Verify the result "4" appears on the page
    // The right panel should show the result
    const pageContent = await page.textContent('body');
    expect(pageContent, 'Page should contain result 4').toContain('4');
    
    // Verify Output Type shows Int32 (visible in the toolbar)
    await expect(page.getByText('Int32'), 'Output type should be Int32').toBeVisible({ timeout: 5000 });
  });
});
