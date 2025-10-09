# Test Plans Directory

This directory contains test plans for the Magic Suite project and related systems.

## Naming Convention

Test plan files should be named using the corresponding JIRA issue key format:

- **Format**: `MS-12345.md`
- **Example**: `MS-21972.md` for JIRA issue MS-21972

## Test Plan Structure

Each test plan should include:

- **Issue Summary**: Brief description from JIRA
- **Test Objectives**: What needs to be tested
- **Prerequisites**: System setup and data requirements
- **Test Steps**: Detailed step-by-step instructions
- **Expected Results**: What should happen for each step
- **Test Data**: Sample data or configurations needed
- **Environment**: Which environment(s) to test on
- **Notes**: Additional considerations or known issues

## Example Template

```markdown
# Test Plan: MS-12345 - Issue Summary

## Issue Details
- **JIRA Issue**: MS-12345
- **Summary**: Brief issue description
- **Priority**: Critical/Major/Minor
- **Assignee**: Developer name
- **Status**: Current JIRA status

## Test Objectives
- Primary objective
- Secondary objectives

## Prerequisites
- System requirements
- Test data setup
- User permissions needed

## Test Steps
1. Step 1
   - Expected Result: What should happen
2. Step 2
   - Expected Result: What should happen

## Test Environment
- [ ] Development
- [ ] Staging  
- [ ] Production

## Test Results
- **Date**: Test execution date
- **Tester**: Name of person executing test
- **Status**: Pass/Fail/Blocked
- **Notes**: Any issues or observations
```

## Management

- Test plans should be created when issues are assigned for testing
- Update test plans as requirements change
- Archive completed test plans but keep for reference
- Link test plans to JIRA issues in comments
