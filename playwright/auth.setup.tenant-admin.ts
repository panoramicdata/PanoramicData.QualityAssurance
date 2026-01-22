import { test as setup } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Tenant Admin Authentication Setup
 * 
 * This script opens a fresh browser window (no existing login) and waits for you to:
 * 1. Log in manually with Tenant Admin credentials
 * 2. Click "Resume" in the Playwright Inspector
 * 
 * The authentication state will be saved to .auth/tenant-admin.json
 * 
 * Usage: npx playwright test auth.setup.tenant-admin --headed --project=firefox
 */

const env = process.env.MS_ENV || 'test2';
const loginUrl = `https://www.${env}.magicsuite.net`;

setup('authenticate as Tenant Admin', async ({ page }) => {
  setup.setTimeout(300000); // 5 minutes for manual login
  
  const authFile = '.auth/tenant-admin.json';
  
  console.log('\n=================================================================');
  console.log('TENANT ADMIN LOGIN SETUP');
  console.log('=================================================================');
  console.log(`Environment: ${env}`);
  console.log(`Login URL: ${loginUrl}`);
  console.log('');
  console.log('⚠️  IMPORTANT: Log in with TENANT ADMIN credentials');
  console.log('');
  console.log('This should be a user with tenant admin permissions.');
  console.log('After logging in successfully, click "Resume" in Playwright Inspector');
  console.log('=================================================================\n');
  
  // Go to Magic Suite home page
  await page.goto(loginUrl);
  
  // Wait for initial page load
  await page.waitForLoadState('networkidle');
  
  console.log('🔐 Please log in manually with Tenant Admin account');
  console.log('📌 After logging in successfully, click "Resume" in the Playwright Inspector\n');
  
  // Pause for manual login - user clicks Resume when done
  await page.pause();
  
  // After login completes, verify we're on a Magic Suite page
  await page.waitForLoadState('networkidle');
  const finalUrl = page.url();
  
  if (!finalUrl.includes('magicsuite.net')) {
    throw new Error(`Login failed - not on magicsuite.net (current URL: ${finalUrl})`);
  }
  
  // Ensure the .auth directory exists
  const authDir = path.dirname(authFile);
  if (!fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }
  
  // Save the authenticated state
  await page.context().storageState({ path: authFile });
  
  console.log('\n=================================================================');
  console.log('✅ Tenant Admin authentication state saved successfully!');
  console.log(`   Saved to: ${authFile}`);
  console.log('\nTests using this authentication will load from this file.');
  console.log('\nRun this setup again when your session expires.');
  console.log('=================================================================\n');
});
