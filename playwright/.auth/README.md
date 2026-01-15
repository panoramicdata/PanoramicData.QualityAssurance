# Authentication Setup

This directory stores saved authentication state (cookies, localStorage, sessionStorage) for Magic Suite tests with different user roles.

## Files
- `user.json` - Default authentication (tester's personal Microsoft profile)
- `super-admin.json` - Super admin user authentication state
- `uber-admin.json` - Uber admin user authentication state
- `regular-user.json` - Regular user authentication state

## How It Works
Authentication setup scripts log you in once for each role and save the session state.
Tests then reuse the appropriate authentication state based on the project/role they need.

### Initial Setup

**All authentication setups are now in one place:**
```bash
# Run consolidated setup (all user roles)
npx playwright test setup/auth.setup.ts

# Or run specific role setup
npx playwright test setup/auth.setup.ts --grep "Default User"
npx playwright test setup/auth.setup.ts --grep "Super Admin"
npx playwright test setup/auth.setup.ts --grep "Uber Admin"
npx playwright test setup/auth.setup.ts --grep "Regular User"
```

This will guide you through setting up authentication for each role you need.

## Using Different User Roles in Tests

### Run all tests with default user (your profile)
```bash
npx playwright test
```

### Run tests with specific user role
```bash
# Super admin tests
npx playwright test --project=super-admin

# Uber admin tests  
npx playwright test --project=uber-admin

# Regular user tests
npx playwright test --project=regular-user
```

### Run specific test file with a role
```bash
npx playwright test tests/tenant-management.spec.ts --project=super-admin
npx playwright test tests/user-dashboard.spec.ts --project=regular-user
```

### Run multiple projects (parallel)
```bash
npx playwright test --project=default-chromium --project=super-admin
```

## Refreshing Authentication

Sessions expire periodically. When tests start failing with authentication errors, rerun the setup for that role:

```bash
# Refresh default user
npx playwright test auth.setup

# Refresh super admin
npx playwright test auth.setup.super-admin

# Refresh uber admin
npx playwright test auth.setup.uber-admin

# Refresh regular user
npx playwright test auth.setup.regular-user
```

## Securitall or specific roles
npx playwright test setup/auth.setup.ts

# Refresh specific role
npx playwright test setup/auth.setup.ts --grep "Super Admin"
```bash
# Windows PowerShell
$env:MS_ENV = "test2"
npx playwright test auth.setup.super-admin

# Or set in one command
npx playwright test auth.setup.super-admin --env MS_ENV=test2
```

Available environmensetup/auth.setup.ts --grep "Super Admin"
```

Available environments: alpha, alpha2, alpha3, test, test2, beta, staging, ps, production

---

## 📂 File Organization

```
playwright/
├── setup/                   ← Setup scripts location
│   └── auth.setup.ts       ← All auth setups in one file
├── .auth/                  ← Saved authentication states (this folder)
│   ├── user.json
│   ├── super-admin.json
│   ├── uber-admin.json
│   └── regular-user.json
└── Magic Suite/            ← Test files
    ├── Admin/
    ├── DataMagic/
    └── tests/
```