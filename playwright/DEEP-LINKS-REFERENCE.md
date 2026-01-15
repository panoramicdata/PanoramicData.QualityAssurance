# Magic Suite Deep Link URLs - Quick Reference

Complete list of deep link URLs for all Magic Suite products. Use this for manual testing or copy into Playwright tests.

## 🔗 Quick Links by Product

### DataMagic (Data Source Management)

**Base URLs:**
- Alpha: `https://data.alpha.magicsuite.net`
- Alpha2: `https://data.alpha2.magicsuite.net`
- Test2: `https://data.test2.magicsuite.net`
- Production: `https://data.magicsuite.net`

**Main Pages:**
```
/                        # Home
/networks                # Network devices list
/devices                 # All devices
/collectors              # Data collectors
/datasources             # Data sources
/dataCollectorGroups     # Collector groups
/deviceGroups            # Device groups
/settings                # Settings
/settings/tokens         # API tokens
```

**Dynamic URLs (replace {id} with actual ID):**
```
/networks/{id}           # Specific network
/devices/{id}            # Device details
/devices/{id}/properties # Device properties
/devices/{id}/alerts     # Device alerts
/collectors/{id}         # Collector details
```

---

### ReportMagic (Reporting & Scheduling)

**Base URLs:**
- Alpha: `https://report.alpha.magicsuite.net`
- Alpha2: `https://report.alpha2.magicsuite.net`
- Test2: `https://report.test2.magicsuite.net`
- Production: `https://report.magicsuite.net`

**Main Pages:**
```
/                        # Home
/studio                  # Report Studio
/studio/new              # New report in Studio
/reports                 # Reports list
/schedules               # Schedules list
/schedules/new           # Create new schedule
/history                 # Report history
/outputs                 # Report outputs
/templates               # Report templates
/macros                  # Available macros
/settings                # Settings
/settings/connections    # Data connections
```

**Dynamic URLs:**
```
/studio/{id}             # Edit report in Studio
/reports/{id}            # View report
/reports/{id}/edit       # Edit report
/reports/{id}/run        # Run report
/schedules/{id}          # View schedule
/schedules/{id}/edit     # Edit schedule
```

---

### AlertMagic (Alerts & Incidents)

**Base URLs:**
- Alpha: `https://alert.alpha.magicsuite.net`
- Alpha2: `https://alert.alpha2.magicsuite.net`
- Test2: `https://alert.test2.magicsuite.net`
- Production: `https://alert.magicsuite.net`

**Main Pages:**
```
/                        # Home
/alerts                  # Active alerts
/incidents               # Incidents list
/rules                   # Alert rules
/rules/new               # Create new rule
/channels                # Alert channels
/channels/new            # Create new channel
/escalations             # Escalation chains
/escalations/new         # Create new escalation
/settings                # Settings
```

**Dynamic URLs:**
```
/incidents/{id}          # Incident details
/rules/{id}              # Alert rule details
/rules/{id}/edit         # Edit alert rule
/channels/{id}           # Channel details
/escalations/{id}        # Escalation details
```

---

### Admin Portal (System Administration)

**Base URLs:**
- Alpha: `https://admin.alpha.magicsuite.net`
- Alpha2: `https://admin.alpha2.magicsuite.net`
- Test2: `https://admin.test2.magicsuite.net`
- Production: `https://admin.magicsuite.net`

**Main Pages:**
```
/                        # Home
/tenants                 # Tenants list (Super Admin)
/tenants/new             # Create new tenant
/users                   # Users list
/users/new               # Create new user
/roles                   # Roles list (RBAC)
/roles/new               # Create new role
/permissions             # Permissions management
/api-tokens              # System API tokens
/audit                   # Audit logs
/settings                # System settings
/system/health           # System health status
```

**Dynamic URLs:**
```
/tenants/{id}            # Tenant details
/tenants/{id}/edit       # Edit tenant
/users/{id}              # User details
/users/{id}/edit         # Edit user
/roles/{id}              # Role details
```

---

### Connect Portal (Integrations)

**Base URLs:**
- Alpha: `https://connect.alpha.magicsuite.net`
- Alpha2: `https://connect.alpha2.magicsuite.net`
- Test2: `https://connect.test2.magicsuite.net`
- Production: `https://connect.magicsuite.net`

**Main Pages:**
```
/                        # Home
/connectors              # Connectors list
/connectors/new          # Create new connector
/integrations            # Integrations list
/integrations/new        # Create new integration
/webhooks                # Webhooks list
/webhooks/new            # Create new webhook
/settings                # Settings
```

