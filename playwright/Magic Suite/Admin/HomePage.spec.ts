import { test, expect } from '@playwright/test';

/**
 * Admin Home Page Tests
 * Tests the administration console with different user roles
 * 
 * AUTHENTICATION:
 * - Each test MUST be run with its corresponding Playwright project
 * - Regular User test: run with --project=regular-user
 * - Tenant Admin test: run with --project=tenant-admin
 * - Super Admin test: run with --project=super-admin
 * 
 * To set up authentication, run: npx playwright test setup/auth.setup.ts
 * 
 * To run the tests:
 *   npx playwright test --grep "Regular User" --project=regular-user
 *   npx playwright test --grep "Tenant Admin" --project=tenant-admin
 *   npx playwright test --grep "Super Admin" --project=super-admin
 */

// Get environment from environment variable or default to 'test2'
const env = process.env.MS_ENV || 'test2';
const baseUrl = env === 'production' 
  ? 'https://admin.magicsuite.net'
  : `https://admin.${env}.magicsuite.net`;

// Known non-critical errors to ignore (CSP issues with analytics, etc.)
const ignoredPatterns = [
  /Content Security Policy/i,
  /google-analytics/i,
  /gtag/i,
];

test.describe('Admin Home Page - Regular User', () => {
  test('should show admin dashboard with NO Super Admin tab for regular user', async ({ page }, testInfo) => {
    // Skip if not running with the regular-user project
    if (testInfo.project.name !== 'regular-user') {
      test.skip();
    }
    
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

    // Navigate to the Admin app
    const response = await page.goto(baseUrl);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // 1. Verify HTTP response is successful
    expect(response?.status(), 'HTTP response should be successful').toBeLessThan(400);
    
    // 2. Verify page has correct title
    await expect(page, 'Page should have Admin in title').toHaveTitle(/Admin/i);
    
    // 3. Verify welcome message is displayed (flexible - any name)
    await expect(page.locator('text=/Welcome .*/i')).toBeVisible({ 
      timeout: 10000 
    });
    
    // 4. Verify user information is displayed (flexible about values)
    await expect(page.locator('text=/User ID.*:/i')).toBeVisible();
    await expect(page.locator('text=/Name.*:/i').first()).toBeVisible();
    await expect(page.locator('text=/Email.*:/i')).toBeVisible();
    await expect(page.locator('text=/Tenant ID.*:/i')).toBeVisible();
    
    // 5. Verify navigation tabs are present (regular user has admin access in this environment)
    await expect(page.locator('text=DataMagic').first()).toBeVisible();
    await expect(page.locator('text=ReportMagic').first()).toBeVisible();
    await expect(page.locator('text=Access').first()).toBeVisible();
    await expect(page.locator('text=Users').first()).toBeVisible();
    
    // 6. Verify Super Admin tab is NOT present (key difference from super admin)
    await expect(page.locator('text=Super Admin').first()).not.toBeVisible();
    
    // 7. Verify the Admin label is present in sidebar
    await expect(page.locator('text=Admin').first()).toBeVisible();
    
    // 8. Verify no critical console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no critical console errors').toHaveLength(0);
  });
});

