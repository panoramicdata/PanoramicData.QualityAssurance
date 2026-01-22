import { test, expect } from '@playwright/test';

/**
 * NCalc 101 Home Page Tests
 * Tests the NCalc expression language learning portal
 * 
 * AUTHENTICATION:
 * - Uses saved auth from .auth/user.json (automatically loaded by playwright.config.ts)
 * - To set up auth for the first time, run: npx playwright test setup/auth.setup.ts
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
  // Note: Authentication is handled automatically via storageState in playwright.config.ts
  // The .auth/user.json file is loaded automatically if it exists
  test.beforeEach(async ({ page }) => {
    // Navigate to NCalc 101 - auth state should be loaded from .auth/user.json
    await page.goto(baseUrl);
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Wait for app to fully load
    await page.waitForTimeout(2000);
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
    
    // Check if there's an iframe that contains the editor
    const frames = page.frames();
    console.log(`Found ${frames.length} frames on page`);
    
    // Try to find the iframe containing the NCalc editor
    let workingFrame = page;
    const iframes = await page.locator('iframe').all();
    if (iframes.length > 0) {
      console.log(`Found ${iframes.length} iframes, checking for editor...`);
      for (const iframe of iframes) {
        try {
          const frameElement = await iframe.contentFrame();
          if (frameElement) {
            const editorInFrame = await frameElement.locator('.cm-content').count();
            if (editorInFrame > 0) {
              console.log(`✓ Found ${editorInFrame} editors in iframe`);
              workingFrame = frameElement as any;
              break;
            }
          }
        } catch (e) {
          // Skip iframes that can't be accessed
        }
      }
    }
    
    // Wait longer for Monaco editor to load
    console.log('Waiting for Monaco editor to load...');
    await page.waitForTimeout(3000);
    
    // The NCalc 101 UI has three panels:
    // - Left: Variables panel (shows Name, Type, Value)
    // - Center: Expression editor (Monaco editor - the editable area)
    // - Right: Result output (shows the evaluation result)
    
    // Look for Monaco editor - it uses .monaco-editor and .view-line classes
    const monacoEditors = await workingFrame.locator('.monaco-editor').all();
    console.log(`Found ${monacoEditors.length} Monaco editors`);
    
    // Find the editable Monaco editor (center panel - Expression editor)
    // Look for the editor with contenteditable textarea or the lines-content div
    const editorContent = workingFrame.locator('.monaco-editor .lines-content').first();
    const editorExists = await editorContent.count() > 0;
    
    if (editorExists) {
      try {
        console.log('✓ Found Monaco editor content area');
        
        // Click on the view-line (the actual text line) to focus the editor
        // Use force click to bypass overlays
        const viewLine = workingFrame.locator('.monaco-editor .view-line').first();
        await viewLine.click({ force: true, timeout: 5000 });
        console.log('✓ Clicked Monaco editor (view-line)');
        
        await page.waitForTimeout(300);
        
        // Select all text in the editor (Ctrl+A)
        await workingFrame.keyboard.press('Control+A');
        await page.waitForTimeout(200);
        console.log('✓ Selected all text');
        
        // Delete the selected text
        await workingFrame.keyboard.press('Delete');
        await page.waitForTimeout(300);
        console.log('✓ Deleted existing content');
        
        // Type the new expression
        await workingFrame.keyboard.type('2 + 2', { delay: 100 });
        console.log('✓ Typed: 2 + 2');
        
      } catch (e: any) {
        console.log(`✗ Failed to interact with Monaco editor: ${e.message}`);
        throw e;
      }
    } else {
      console.log('✗ Monaco editor not found');
      await page.screenshot({ path: 'test-results/ncalc-editor-not-found.png', fullPage: true });
      throw new Error('Monaco editor not found on page');
    }
    
    // Wait for evaluation to complete
    await page.waitForTimeout(2000);
    
    // Take screenshot after typing
    await page.screenshot({ path: 'test-results/ncalc-after-typing.png', fullPage: true });
    console.log('📸 Screenshot saved: test-results/ncalc-after-typing.png');
    
    // Verify the result "4" appears in the rightmost result panel
    // Look for Monaco editor view lines which contain the result
    const viewLines = await workingFrame.locator('.view-line').allTextContents();
    console.log(`✓ Found view lines with content: ${viewLines.join(', ')}`);
    
    // The result "4" should appear in one of the view lines
    const hasResult = viewLines.some(line => line.trim() === '4');
    expect(hasResult, 'Result panel should show "4"').toBe(true);
    
    // Verify Output Type shows Int32 (visible in the toolbar)
    await expect(page.getByText('Int32').first(), 'Output type should be Int32').toBeVisible({ timeout: 5000 });
    console.log('✓ Test passed: 2 + 2 = 4 verified');
  });
});
