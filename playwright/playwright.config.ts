import { defineConfig, devices } from '@playwright/test';
import * as fs from 'fs';

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
  
  /* Ignore setup files and examples from test discovery */
  testIgnore: [
    '**/auth.setup*.spec.ts',  // Old auth setup files (moved to setup/ folder)
    '**/example.*.spec.ts',    // Example files
  ],
  
  /* Output directory for test results including videos */
  outputDir: 'test-results',
  
  /* Run tests in files in parallel */
  fullyParallel: true,
  
  /* Fail the build on CI if you accidentally left test.only in the source code */
  forbidOnly: !!process.env.CI,
  
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  
  /* Opt out of parallel tests on CI */
  workers: process.env.CI ? 1 : undefined,
  
  /* Reporter to use - includes custom video reporter for easy video access */
  reporter: [
    ['html'],
    ['./video-reporter.js']
  ],
  
  /* Shared settings for all the projects below */
  use: {
    /* Show browser window during tests (set to true for headed mode) */
    headless: false,
    
    /* Collect trace when retrying the failed test */
    trace: 'on-first-retry',
    
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Video recording - ALWAYS records all tests in WebM format
     * Videos are saved to test-results/<test-name>/video.webm
     * Options: 'off', 'on', 'retain-on-failure', 'on-first-retry'
     */
    video: {
      mode: 'on',
      size: { width: 1920, height: 1080 },
    },
    
    /* Viewport size for higher resolution */
    viewport: { width: 1920, height: 1080 },
    
    /* Reuse authentication state from auth.setup.spec.ts
     * This loads saved cookies and storage so tests don't need to log in
     * Run 'npx playwright test auth.setup' to create/refresh the auth state
     * Only loads if the file exists (allows auth.setup to run without it)
     */
    storageState: fs.existsSync('.auth/user.json') ? '.auth/user.json' : undefined,
  },

  /**
   * Browser Projects Configuration
   * 
   * Default: Chromium with default user (tester's personal profile)
   * Additional projects for different user roles when needed.
   * 
   * User Role Projects:
   * - 'default-chromium': Tester's personal Microsoft profile (default)
   * - 'super-admin': Super admin user permissions
   * - 'uber-admin': Uber admin user permissions  
   * - 'regular-user': Standard user permissions
   * 
   * Usage:
   *   npx playwright test                        # Runs with default user
   *   npx playwright test --project=super-admin  # Runs as super admin
   *   npx playwright test tests/admin.spec.ts --project=super-admin
   * 
   * In test files, specify the project/role:
   *   test.describe('Admin features', { tag: '@super-admin' }, () => { ... })
   * 
   * Install browsers: npx playwright install
   */
  projects: [
    /* Default user - tester's personal profile */
    {
      name: 'default-chromium',
      use: { 
        ...devices['Desktop Chrome'],
        storageState: fs.existsSync('.auth/user.json') ? '.auth/user.json' : undefined,
      },
    },
    
    /* Super Admin role - for tests requiring super admin permissions */
    {
      name: 'super-admin',
      use: { 
        ...devices['Desktop Chrome'],
        storageState: fs.existsSync('.auth/super-admin.json') ? '.auth/super-admin.json' : undefined,
      },
    },
    
    /* Uber Admin role - for tests requiring uber admin permissions */
    {
      name: 'uber-admin',
      use: { 
        ...devices['Desktop Chrome'],
        storageState: fs.existsSync('.auth/uber-admin.json') ? '.auth/uber-admin.json' : undefined,
      },
    },
    
    /* Regular User role - for tests requiring standard user permissions */
    {
      name: 'regular-user',
      use: { 
        ...devices['Desktop Chrome'],
        storageState: fs.existsSync('.auth/regular-user.json') ? '.auth/regular-user.json' : undefined,
      },
    },
    
    /* Additional browsers - uncomment to enable */
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
    // {
    //   name: 'Microsoft Edge',
    //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
    // },
  ],
  
  /* Global timeout for each test - set high to allow manual login in auth.setup */
  timeout: 360000, // 6 minutes
  
  /* Expect timeout */
  expect: {
    timeout: 5000,
  },
});
