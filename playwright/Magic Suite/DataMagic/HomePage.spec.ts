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

test.describe('DataMagic Home Page', () => {
  test('should load without console errors', async ({ page }) => {
    const consoleErrors: string[] = [];
    
    // Known non-critical errors to ignore (CSP issues with analytics, etc.)
    const ignoredPatterns = [
      /Content Security Policy/i,
      /google-analytics/i,
      /gtag/i,
    ];
    
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
    
    // Verify the page loaded successfully
    expect(response?.status()).toBeLessThan(400);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');
    
    // Log any console errors for debugging
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    
    // Assert no console errors
    expect(consoleErrors).toHaveLength(0);
  });

  test('should have correct title', async ({ page }) => {
    await page.goto(baseUrl);
    
    // Check that the page has a title (adjust regex as needed)
    await expect(page).toHaveTitle(/Data|DataMagic|Magic Suite/i);
  });
});
