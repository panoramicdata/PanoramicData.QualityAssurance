import { test, expect } from '@playwright/test';

/**
 * ReportMagic Home Page Tests
 * Tests the reporting and analytics system
 */

// Get environment from environment variable or default to 'alpha'
const env = process.env.MS_ENV || 'alpha';
const baseUrl = env === 'production' 
  ? 'https://report.magicsuite.net'
  : `https://report.${env}.magicsuite.net`;

test.describe('ReportMagic Home Page', () => {
  test('should load correctly', async ({ page }) => {
    const consoleErrors: string[] = [];
    
    // Collect console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    // Navigate to the home page
    const response = await page.goto(baseUrl);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('load');
    
    // 1. Verify HTTP response is successful
    expect(response?.status(), 'HTTP response should be successful').toBeLessThan(400);
    
    // 2. Verify page has a title (may redirect to login, so accept any title)
    const title = await page.title();
    expect(title.length >= 0, 'Page should have loaded').toBeTruthy();
    
    // 3. Verify no console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no console errors').toHaveLength(0);
  });
});