test.describe('Admin Home Page - Tenant Admin', () => {
  test('should show admin tabs but NO Super Admin tab for tenant admin', async ({ page }, testInfo) => {
    // Skip if not running with the tenant-admin project
    if (testInfo.project.name !== 'tenant-admin') {
      test.skip();
    }
    
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

    // Navigate to the Admin app
    const response = await page.goto(baseUrl);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // 1. Verify HTTP response is successful
    expect(response?.status(), 'HTTP response should be successful').toBeLessThan(400);
    
    // 2. Verify page has correct title
    await expect(page, 'Page should have Admin in title').toHaveTitle(/Admin/i);
    
    // 3. Verify welcome message for tenant admin is displayed (flexible - any name)
    await expect(page.locator('text=/Welcome .*/i')).toBeVisible({ 
      timeout: 10000 
    });
    
    // 4. Verify user information is displayed (flexible about values)
    await expect(page.locator('text=/User ID.*:/i')).toBeVisible();
    await expect(page.locator('text=/Name.*:/i').first()).toBeVisible();
    await expect(page.locator('text=/Email.*:/i')).toBeVisible();
    await expect(page.locator('text=/Tenant ID.*:/i')).toBeVisible();
    await expect(page.locator('text=/Tenant Admin.*True/i')).toBeVisible();
    
    // 5. Verify navigation tabs are present for tenant admin
    await expect(page.locator('text=DataMagic').first()).toBeVisible();
    await expect(page.locator('text=ReportMagic').first()).toBeVisible();
    await expect(page.locator('text=Access').first()).toBeVisible();
    await expect(page.locator('text=Agent Console').first()).toBeVisible();
    await expect(page.locator('text=API Tokens').first()).toBeVisible();
    await expect(page.locator('text=Audit Logs').first()).toBeVisible();
    await expect(page.locator('text=Badges').first()).toBeVisible();
    await expect(page.locator('text=Branding').first()).toBeVisible();
    await expect(page.locator('text=Certificates').first()).toBeVisible();
    await expect(page.locator('text=Connections').first()).toBeVisible();
    await expect(page.locator('text=Feedback').first()).toBeVisible();
    await expect(page.locator('text=Notifications').first()).toBeVisible();
    await expect(page.locator('text=Subscriptions').first()).toBeVisible();
    await expect(page.locator('text=Users').first()).toBeVisible();
    await expect(page.locator('text=Workflows').first()).toBeVisible();
    
    // 6. Verify Super Admin tab is NOT present for tenant admin
    await expect(page.locator('text=Super Admin').first()).not.toBeVisible();
    
    // 7. Verify no critical console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no critical console errors').toHaveLength(0);
  });
});

test.describe('Admin Home Page - Super Admin', () => {
  test('should show all admin tabs INCLUDING Super Admin tab', async ({ page }, testInfo) => {
    // Skip if not running with the super-admin project
    if (testInfo.project.name !== 'super-admin') {
      test.skip();
    }
    
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

    // Navigate to the Admin app
    const response = await page.goto(baseUrl);
    
    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);
    
    // 1. Verify HTTP response is successful
    expect(response?.status(), 'HTTP response should be successful').toBeLessThan(400);
    
    // 2. Verify page has correct title
    await expect(page, 'Page should have Admin in title').toHaveTitle(/Admin/i);
    
    // 3. Verify welcome message for super admin is displayed (flexible - any name)
    await expect(page.locator('text=/Welcome .*/i')).toBeVisible({ 
      timeout: 10000 
    });
    
    // 4. Verify user information is displayed (flexible about values)
    await expect(page.locator('text=/User ID.*:/i')).toBeVisible();
    await expect(page.locator('text=/Name.*:/i').first()).toBeVisible();
    await expect(page.locator('text=/Email.*:/i')).toBeVisible();
    await expect(page.locator('text=/Tenant ID.*:/i')).toBeVisible();
    await expect(page.locator('text=/Tenant Admin.*True/i')).toBeVisible();
    await expect(page.locator('text=/Super Admin.*True/i')).toBeVisible();
    
    // 5. Verify all navigation tabs are present for super admin
    await expect(page.locator('text=DataMagic').first()).toBeVisible();
    await expect(page.locator('text=ReportMagic').first()).toBeVisible();
    await expect(page.locator('text=Access').first()).toBeVisible();
    await expect(page.locator('text=Agent Console').first()).toBeVisible();
    await expect(page.locator('text=API Tokens').first()).toBeVisible();
    await expect(page.locator('text=Audit Logs').first()).toBeVisible();
    await expect(page.locator('text=Badges').first()).toBeVisible();
    await expect(page.locator('text=Branding').first()).toBeVisible();
    await expect(page.locator('text=Certificates').first()).toBeVisible();
    await expect(page.locator('text=Connections').first()).toBeVisible();
    await expect(page.locator('text=Feedback').first()).toBeVisible();
    await expect(page.locator('text=Notifications').first()).toBeVisible();
    await expect(page.locator('text=Subscriptions').first()).toBeVisible();
    await expect(page.locator('text=Users').first()).toBeVisible();
    await expect(page.locator('text=Workflows').first()).toBeVisible();
    
    // 6. Verify Super Admin tab IS present (this is the key difference)
    await expect(page.locator('text=Super Admin').first()).toBeVisible();
    
    // 7. Verify no critical console errors
    if (consoleErrors.length > 0) {
      console.log('Console errors found:', consoleErrors);
    }
    expect(consoleErrors, 'Page should have no critical console errors').toHaveLength(0);
  });
});
