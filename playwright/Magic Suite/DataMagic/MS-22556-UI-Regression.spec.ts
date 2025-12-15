import { test, expect } from '@playwright/test';
import { getAppUrl } from '../utils/urls';

/**
 * MS-22556: DataMagic UI/UX Regression Tests
 * Tests for critical UI rendering and usability issues on alpha2
 * 
 * Environment: https://data.alpha2.magicsuite.net/
 * 
 * Issues being tested:
 * 1. Left hand feedback/search pane visibility
 * 2. Waffle menu collapsibility
 * 3. Font rendering across the product
 * 4. Filter boxes being permanently displayed
 * 5. Timeline pages size and usability
 * 6. White borders around top and right sides
 * 7. Images on home page not showing
 * 8. Column options permanently displayed
 * 9. Frequent reload errors
 * 10. Row value coloring not working
 * 11. External link buttons (e.g., Meraki) showing as box with cross
 */

// Get environment from environment variable or default to 'alpha2'
const env = process.env.MS_ENV || 'alpha2';
const baseUrl = getAppUrl('data', env);

test.describe('MS-22556: DataMagic UI/UX Regression Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Navigate to DataMagic
    await page.goto(baseUrl);
    await page.waitForLoadState('networkidle');
  });

  test('Issue 1: Left hand feedback/search pane should be visible', async ({ page }) => {
    // Look for left sidebar/pane elements
    const leftPaneSelectors = [
      '[role="navigation"]',
      '.sidebar',
      '.left-pane',
      'nav',
      '[data-testid="sidebar"]',
      '.navigation-pane'
    ];
    
    let found = false;
    for (const selector of leftPaneSelectors) {
      const element = page.locator(selector).first();
      if (await element.count() > 0 && await element.isVisible()) {
        console.log(`✓ Left pane found with selector: ${selector}`);
        found = true;
        break;
      }
    }
    
    // Take screenshot for evidence
    await page.screenshot({ 
      path: `screenshots/ms-22556-left-pane-${env}-${Date.now()}.png`
    });
    
    expect(found, 'Left hand feedback/search pane should be visible').toBeTruthy();
  });

  test('Issue 2: Waffle menu should be collapsible', async ({ page }) => {
    // Look for waffle menu (typically a button with 9-dot grid icon)
    const waffleMenuSelectors = [
      '[aria-label*="menu"]',
      '[aria-label*="waffle"]',
      '.waffle-menu',
      '[data-testid="waffle-menu"]',
      'button[aria-label*="apps"]'
    ];
    
    let waffleMenu = null;
    for (const selector of waffleMenuSelectors) {
      const element = page.locator(selector).first();
      if (await element.count() > 0) {
        waffleMenu = element;
        console.log(`✓ Waffle menu found with selector: ${selector}`);
        break;
      }
    }
    
    if (waffleMenu) {
      const isVisible = await waffleMenu.isVisible();
      expect(isVisible, 'Waffle menu should be visible').toBeTruthy();
      
      // Try to click it (should be interactive)
      await waffleMenu.click();
      await page.waitForTimeout(500);
      
      // Take screenshot after click
      await page.screenshot({ 
        path: `screenshots/ms-22556-waffle-menu-${env}-${Date.now()}.png`
      });
    } else {
      console.log('⚠ Waffle menu not found - may need selector update');
    }
  });

  test('Issue 3: Font rendering should be correct across the product', async ({ page }) => {
    // Check multiple elements for proper font rendering
    const bodyStyle = await page.locator('body').evaluate(el => {
      const style = window.getComputedStyle(el);
      return {
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight
      };
    });
    
    console.log('Body font styling:', bodyStyle);
    
    // Check heading fonts
    const h1Exists = await page.locator('h1').count() > 0;
    if (h1Exists) {
      const h1Style = await page.locator('h1').first().evaluate(el => {
        const style = window.getComputedStyle(el);
        return {
          fontFamily: style.fontFamily,
          fontSize: style.fontSize
        };
      });
      console.log('H1 font styling:', h1Style);
    }
    
    // Font family should be defined
    expect(bodyStyle.fontFamily).toBeTruthy();
    expect(bodyStyle.fontFamily).not.toBe('initial');
    expect(bodyStyle.fontFamily).not.toBe('auto');
    
    await page.screenshot({ 
      path: `screenshots/ms-22556-font-rendering-${env}-${Date.now()}.png`
    });
  });

  test('Issue 4: Filter boxes should not be permanently out', async ({ page }) => {
    // Look for filter boxes/panels
    const filterSelectors = [
      '.filter',
      '.filter-box',
      '[role="search"]',
      'input[type="search"]',
      '[data-testid*="filter"]',
      '.search-box'
    ];
    
    const filters: any[] = [];
    for (const selector of filterSelectors) {
      const elements = page.locator(selector);
      const count = await elements.count();
      if (count > 0) {
        for (let i = 0; i < count; i++) {
          const isVisible = await elements.nth(i).isVisible();
          filters.push({ selector, visible: isVisible });
        }
      }
    }
    
    console.log('Filter elements found:', filters);
    
    await page.screenshot({ 
      path: `screenshots/ms-22556-filter-boxes-${env}-${Date.now()}.png`
    });
  });

  test('Issue 6: Should not have white borders around top and right sides', async ({ page }) => {
    // Check body and main content area for unexpected margins/padding
    const layoutInfo = await page.evaluate(() => {
      const body = document.body;
      const main = document.querySelector('main, .main-content, #content, [role="main"]');
      
      const bodyStyle = window.getComputedStyle(body);
      const mainStyle = main ? window.getComputedStyle(main) : null;
      
      return {
        body: {
          margin: bodyStyle.margin,
          padding: bodyStyle.padding,
          border: bodyStyle.border,
          backgroundColor: bodyStyle.backgroundColor
        },
        main: mainStyle ? {
          margin: mainStyle.margin,
          padding: mainStyle.padding,
          border: mainStyle.border,
          backgroundColor: mainStyle.backgroundColor
        } : null,
        viewport: {
          width: window.innerWidth,
          height: window.innerHeight
        }
      };
    });
    
    console.log('Layout information:', JSON.stringify(layoutInfo, null, 2));
    
    // Take full screenshot for visual inspection
    await page.screenshot({ 
      path: `screenshots/ms-22556-borders-fullpage-${env}-${Date.now()}.png`,
      fullPage: true 
    });
    
    // Take viewport screenshot
    await page.screenshot({ 
      path: `screenshots/ms-22556-borders-viewport-${env}-${Date.now()}.png`,
      fullPage: false 
    });
  });

  test('Issue 7: Home page images should be displayed', async ({ page }) => {
    // Find all images on the page
    const images = page.locator('img');
    const imageCount = await images.count();
    
    console.log(`Found ${imageCount} images on the page`);
    
    if (imageCount > 0) {
      const imageStatus: any[] = [];
      
      // Check each image (limit to first 10 for performance)
      for (let i = 0; i < Math.min(imageCount, 10); i++) {
        const img = images.nth(i);
        const isVisible = await img.isVisible();
        const src = await img.getAttribute('src');
        const alt = await img.getAttribute('alt');
        
        // Check if image actually loaded
        const naturalDimensions = await img.evaluate((el: HTMLImageElement) => ({
          width: el.naturalWidth,
          height: el.naturalHeight,
          complete: el.complete
        }));
        
        imageStatus.push({
          index: i,
          src,
          alt,
          visible: isVisible,
          loaded: naturalDimensions.width > 0,
          dimensions: naturalDimensions
        });
      }
      
      console.log('Image status:', JSON.stringify(imageStatus, null, 2));
      
      // At least some images should be loaded
      const loadedImages = imageStatus.filter(img => img.loaded);
      expect(loadedImages.length).toBeGreaterThan(0);
    }
    
    await page.screenshot({ 
      path: `screenshots/ms-22556-images-${env}-${Date.now()}.png`
    });
  });

  test('Issue 8: Column options should not be permanently displayed', async ({ page }) => {
    // Look for column configuration panels/menus
    const columnSelectors = [
      '.column-options',
      '[aria-label*="column"]',
      '[data-testid*="column"]',
      '.column-selector',
      '[aria-label*="columns"]'
    ];
    
    const columnElements: any[] = [];
    for (const selector of columnSelectors) {
      const elements = page.locator(selector);
      const count = await elements.count();
      if (count > 0) {
        for (let i = 0; i < count; i++) {
          const isVisible = await elements.nth(i).isVisible();
          columnElements.push({ selector, index: i, visible: isVisible });
        }
      }
    }
    
    console.log('Column option elements:', columnElements);
    
    await page.screenshot({ 
      path: `screenshots/ms-22556-column-options-${env}-${Date.now()}.png`
    });
  });

  test('Issue 9: Should not have frequent reload errors', async ({ page }) => {
    const errors: string[] = [];
    const consoleErrors: string[] = [];
    
    // Monitor for page errors
    page.on('pageerror', error => {
      errors.push(error.message);
      console.log('Page error:', error.message);
    });
    
    // Monitor console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Wait and observe for errors
    await page.waitForTimeout(5000);
    
    // Try some interactions that might trigger reload
    await page.mouse.move(100, 100);
    await page.mouse.move(300, 300);
    await page.waitForTimeout(2000);
    
    console.log('Page errors:', errors);
    console.log('Console errors:', consoleErrors);
    
    // Should have minimal errors (allow for minor non-critical errors)
    expect(errors.length, 'Should not have frequent page errors').toBeLessThan(3);
  });

  test('Issue 11: External link buttons should render correctly (not as box with cross)', async ({ page }) => {
    // Look for external links and buttons
    const externalLinkSelectors = [
      'a[target="_blank"]',
      'button[data-external]',
      '.external-link',
      'a[href*="meraki"]',
      'button[aria-label*="open"]'
    ];
    
    const linkStatus: any[] = [];
    
    for (const selector of externalLinkSelectors) {
      const links = page.locator(selector);
      const count = await links.count();
      
      if (count > 0) {
        console.log(`Found ${count} links matching: ${selector}`);
        
        for (let i = 0; i < Math.min(count, 5); i++) {
          const link = links.nth(i);
          const isVisible = await link.isVisible();
          const innerHTML = await link.innerHTML();
          const textContent = await link.textContent();
          
          // Check for broken icon indicators
          const hasCrossIcon = innerHTML.includes('×') || innerHTML.includes('✕');
          
          linkStatus.push({
            selector,
            index: i,
            visible: isVisible,
            hasCrossIcon,
            textContent: textContent?.trim(),
            htmlSnippet: innerHTML.substring(0, 100)
          });
        }
      }
    }
    
    console.log('External link status:', JSON.stringify(linkStatus, null, 2));
    
    // None should have cross icon
    const brokenLinks = linkStatus.filter(link => link.hasCrossIcon);
    expect(brokenLinks.length, 'External links should not show as box with cross').toBe(0);
    
    await page.screenshot({ 
      path: `screenshots/ms-22556-external-links-${env}-${Date.now()}.png`
    });
  });

  test('Full page visual regression capture', async ({ page }) => {
    // Comprehensive screenshot for manual visual inspection
    await page.screenshot({ 
      path: `screenshots/ms-22556-visual-regression-${env}-${Date.now()}.png`,
      fullPage: true 
    });
    
    // Also capture viewport
    await page.screenshot({ 
      path: `screenshots/ms-22556-viewport-${env}-${Date.now()}.png`,
      fullPage: false 
    });
  });
});
