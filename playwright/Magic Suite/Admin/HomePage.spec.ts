import { test, expect } from '@playwright/test';
import * as path from 'path';

// Auth file paths (relative to playwright root)
const authDir = path.join(__dirname, '..', '..', '.auth');
const regularUserAuth = path.join(authDir, 'regular-user.json');
const tenantAdminAuth = path.join(authDir, 'tenant-admin.json');
const superAdminAuth = path.join(authDir, 'super-admin.json');

/**
 * Admin Home Page Tests
 * Tests the administration console with different user roles
 * 
 * AUTHENTICATION:
 * Each test suite uses test.use() to specify its own authentication state,
 * so you can run all tests with any project (e.g., default-chromium).
 * 
 * Prerequisites: Run auth setup first to create the auth state files:
 *   npx playwright test setup/auth.setup.ts
 * 
 * To run all Admin tests:
 *   npx playwright test "Magic Suite/Admin/HomePage.spec.ts"
 * 
 * To run specific role tests:
 *   npx playwright test --grep "Regular User"
 *   npx playwright test --grep "Tenant Admin"
 *   npx playwright test --grep "Super Admin"
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

// Check if auth files exist
const fs = require('fs');
const regularUserAuthExists = fs.existsSync(regularUserAuth);
const tenantAdminAuthExists = fs.existsSync(tenantAdminAuth);
const superAdminAuthExists = fs.existsSync(superAdminAuth);

// These tests manage their own authentication via browser.newContext()
// Only run with the 'chromium' project to avoid running 5x across all projects
test.describe('Admin Home Page - Regular User', () => {
  // Skip if not running with chromium project (avoids duplicate runs)
  test.beforeEach(async ({}, testInfo) => {
    if (testInfo.project.name !== 'chromium') {
      test.skip();
    }
  });
  
  // Skip this test suite if regular-user auth file doesn't exist
  test.skip(!regularUserAuthExists, 'Regular user auth not configured - run auth setup first');
  
  test('should show admin dashboard with NO Super Admin tab for regular user', async ({ browser }, testInfo) => {
    // Create a NEW browser context with the regular-user auth - this ensures we don't inherit any other credentials
    const context = await browser.newContext({ storageState: regularUserAuth });
    const page = await context.newPage();
    
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
    
    // Clean up the context we created
    await context.close();
  });
});

test.describe('Admin Home Page - Tenant Admin', () => {
  // Skip if not running with chromium project (avoids duplicate runs)
  test.beforeEach(async ({}, testInfo) => {
    if (testInfo.project.name !== 'chromium') {
      test.skip();
    }
  });
  
  // Skip this test suite if tenant-admin auth file doesn't exist
  test.skip(!tenantAdminAuthExists, 'Tenant admin auth not configured - run auth setup first');
  
  test('should show admin tabs but NO Super Admin tab for tenant admin', async ({ browser }, testInfo) => {
    // Create a NEW browser context with the tenant-admin auth
    const context = await browser.newContext({ storageState: tenantAdminAuth });
    const page = await context.newPage();
    
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
    
    // Clean up the context we created
    await context.close();
  });
});

test.describe('Admin Home Page - Super Admin', () => {
  // Skip if not running with chromium project (avoids duplicate runs)
  test.beforeEach(async ({}, testInfo) => {
    if (testInfo.project.name !== 'chromium') {
      test.skip();
    }
  });
  
  // Skip this test suite if super-admin auth file doesn't exist
  test.skip(!superAdminAuthExists, 'Super admin auth not configured - run auth setup first');
  
  test('should show all admin tabs INCLUDING Super Admin tab', async ({ browser }, testInfo) => {
    // Create a NEW browser context with the super-admin auth
    const context = await browser.newContext({ storageState: superAdminAuth });
    const page = await context.newPage();
    
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
    
    // Clean up the context we created
    await context.close();
  });
});
