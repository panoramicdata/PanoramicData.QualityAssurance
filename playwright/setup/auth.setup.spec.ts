import { test as setup, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { getLoginUrl } from '../Magic Suite/utils/urls';
import { performAutoLogin } from '../Magic Suite/utils/auth';

/**
 * Consolidated Authentication Setup for Magic Suite
 * 
 * This script manages all authentication setups for different user roles.
 * Run this to configure authentication for any or all user types.
 * 
 * Usage:
 *   # Default user (your personal profile)
 *   npx playwright test setup/auth.setup.ts
 *   
 *   # Specific roles
 *   npx playwright test setup/auth.setup.ts --grep "Super Admin"
 *   npx playwright test setup/auth.setup.ts --grep "Tenant Admin"
 *   npx playwright test setup/auth.setup.ts --grep "Regular User"
 *   
 * The saved states expire when your session expires - rerun when needed.
 */

// Get environment from environment variable or default to 'test2'
const env = process.env.MS_ENV || 'test2';
// Use Magic Suite home app (Www) for login
const loginUrl = `https://www.${env}.magicsuite.net`;

/**
 * Helper function to perform authentication
 */
async function authenticateUser(
  page: any,
  authFile: string,
  userType: string,
  description: string
) {
  // Override the default timeout - give 5 minutes for manual login if needed
  setup.setTimeout(300000); // 5 minutes
  
  console.log('\n=================================================================');
  console.log(`${userType.toUpperCase()} LOGIN SETUP`);
  console.log('=================================================================');
  console.log(`Environment: ${env}`);
  console.log(`Login URL: ${loginUrl}`);
  console.log('');
  console.log(`⚠️  IMPORTANT: Log in with ${userType} credentials`);
  console.log('');
  console.log(description);
  console.log('=================================================================\n');
  
  // Go to login page
  await page.goto(loginUrl);
  
  // Wait for initial page load
  await page.waitForLoadState('networkidle');
  
  console.log(`🔐 Please log in manually with ${userType} account in the browser window`);
  console.log('📌 After logging in successfully, click "Resume" in the Playwright Inspector\n');
  
  // Pause for manual login - user clicks Resume when done
  // This happens AFTER navigation so the page is visible
  await page.pause();
  
  // After login completes (user clicked Resume), verify we're on a Magic Suite page
  await page.waitForLoadState('networkidle');
  const finalUrl = page.url();
  expect(finalUrl).toContain('magicsuite.net');
  
  // Ensure the .auth directory exists
  const authDir = path.dirname(authFile);
  if (!fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }
  
  // Save the authenticated state (cookies, localStorage, sessionStorage)
  await page.context().storageState({ path: authFile });
  
  console.log('\n=================================================================');
  console.log(`✅ ${userType} authentication state saved successfully!`);
  console.log(`   Saved to: ${authFile}`);
  console.log(`\nTests using this authentication will load from this file.`);
  console.log(`\nRun this setup again when your ${userType.toLowerCase()} session expires.`);
  console.log('=================================================================\n');
}

// Default User Authentication (Tester's Personal Profile)
setup('authenticate - Default User', async ({ page }) => {
  const authFile = '.auth/user.json';
  
  await authenticateUser(
    page,
    authFile,
    'Default User (Your Personal Profile)',
    'This is your personal Microsoft profile for everyday testing.\nUsed by default for all tests unless specified otherwise.'
  );
  
  console.log('Usage:');
  console.log('  npx playwright test                           # Uses this authentication');
  console.log('  npx playwright test --project=default-chromium # Explicit default user');
});

// Super Admin Authentication
setup('authenticate - Super Admin', async ({ page }) => {
  const authFile = '.auth/super-admin.json';
  
  await authenticateUser(
    page,
    authFile,
    'Super Admin',
    'This authentication state will be used for tests that require\nsuper admin permissions (e.g., --all-tenants, tenant management)'
  );
  
  console.log('Usage:');
  console.log('  npx playwright test --project=super-admin');
  console.log('  npx playwright test tests/admin-features.spec.ts --project=super-admin');
});

// Tenant Admin Authentication
setup('authenticate - Tenant Admin', async ({ page }) => {
  const authFile = '.auth/tenant-admin.json';
  
  await authenticateUser(
    page,
    authFile,
    'Tenant Admin',
    'This authentication state will be used for tests that require\ntenant admin permissions (tenant-level administration)'
  );
  
  console.log('Usage:');
  console.log('  npx playwright test --project=tenant-admin');
  console.log('  npx playwright test tests/tenant-admin-features.spec.ts --project=tenant-admin');
});

// Regular User Authentication
setup('authenticate - Regular User', async ({ page }) => {
  const authFile = '.auth/regular-user.json';
  
  await authenticateUser(
    page,
    authFile,
    'Regular User',
    'This authentication state will be used for tests that require\nstandard user permissions (no admin privileges)'
  );
  
  console.log('Usage:');
  console.log('  npx playwright test --project=regular-user');
  console.log('  npx playwright test tests/user-features.spec.ts --project=regular-user');
});
