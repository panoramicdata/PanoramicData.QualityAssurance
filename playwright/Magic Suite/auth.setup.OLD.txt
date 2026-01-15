import { test as setup, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import { getLoginUrl } from './utils/urls';

/**
 * Authentication Setup for Magic Suite
 * 
 * This script logs into Magic Suite and saves the authentication state
 * (cookies, localStorage, etc.) to a file that can be reused by all tests.
 * 
 * Run this once manually when you need to refresh login:
 *   npx playwright test auth.setup.ts
 * 
 * The saved state expires when your session expires - rerun when needed.
 */

const authFile = '.auth/user.json';

// Get environment from environment variable or default to 'alpha2'
const env = process.env.MS_ENV || 'alpha2';
const loginUrl = getLoginUrl(env);

setup('authenticate to Magic Suite', async ({ page }) => {
  // Override the default timeout - give 5 minutes for manual login
  setup.setTimeout(300000); // 5 minutes
  
  console.log(`Logging into Magic Suite (${env} environment)...`);
  
  // Go to login page
  await page.goto(loginUrl);
  
  // Wait for navigation to complete
  await page.waitForLoadState('networkidle');
  
  console.log('Current URL:', page.url());
  console.log('\n=================================================================');
  console.log('MANUAL LOGIN REQUIRED');
  console.log('=================================================================');
  console.log('1. Log in manually in the browser window');
  console.log('2. After logging in, you will see a Playwright Inspector window');
  console.log('3. Click the "Resume" button (play icon) in the Inspector');
  console.log('4. Your session will be saved automatically');
  console.log('=================================================================\n');
  
  // Pause execution - browser stays open, user logs in, then clicks Resume in Inspector
  await page.pause();
  
  // When resumed, save the authentication state
  console.log('\nSaving authentication state...');
  const authDir = path.dirname(authFile);
  if (!fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }
  
  await page.context().storageState({ path: authFile });
  
  console.log('\n✅ Authentication state saved successfully!');
  console.log(`   Saved to: ${authFile}`);
  console.log('\nAll tests will now use this logged-in state.');
  console.log('Run this setup again when your session expires.\n');
});
