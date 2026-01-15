# Playwright Setup Scripts

This directory contains setup scripts that configure the testing environment and authentication states.

## 📁 Contents

### Authentication Setup
- **auth.setup.ts** - Consolidated authentication setup for all user roles

## 🚀 Running Setup Scripts

### Set up authentication for all user roles:
```powershell
# Run all authentication setups (choose which ones to complete)
npx playwright test setup/auth.setup.ts
```

### Set up specific user role:
```powershell
# Default user (your personal profile)
npx playwright test setup/auth.setup.ts --grep "Default User"

# Super admin
npx playwright test setup/auth.setup.ts --grep "Super Admin"

# Uber admin
npx playwright test setup/auth.setup.ts --grep "Uber Admin"

# Regular user
npx playwright test setup/auth.setup.ts --grep "Regular User"
```

### Change environment before setup:
```powershell
$env:MS_ENV="test2"
npx playwright test setup/auth.setup.ts
```

## 📝 What Gets Created

Authentication states are saved to the `.auth/` directory:
```
.auth/
├── user.json              # Default user (your personal profile)
├── super-admin.json       # Super admin user
├── uber-admin.json        # Uber admin user
└── regular-user.json      # Regular user
```

## 🔄 When to Re-run Setup

Re-run authentication setup when:
- ✅ Sessions expire (typically after several hours/days)
- ✅ You need to switch environments
- ✅ You need to add a new user role
- ✅ Tests start failing with authentication errors

## 📚 Documentation

See the main [.auth/README.md](../.auth/README.md) for more details on using different authentication states in tests.

## 🗂️ Directory Structure

```
playwright/
├── setup/                    ← Setup scripts (this folder)
│   ├── auth.setup.ts        ← Authentication setup
│   └── README.md            ← This file
├── .auth/                   ← Saved authentication states
│   ├── user.json
│   ├── super-admin.json
│   ├── uber-admin.json
│   └── regular-user.json
└── Magic Suite/             ← Test files
    ├── Admin/
    ├── DataMagic/
    ├── ReportMagic/
    └── tests/
```

## ⚠️ Important Notes

- Setup scripts are **not tests** - they're configuration tools
- They require manual interaction (logging in)
- Run with headed browser mode (automatically enabled)
- Each setup can take 1-5 minutes depending on login method
- Authentication states are git-ignored for security

## 🆘 Troubleshooting

**Problem**: Setup hangs at login screen
- **Solution**: Make sure to click "Resume" in the Playwright Inspector after logging in

**Problem**: Authentication state not saved
- **Solution**: Wait for the confirmation message before closing the browser

**Problem**: Can't find specific user credentials
- **Solution**: Check with your team lead for test account credentials

**Problem**: Setup fails with timeout
- **Solution**: The default timeout is 5 minutes. If you need more time, edit the setup script.
