import { defineConfig, devices } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

// Configure Playwright output directory (videos, traces, reports)
// Preferred: `MS_VIDEO_DIR` environment variable (user-provided)
// Secondary: attempt to detect OneDrive (Panoramic* folders)
// Important: do NOT store videos inside the repository. If no external storage
// is available, videos will be disabled and the user will be warned.
const oneDriveRoot = process.env.MS_VIDEO_DIR || process.env.OneDrive || process.env.OneDriveCommercial || process.env.OneDriveConsumer;

function tryCreateDir(p: string): boolean {
  try {
    if (!p) return false;
    if (!path.isAbsolute(p)) p = path.resolve(p);
    if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
    return fs.existsSync(p);
  } catch (e) {
    return false;
  }
}

let absoluteOutputDir: string | undefined;
if (process.env.MS_VIDEO_DIR) {
  if (tryCreateDir(process.env.MS_VIDEO_DIR)) {
    absoluteOutputDir = path.resolve(process.env.MS_VIDEO_DIR);
  }
}

// If MS_VIDEO_DIR not set, try to pick a sensible OneDrive path under detected OneDrive roots
if (!absoluteOutputDir && (process.env.OneDrive || process.env.OneDriveCommercial || process.env.OneDriveConsumer)) {
  const roots = [process.env.OneDriveCommercial, process.env.OneDrive, process.env.OneDriveConsumer].filter(Boolean) as string[];
  for (const r of roots) {
    // prefer folders named Panoramic Data* otherwise use a standard candidate
    const candidate = path.join(r!, 'Panoramic Data', 'QA', 'playwright tests');
    if (tryCreateDir(candidate)) { absoluteOutputDir = path.resolve(candidate); break; }
  }
}

// If we still don't have an external folder, disable video recording and avoid repo storage
let videoEnabled = true;
if (!absoluteOutputDir) {
  // Use system temp for non-video artifacts to avoid writing into the repo
  absoluteOutputDir = path.join(os.tmpdir(), 'playwright-test-results');
  tryCreateDir(absoluteOutputDir);
  // But do not record videos if no external persistent storage selected
  videoEnabled = false;
  console.warn('\nWARNING: No external Playwright output directory found.');
  console.warn('Videos will be DISABLED to avoid storing large files inside the repository.');
  console.warn('To enable video recording, set the environment variable MS_VIDEO_DIR to a folder (OneDrive recommended) or run the repository setup to configure it.\n');
}

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
  testDir: './',
  
  /* Ignore old setup files and examples from test discovery */
  testIgnore: [
    '**/Magic Suite/**/auth.setup*.spec.ts',  // Old auth setup files in Magic Suite folder
    '**/example.*.spec.ts',    // Example files
  ],
  
  /* Output directory for test results including videos */
  outputDir: absoluteOutputDir,
  
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
    /* Show browser window during tests - headless false means browser is visible
     * When --headed flag is used, it will override and ensure browser shows
     */
    headless: false,
    
    /* Collect trace when retrying the failed test */
    trace: 'on-first-retry',
    
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
    
    /* Video recording - enabled only when an external MS_VIDEO_DIR was configured
     * Options: 'off', 'on', 'retain-on-failure', 'on-first-retry'
     */
    video: {
      mode: videoEnabled ? 'on' : 'off',
      size: { width: 1920, height: 1080 },
    },
    
    /* Viewport size for higher resolution */
    viewport: { width: 1920, height: 1080 },
    
    /* Reuse authentication state from auth.setup.spec.ts
     * This loads saved cookies and storage so tests don't need to log in
     * Run 'npx playwright test auth.setup' to create/refresh the auth state
     * Only loads if the file exists (allows auth.setup to run without it)
     * Note: storageState is undefined here and set per-project to allow auth setup to run
     */
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
   * - 'tenant-admin': Tenant admin user permissions  
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
    
    /* Tenant Admin role - for tests requiring tenant admin permissions */
    {
      name: 'tenant-admin',
      use: { 
        ...devices['Desktop Chrome'],
        storageState: fs.existsSync('.auth/tenant-admin.json') ? '.auth/tenant-admin.json' : undefined,
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
