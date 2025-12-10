import { test, expect } from '@playwright/test';

/**
 * AlertMagic Home Page Tests
 * Tests the alerting and notification system
 */

// Get environment from environment variable or default to 'alpha'
const env = process.env.MS_ENV || 'alpha';
const baseUrl = env === 'production' 
  ? 'https://alert.magicsuite.net'
  : `https://alert.${env}.magicsuite.net`;

test.describe('AlertMagic Home Page', () => {
  test('should load without console errors', async ({ page }) => {
    const consoleErrors: string[] = [];
    
    // Collect console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
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
    await expect(page).toHaveTitle(/Alert|AlertMagic|Magic Suite/i);
  });
});
