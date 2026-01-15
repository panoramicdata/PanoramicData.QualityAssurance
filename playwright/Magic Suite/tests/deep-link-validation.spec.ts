import { test, expect } from '@playwright/test';
import { MagicSuiteUrls, getAllUrlsForEnvironment, validateUrl } from '../utils/magic-suite-urls';

/**
 * Deep Link Regression Tests
 * 
 * Validates that all Magic Suite deep links are accessible and return valid responses.
 * This test suite checks every major URL across all products to ensure they work correctly.
 * 
 * Run with:
 *   npx playwright test deep-link-validation.spec.ts
 *   npx playwright test deep-link-validation.spec.ts --project=super-admin
 */

// Get environment from environment variable or default to 'alpha2'
const env = (process.env.MS_ENV || 'alpha2') as any;

test.describe('Magic Suite Deep Link Validation', () => {
  
  test.describe('DataMagic URLs', () => {
    test('should load DataMagic home page', async ({ page }) => {
      const url = MagicSuiteUrls.data.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
      await expect(page).not.toHaveURL(/login/);
    });

    test('should load Networks page', async ({ page }) => {
      const url = MagicSuiteUrls.data.networks(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Devices page', async ({ page }) => {
      const url = MagicSuiteUrls.data.devices(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Collectors page', async ({ page }) => {
      const url = MagicSuiteUrls.data.collectors(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Data Sources page', async ({ page }) => {
      const url = MagicSuiteUrls.data.datasources(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Settings page', async ({ page }) => {
      const url = MagicSuiteUrls.data.settings(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('ReportMagic URLs', () => {
    test('should load ReportMagic home page', async ({ page }) => {
      const url = MagicSuiteUrls.report.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Report Studio', async ({ page }) => {
      const url = MagicSuiteUrls.report.studio(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Reports list', async ({ page }) => {
      const url = MagicSuiteUrls.report.reports(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Schedules page', async ({ page }) => {
      const url = MagicSuiteUrls.report.schedules(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Report History', async ({ page }) => {
      const url = MagicSuiteUrls.report.history(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('AlertMagic URLs', () => {
    test('should load AlertMagic home page', async ({ page }) => {
      const url = MagicSuiteUrls.alert.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Alerts page', async ({ page }) => {
      const url = MagicSuiteUrls.alert.alerts(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Incidents page', async ({ page }) => {
      const url = MagicSuiteUrls.alert.incidents(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Alert Rules page', async ({ page }) => {
      const url = MagicSuiteUrls.alert.rules(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Alert Channels page', async ({ page }) => {
      const url = MagicSuiteUrls.alert.channels(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('Admin Portal URLs', { tag: '@super-admin' }, () => {
    // These tests require super admin permissions
    test('should load Admin home page', async ({ page }) => {
      const url = MagicSuiteUrls.admin.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Tenants page', async ({ page }) => {
      const url = MagicSuiteUrls.admin.tenants(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Users page', async ({ page }) => {
      const url = MagicSuiteUrls.admin.users(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Roles page', async ({ page }) => {
      const url = MagicSuiteUrls.admin.roles(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('Connect Portal URLs', () => {
    test('should load Connect home page', async ({ page }) => {
      const url = MagicSuiteUrls.connect.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Connectors page', async ({ page }) => {
      const url = MagicSuiteUrls.connect.connectors(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Integrations page', async ({ page }) => {
      const url = MagicSuiteUrls.connect.integrations(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('Documentation URLs', () => {
    test('should load Docs home page', async ({ page }) => {
      const url = MagicSuiteUrls.docs.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load ReportMagic Macros documentation', async ({ page }) => {
      const url = MagicSuiteUrls.docs.reportMagicMacros(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load API documentation', async ({ page }) => {
      const url = MagicSuiteUrls.docs.api(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('Main Portal URLs', () => {
    test('should load Main portal home page', async ({ page }) => {
      const url = MagicSuiteUrls.www.home(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load Dashboard', async ({ page }) => {
      const url = MagicSuiteUrls.www.dashboard(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });

    test('should load User Profile', async ({ page }) => {
      const url = MagicSuiteUrls.www.profile(env);
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });

  test.describe('Special URLs', () => {
    test('should load NCalc 101', async ({ page }) => {
      const url = MagicSuiteUrls.special.ncalc101();
      const response = await page.goto(url);
      expect(response?.status()).toBeLessThan(400);
    });
  });
});

/**
 * Comprehensive URL Check
 * Tests all URLs at once for quick validation
 */
test.describe('Comprehensive URL Accessibility Check', () => {
  test('all major URLs should be accessible', async ({ page }) => {
    const allUrls = getAllUrlsForEnvironment(env);
    const results: Array<{ name: string; url: string; ok: boolean; status: number }> = [];
    
    console.log(`\n📋 Checking ${Object.keys(allUrls).length} URLs for environment: ${env}\n`);
    
    for (const [name, url] of Object.entries(allUrls)) {
      try {
        const response = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 10000 });
        const ok = response ? response.status() < 400 : false;
        const status = response?.status() || 0;
        
        results.push({ name, url, ok, status });
        
        const icon = ok ? '✅' : '❌';
        console.log(`${icon} ${name.padEnd(30)} ${status} ${url}`);
        
      } catch (error) {
        results.push({ name, url, ok: false, status: 0 });
        console.log(`❌ ${name.padEnd(30)} ERROR ${url}`);
      }
    }
    
    const failedUrls = results.filter(r => !r.ok);
    
    console.log(`\n📊 Results: ${results.length - failedUrls.length}/${results.length} URLs accessible\n`);
    
    if (failedUrls.length > 0) {
      console.log('❌ Failed URLs:');
      failedUrls.forEach(f => console.log(`   - ${f.name}: ${f.url} (status: ${f.status})`));
      console.log('');
    }
    
    // Expect at least 90% of URLs to be accessible
    const successRate = (results.length - failedUrls.length) / results.length;
    expect(successRate).toBeGreaterThanOrEqual(0.9);
  });
});
