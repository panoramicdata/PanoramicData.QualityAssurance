import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Magic Suite regression tests.
 * 
 * Default: Chromium only (fast development workflow)
 * 
 * To run with other browsers:
 *   npm test                          # Chromium only (default)
 *   npm run test:all-browsers         # All 6 browsers
 *   npm run test:desktop              # Desktop browsers only
 *   npx playwright test --project=firefox  # Specific browser
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
    
    /* Video recording - 'on' records all tests */
    video: {
      mode: 'on',
      size: { width: 1920, height: 1080 },
    },
    
    /* Viewport size for higher resolution */
    viewport: { width: 1920, height: 1080 },
  },

  /**
   * Browser Projects Configuration
   * 
   * Default: Only Chromium runs (fast for development)
   * Use --project flag or npm scripts to run other browsers when needed.
   * 
   * Install browsers: npx playwright install
   */
  projects: [
    /* Default browser - always runs */
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    
    /* Additional browsers - run with --project flag or npm run test:all-browsers */
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
    // {
    //   name: 'Mobile Safari',
    //   use: { ...devices['iPhone 12'] },
    // },
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
  ],
  
  /* Global timeout for each test */
  timeout: 30000,
  
  /* Expect timeout */
  expect: {
    timeout: 5000,
  },
});
