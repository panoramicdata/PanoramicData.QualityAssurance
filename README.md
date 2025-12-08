# MagicSuite CLI QA Tools

A collection of PowerShell scripts and tools for testing the MagicSuite CLI, creating JIRA bug reports, and automating quality assurance workflows.

---

## 🚀 Quick Start

1. **Clone or copy this folder** to your local machine
2. **Follow setup instructions**: See [SETUP-INSTRUCTIONS.md](SETUP-INSTRUCTIONS.md)
3. **Run smoke test**: `.\smoke-test.ps1` to verify everything works
4. **Read testing ideas**: Check [Testing-Ideas.md](Testing-Ideas.md) for strategies

---

## 📋 What's Included

### Testing Tools
- **Smoke Tests** - Quick validation of core functionality
- **Regression Tests** - Systematic testing of all entity types
- **Performance Tests** - Measure execution times
- **Error Handling Tests** - Validate edge cases
- **Output Validation** - Verify JSON/Table formats
- **Comparative Testing** - Before/after update comparisons
- **Coverage Tracking** - Monitor what's been tested

### JIRA Integration
- **Automated Bug Creation** - Create tickets from test failures
- **Credential Management** - Secure credential storage
- **Batch Operations** - Update multiple tickets at once

### Documentation
- **Setup Instructions** - How to configure on your machine
- **Testing Strategies** - 10 different testing approaches
- **CLI Reference** - Complete command documentation

---

## 🔧 Requirements

- **MagicSuite CLI** (v3.28.258 or later)
- **PowerShell** 5.1 or later
- **JIRA Account** with MS project access
- **Windows** (for Credential Manager integration)

---

## 📖 Documentation

- **[SETUP-INSTRUCTIONS.md](SETUP-INSTRUCTIONS.md)** - First-time setup guide
- **[Testing-Ideas.md](Testing-Ideas.md)** - Comprehensive testing strategies
- **[.github/copilot-instructions.md](.github/copilot-instructions.md)** - CLI reference and JIRA details

---

## 🔒 Security

**Important**: This repository contains tools that interact with JIRA and MagicSuite APIs.

- **Never commit credentials** to version control
- Use **Windows Credential Manager** for secure storage
- Keep `.env` files in `.gitignore`
- Use **JIRA API tokens** instead of passwords
- Each user must configure their own credentials

See [SETUP-INSTRUCTIONS.md](SETUP-INSTRUCTIONS.md) for secure credential management.

---

## 🎯 Common Tasks

### Run Quick Validation
```powershell
.\smoke-test.ps1
```

### Test All Entity Types
```powershell
.\regression-test.ps1
```

### Create a Bug Report
```powershell
# Edit create-jira-bug.ps1 with bug details, then run:
.\create-jira-bug.ps1
```

### Check Test Coverage
```powershell
.\test-coverage.ps1
```

### Compare Before/After Update
```powershell
.\compare-versions.ps1
```

---

## 🐛 Known Issues

See JIRA project MS for active bug reports:
- MS-22521: NullReferenceException on many entity types
- MS-22522: Malformed markup exception (Spectre.Console)
- MS-22523: Profile list shows "?" instead of checkmark
- MS-22558: NuGet package missing DotnetToolSettings.xml

---

## 🤝 Contributing

To add new tests or improve existing ones:

1. **Don't hardcode credentials** - Use environment variables
2. **Follow naming conventions** - `test-*.ps1` for tests
3. **Document your changes** - Update README if needed
4. **Test your scripts** - Verify they work for others
5. **Share with the team** - Submit improvements

---

## 📝 Version History

- **v1.0** (2025-12-08) - Initial release
  - Core testing scripts
  - JIRA integration
  - Documentation

---

## 👥 Team

Developed for MagicSuite QA workflows.

Questions? Check the documentation or ask the team!

---

## 📄 License

Internal tool for PanoramicData team use.
