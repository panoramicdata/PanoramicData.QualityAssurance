/**
 * Authentication utilities for Magic Suite Playwright tests
 * 
 * Provides automatic Microsoft login functionality that works across all Magic Suite apps.
 * Falls back to manual login if credentials are not available.
 */

/**
 * Automatic login helper for Microsoft authentication
 * 
 * @param page - The Playwright page object
 * @param appName - Optional name of the app for logging purposes (e.g., "NCalc 101", "Data Explorer")
 * @returns true if login succeeded, false if manual login is needed
 * 
 * Usage:
 *   const loggedIn = await performAutoLogin(page, "NCalc 101");
 *   if (!loggedIn) {
 *     await page.pause(); // Manual login
 *   }
 * 
 * Environment variables:
 *   MS_TEST_USER or MS_USERNAME - Email/username for Microsoft login
 *   MS_TEST_PASSWORD or MS_PASSWORD - Password for Microsoft login
 */
export async function performAutoLogin(page: any, appName?: string): Promise<boolean> {
  // Get credentials from environment variables
  const username = process.env.MS_TEST_USER || process.env.MS_USERNAME;
  const password = process.env.MS_TEST_PASSWORD || process.env.MS_PASSWORD;
  
  if (!username || !password) {
    console.log('⚠️  No credentials found in environment variables.');
    console.log('   Set MS_TEST_USER and MS_TEST_PASSWORD to enable automatic login.');
    return false;
  }
  
  try {
    const appDescription = appName ? ` for ${appName}` : '';
    console.log(`🔐 Attempting automatic login${appDescription}: ${username}`);
    
    // Wait for Microsoft login page to load
    await page.waitForTimeout(2000);
    
    // Enter email
    const emailInput = page.locator('input[type="email"]');
    if (await emailInput.count() > 0) {
      await emailInput.fill(username);
      await page.keyboard.press('Enter');
      console.log('✓ Entered email');
      await page.waitForTimeout(2000);
    }
    
    // Enter password
    const passwordInput = page.locator('input[type="password"]');
    if (await passwordInput.count() > 0) {
      await passwordInput.fill(password);
      await page.keyboard.press('Enter');
      console.log('✓ Entered password');
      await page.waitForTimeout(3000);
    }
    
    // Handle "Stay signed in?" prompt
    const staySignedInButton = page.locator('input[type="submit"][value="Yes"]');
    if (await staySignedInButton.count() > 0) {
      await staySignedInButton.click();
      console.log('✓ Clicked Stay signed in');
      await page.waitForTimeout(2000);
    }
    
    // Wait for navigation to complete
    await page.waitForLoadState('networkidle');
    
    console.log('✅ Automatic login completed');
    return true;
  } catch (e: any) {
    console.log(`✗ Automatic login failed: ${e.message}`);
    return false;
  }
}

/**
 * Check if the page requires login
 * 
 * @param page - The Playwright page object
 * @param expectedDomain - The expected domain substring (e.g., 'ncalc101', 'data', 'alert')
 * @returns true if login is needed
 */
export async function needsLogin(page: any, expectedDomain?: string): Promise<boolean> {
  const currentUrl = page.url();
  const pageText = (await page.textContent('body') || '').toLowerCase();
  
  // Check for Microsoft login page indicators
  const onLoginPage = currentUrl.includes('login') || 
                      currentUrl.includes('microsoftonline') ||
                      currentUrl.includes('identity') ||
                      currentUrl.includes('auth') ||
                      pageText.includes('sign in') ||
                      pageText.includes('pick an account') ||
                      pageText.includes('enter your password') ||
                      pageText.includes('microsoft') && pageText.includes('password');
  
  if (onLoginPage) {
    console.log(`🔐 Login required - detected login page: ${currentUrl}`);
    return true;
  }
  
  // If expectedDomain is provided, check if we're on the right app
  if (expectedDomain && !currentUrl.includes(expectedDomain)) {
    console.log(`🔐 Login required - not on expected domain (${expectedDomain}): ${currentUrl}`);
    return true;
  }
  
  // Additional check: look for common login form elements
  const hasLoginForm = await page.locator('input[type="email"], input[type="password"], button:has-text("Sign in")').count() > 0;
  if (hasLoginForm && !currentUrl.includes(expectedDomain || '')) {
    console.log(`🔐 Login required - detected login form elements`);
    return true;
  }
  
  return false;
}

/**
 * Handle authentication for Magic Suite apps
 * Tries automatic login first, falls back to manual login if needed
 * 
 * @param page - The Playwright page object
 * @param baseUrl - The base URL of the app
 * @param appName - Name of the app for logging
 * @param expectedDomain - Expected domain substring to verify we're on the right app
 * 
 * Usage in beforeEach:
 *   await handleAuthentication(page, baseUrl, "NCalc 101", "ncalc101");
 */
export async function handleAuthentication(
  page: any,
  baseUrl: string,
  appName: string,
  expectedDomain: string
): Promise<void> {
  const loginRequired = await needsLogin(page, expectedDomain);
  
  if (loginRequired) {
    console.log('\n=================================================================');
    console.log(`LOGIN REQUIRED FOR ${appName.toUpperCase()}`);
    console.log('=================================================================');
    console.log(`Target: ${baseUrl}`);
    console.log('=================================================================\n');
    
    // Try automatic login first
    const autoLoginSucceeded = await performAutoLogin(page, appName);
    
    if (!autoLoginSucceeded) {
      // Fall back to manual login
      console.log('\n=================================================================');
      console.log('MANUAL LOGIN REQUIRED');
      console.log('=================================================================');
      console.log('1. Log in manually in the browser window');
      console.log('2. Complete the Microsoft authentication if prompted');
      console.log('3. After logging in successfully, click "Resume" in the Playwright Inspector');
      console.log('4. Your session will be saved automatically');
      console.log('=================================================================\n');
      
      // Pause for manual login
      await page.pause();
      
      // After manual login, save the authentication state
      try {
        const authFile = '.auth/user.json';
        await page.context().storageState({ path: authFile });
        console.log(`\n✅ Authentication saved to ${authFile}`);
        console.log('   Future test runs will use this saved authentication.\n');
      } catch (e: any) {
        console.log(`\n⚠️ Could not save authentication: ${e.message}\n`);
      }
    }
    
    // After login, ensure we're on the right page
    if (!page.url().includes(expectedDomain)) {
      await page.goto(baseUrl);
      await page.waitForLoadState('networkidle');
    }
  }
}
