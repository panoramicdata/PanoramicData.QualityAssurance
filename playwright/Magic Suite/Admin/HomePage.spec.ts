import { test, expect } from '@playwright/test';

/**
 * Admin Home Page Tests
 * Tests the administration console
 */

// Get environment from environment variable or default to 'alpha'
const env = process.env.MS_ENV || 'alpha';
const baseUrl = env === 'production' 
  ? 'https://admin.magicsuite.net'
  : `https://admin.${env}.magicsuite.net`;

test.describe('Admin Home Page', () => {
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
    
    // 2. Verify page has correct title
    await expect(page, 'Page should have correct title').toHaveTitle(/Admin|Administration|Magic Suite/i);
    
    // 3. Verify no console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no console errors').toHaveLength(0);
  });
});
