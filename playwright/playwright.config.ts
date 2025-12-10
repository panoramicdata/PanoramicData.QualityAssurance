import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Magic Suite regression tests.
 * 
 * Test Strategy:
 * - Smoke tests (HomePage.spec.ts): Run on ALL browsers for cross-browser validation
 * - Feature tests: Run on Chromium only for speed (use @chromium-only tag or place in chromium/ subfolder)
 * 
 * To run specific browser sets:
 *   npm test                          # All browsers, smoke tests only
 *   npm run test:chromium             # Chromium only (fast)
 *   npm run test:all                  # All tests, all browsers
 * 
 * See https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './Magic Suite',
  
  /* Run tests in files in parallel */
  fullyParallel: true,
  
  /* Fail the build on CI if you accidentally left test.only in the source code */
  forbidOnly: !!process.env.CI,
  
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  
  /* Opt out of parallel tests on CI */
  workers: process.env.CI ? 1 : undefined,
  
  /* Reporter to use */
  reporter: 'html',
  
  /* Shared settings for all the projects below */
  use: {
    /* Collect trace when retrying the failed test */
    trace: 'on-first-retry',
    
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Video recording */
    video: 'retain-on-failure',
  },

  /**
   * Browser Projects Configuration
   * 
   * All browsers are enabled. Use test file naming or grep to control which browsers run:
   * - HomePage.spec.ts files: Run on all browsers (cross-browser smoke tests)
   * - Other .spec.ts files: Use --project=chromium for speed during development
   * 
   * Install browsers: npx playwright install
   */
  projects: [
    /* Desktop Browsers */
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },

    /* Mobile Viewports */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },

    /* Branded Browsers (use installed browser, not Playwright's) */
    {
      name: 'Microsoft Edge',
      use: { ...devices['Desktop Edge'], channel: 'msedge' },
    },
    // Uncomment if Google Chrome is installed and you want to test it separately from Chromium
    // {
    //   name: 'Google Chrome',
    //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
    // },
  ],
  
  /* Global timeout for each test */
  timeout: 30000,
  
  /* Expect timeout */
  expect: {
    timeout: 5000,
  },
});