**Dynamic URLs:**
```
/connectors/{id}         # Connector details
/integrations/{id}       # Integration details
/webhooks/{id}           # Webhook details
```

---

### Documentation

**Base URLs:**
- Alpha: `https://docs.alpha.magicsuite.net`
- Alpha2: `https://docs.alpha2.magicsuite.net`
- Test2: `https://docs.test2.magicsuite.net`
- Production: `https://docs.magicsuite.net`

**Main Pages:**
```
/                        # Home
/datamagic               # DataMagic docs
/reportmagic             # ReportMagic docs
/reportmagic/macros      # ReportMagic macros reference
/reportmagic/functions   # ReportMagic functions
/reportmagic/examples    # ReportMagic examples
/alertmagic              # AlertMagic docs
/api                     # API overview
/api/reference           # API reference
/getting-started         # Getting started guide
/tutorials               # Tutorials
/release-notes           # Release notes
/changelog               # Changelog
```

---

### Main Portal (www)

**Base URLs:**
- Alpha: `https://www.alpha.magicsuite.net`
- Alpha2: `https://www.alpha2.magicsuite.net`
- Test2: `https://www.test2.magicsuite.net`
- Production: `https://www.magicsuite.net`

**Main Pages:**
```
/                        # Home
/dashboard               # User dashboard
/profile                 # User profile
/profile/edit            # Edit profile
/profile/settings        # Profile settings
/profile/tokens          # Personal API tokens
/account                 # Account management
/account/billing         # Billing
/account/subscription    # Subscription
/products                # Products overview
/feedback                # Submit feedback
/support                 # Support center
/contact                 # Contact us
```

---

### Special URLs

**NCalc 101 (Expression Language Tutorial):**
```
https://ncalc101.magicsuite.net
```

**API Endpoints:**
- Alpha: `https://api.alpha.magicsuite.net`
- Alpha2: `https://api.alpha2.magicsuite.net`
- Test2: `https://api.test2.magicsuite.net`
- Production: `https://api.magicsuite.net`

---

## 📝 Usage in Playwright Tests

### Import the URL utilities:
```typescript
import { MagicSuiteUrls, getMagicSuiteUrl } from './utils/magic-suite-urls';
```

### Use pre-defined URLs:
```typescript
// Navigate to DataMagic networks page
await page.goto(MagicSuiteUrls.data.networks('alpha2'));

// Navigate to specific device
await page.goto(MagicSuiteUrls.data.deviceById(123, 'alpha2'));

// Navigate to ReportMagic Studio
await page.goto(MagicSuiteUrls.report.studio('test2'));
```

### Use helper function:
```typescript
// Generic URL retrieval
const url = getMagicSuiteUrl('data', 'networks', 'alpha2');
await page.goto(url);
```

---

## 🧪 Running Deep Link Tests

**Test all deep links:**
```powershell
npx playwright test deep-link-validation.spec.ts
```

**Test with specific environment:**
```powershell
$env:MS_ENV="test2"; npx playwright test deep-link-validation.spec.ts
```

**Test with super admin (for admin portal links):**
```powershell
npx playwright test deep-link-validation.spec.ts --project=super-admin
```

**Test specific product:**
```powershell
npx playwright test deep-link-validation.spec.ts --grep "DataMagic"
```

---

## ✅ URL Validation Checklist

Use this checklist when adding new features or pages:

- [ ] Add URL to `magic-suite-urls.ts`
- [ ] Add test to `deep-link-validation.spec.ts`
- [ ] Update this reference document
- [ ] Test URL in all environments (alpha, alpha2, test2, production)
- [ ] Verify authentication requirements
- [ ] Check mobile responsiveness (if applicable)
- [ ] Add to regression test suite

---

## 🔄 Environment Quick Switch

**PowerShell:**
```powershell
# Set environment for current session
$env:MS_ENV="alpha"
$env:MS_ENV="alpha2"
$env:MS_ENV="test2"
$env:MS_ENV="production"
```

**In tests:**
```typescript
process.env.MS_ENV = 'alpha2';
```

---

## 📊 URL Status Dashboard

After running comprehensive tests, check `test-results/test-videos.html` for:
- Which URLs passed/failed
- HTTP status codes
- Response times
- Screenshots of failed pages

---

*Last Updated: January 2026*
*Maintained by: QA Team*
