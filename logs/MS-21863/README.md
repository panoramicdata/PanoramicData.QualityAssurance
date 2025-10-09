# MS-21863 Log Collection

## Issue Summary
- **Ticket**: MS-21863 - SharePoint File Copy Regression  
- **Problem**: CAE Portal Agent fails copying files to newly created SharePoint temp folders
- **Error**: "Not found" during copy operation
- **Version Regression**: Working in 3.26.501, failing in 3.27.351
- **Created**: September 24, 2025

## Log Collection Status

### Pending Log Searches
- [ ] SharePoint copy error logs
- [ ] CAE Portal Agent application logs  
- [ ] File system operation logs
- [ ] Version comparison logs (3.26.501 vs 3.27.351)
- [ ] Error pattern analysis

### Search Queries Prepared

#### 1. SharePoint Copy Errors
**Index**: logs-*, application-*
**Query**: SharePoint file copy failures with "not found" errors
**Time Range**: 2025-09-24 onwards

#### 2. CAE Portal Agent Logs
**Index**: cae-*, application-*  
**Query**: CAE portal agent SharePoint operations
**Focus**: Version 3.27.351 deployment and errors

#### 3. File System Operations
**Index**: system-*, logs-*
**Query**: Settings.rmscript and temp folder operations
**Pattern**: Create /B/Temp, Copy /A/Settings.rmscript → /B/Temp

### Expected Log Categories

1. **error-logs/**: Exception traces and error messages
2. **application-logs/**: CAE Portal Agent operation logs
3. **system-logs/**: File system I/O operations  
4. **sharepoint-logs/**: SharePoint API interactions
5. **regression-logs/**: Version comparison analysis

### Analysis Plan

1. **Timeline Correlation**: Match error timestamps with version deployment
2. **Pattern Recognition**: Identify common failure scenarios  
3. **Root Cause**: Determine what changed between versions
4. **Reproduction**: Validate logs match reported test case

---

**To retrieve logs**: Provide Elastic credentials when prompted by the Elastic.ps1 script.

**Note**: Logs will be automatically saved to this directory with timestamps and categorization.