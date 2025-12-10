import { test, expect } from '@playwright/test';

/**
 * DataMagic Home Page Tests
 * Tests the data visualization and database components
 */

// Get environment from environment variable or default to 'alpha'
const env = process.env.MS_ENV || 'alpha';
const baseUrl = env === 'production' 
  ? 'https://data.magicsuite.net'
  : `https://data.${env}.magicsuite.net`;

// Known non-critical errors to ignore (CSP issues with analytics, etc.)
const ignoredPatterns = [
  /Content Security Policy/i,
  /google-analytics/i,
  /gtag/i,
];

test.describe('DataMagic Home Page', () => {
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
    await expect(page, 'Page should have correct title').toHaveTitle(/Data|DataMagic|Magic Suite/i);
    
    // 3. Verify no console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no console errors').toHaveLength(0);
  });
});
