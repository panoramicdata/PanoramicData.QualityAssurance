# Logs Directory

This directory contains logs retrieved from Elastic for Magic Suite tickets and related systems.

## Directory Structure

```
logs/
├── MS-21863/           # SharePoint file copy regression logs
├── MS-{ticket}/        # Other ticket-specific logs
└── README.md          # This file
```

## MS-21863 Log Collection Strategy

### Search Queries for SharePoint Copy Issue

Based on the ticket details (CAE Portal Agent, SharePoint file copy failures, "Not found" errors), we'll search for:

1. **SharePoint Copy Errors**
   - Index: `logs-*`, `application-*`
   - Query: SharePoint AND (copy OR move) AND ("not found" OR "file not found")
   - Time Range: September 24, 2025 onwards (ticket creation date)

2. **CAE Portal Agent Logs** 
   - Index: `cae-*`, `application-*`
   - Query: "CAE portal agent" AND (SharePoint OR copy OR temp)
   - Focus: Version 3.27.351 logs vs 3.26.501

3. **File System Operations**
   - Index: `system-*`, `logs-*`
   - Query: (Settings.rmscript OR .rmscript) AND (copy OR create OR temp)
   - Look for: File operation failures, permission errors

4. **Error Pattern Matching**
   - Index: `error-*`, `exception-*` 
   - Query: "Not found" AND (folder OR directory OR SharePoint)
   - Pattern: Temp folder creation followed by copy failure

### Log Categories

- **error-logs/**: Error messages and exceptions
- **application-logs/**: CAE Portal Agent application logs  
- **system-logs/**: File system operation logs
- **sharepoint-logs/**: SharePoint-specific interaction logs
- **version-comparison/**: Logs comparing 3.26.501 vs 3.27.351

### Search Commands

To reproduce the log collection, use these Elastic.ps1 commands:

```powershell
# Get available indices
.\.github\tools\Elastic.ps1 -Action "indices"

# Search for SharePoint copy errors (last 30 days)
.\.github\tools\Elastic.ps1 -Action "search" -Index "logs-*" -Parameters @{
    "Query" = @{
        "bool" = @{
            "must" = @(
                @{ "match" = @{ "message" = "SharePoint" } },
                @{ "match" = @{ "message" = "copy" } },
                @{ "match" = @{ "message" = "not found" } }
            ),
            "filter" = @{
                "range" = @{
                    "@timestamp" = @{
                        "gte" = "2025-09-24T00:00:00Z"
                    }
                }
            }
        }
    },
    "Size" = 500
}

# Search for CAE Portal Agent logs
.\.github\tools\Elastic.ps1 -Action "search" -Index "application-*" -Parameters @{
    "Query" = @{
        "bool" = @{
            "must" = @(
                @{ "match" = @{ "application" = "CAE" } },
                @{ "match" = @{ "message" = "SharePoint" } }
            ),
            "filter" = @{
                "range" = @{
                    "@timestamp" = @{
                        "gte" = "2025-09-24T00:00:00Z"
                    }
                }
            }
        }
    },
    "Size" = 500
}
```

### Analysis Focus

For MS-21863 regression analysis, prioritize:

1. **Timeline Analysis**: Before/after version 3.27.351 deployment
2. **Error Patterns**: "Not found" specifically during copy operations  
3. **File Paths**: `/B/Temp` folder creation and access patterns
4. **User Context**: SharePoint permissions and authentication logs
5. **System Resources**: Disk space, network connectivity during failures

### Log File Naming Convention

- `{timestamp}_{category}_{severity}.json` - Individual log entries
- `{date}_search_results_{query_type}.json` - Bulk search results
- `analysis_summary.md` - Human-readable analysis and findings
- `error_patterns.txt` - Extracted error messages and patterns

**Note**: Logs are saved in JSON format to preserve full Elastic document structure and metadata.

---

**Created**: October 9, 2025  
**Last Updated**: October 9, 2025  
**Ticket**: MS-21863 - SharePoint File Copy Regression