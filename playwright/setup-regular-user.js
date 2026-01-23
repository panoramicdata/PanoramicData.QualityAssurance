// Simple script to set up regular user authentication
// Run with: node setup-regular-user.js

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const authFile = '.auth/regular-user.json';
const loginUrl = 'https://www.test2.magicsuite.net';

async function main() {
  console.log('\n=================================================================');
  console.log('REGULAR USER LOGIN SETUP');
  console.log('=================================================================');
  console.log('This will open ONE browser window.');
  console.log('');
  console.log('⚠️  IMPORTANT: Log in with your REGULAR USER account');
  console.log('   (NOT Amy Bond / your default account)');
  console.log('');
  console.log('After logging in, press ENTER in this terminal to save.');
  console.log('=================================================================\n');

  // Launch browser - NOT headless so you can see it
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  // Navigate to login page
  await page.goto(loginUrl);
  
  console.log('🌐 Browser opened. Please log in with your Regular User account...\n');

  // Wait for user to press Enter
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  await new Promise(resolve => {
    rl.question('Press ENTER after you have logged in successfully: ', () => {
      rl.close();
      resolve();
    });
  });

  // Ensure .auth directory exists
  const authDir = path.dirname(authFile);
  if (!fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }

  // Save the storage state
  await context.storageState({ path: authFile });
  
  console.log('\n✅ Regular user authentication saved to:', authFile);
  console.log('You can now close this terminal and run the tests.\n');

  await browser.close();
}

main().catch(console.error);
