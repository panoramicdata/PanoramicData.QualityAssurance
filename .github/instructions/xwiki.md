# XWiki Integration Instructions

## Tool Location
`.github/tools/XWiki.ps1`

## Critical Rules
- **ALWAYS use XWiki.ps1** for page operations - never direct API unless unavoidable
- **Understand nested space structure** - Magic Suite uses nested spaces (e.g., `MagicSuite.DataMagic.UserGuide`)
- **Content encoding** - XWiki uses HTML for page content, with special formatting for headings, paragraphs, lists

## Authentication
- **Environment Variables**: `$env:XWIKI_USERNAME`, `$env:XWIKI_PASSWORD` (required for protected spaces)
- **XWiki URL**: https://docs.panoramicdata.com (or test environment URL)
- **Base Path**: `/xwiki/rest`

## Common Actions

### Get Page Content
```powershell
# Get page from nested space
.\.github\tools\XWiki.ps1 -Action Get -Space "MagicSuite.DataMagic" -PageName "UserGuide"

# Get page with spaces in name
.\.github\tools\XWiki.ps1 -Action Get -Space "MagicSuite" -PageName "Release Notes"
```

### Create or Update Pages
```powershell
# Create new page
$content = @"
= Page Title =

== Section 1 ==
Some content here.

* Bullet point 1
* Bullet point 2
"@

.\.github\tools\XWiki.ps1 -Action CreateOrUpdate -Space "MagicSuite.DataMagic" -PageName "NewPage" -Content $content -Title "New Page Title"
```

### List Pages in Space
```powershell
# List all pages in a space
.\.github\tools\XWiki.ps1 -Action List -Space "MagicSuite"

# List pages in nested space
.\.github\tools\XWiki.ps1 -Action List -Space "MagicSuite.DataMagic"
```

### Delete Page
```powershell
.\.github\tools\XWiki.ps1 -Action Delete -Space "MagicSuite.Test" -PageName "TempPage"
```

## XWiki Syntax Reference

### Headings
```
= Level 1 Heading =
== Level 2 Heading ==
=== Level 3 Heading ===
```

### Text Formatting
```
**bold**
//italic//
__underline__
--strikethrough--
{{code}}inline code{{/code}}
```

### Lists
```
* Unordered item 1
** Nested item
* Unordered item 2

1. Ordered item 1
11. Nested ordered item
1. Ordered item 2
```

### Links
```
[[Internal Page Link]]
[[Label>>Space.Page]]
[[External Link>>http://example.com]]
```

### Code Blocks
```
{{code language="powershell"}}
Write-Host "Hello World"
{{/code}}
```

### Tables
```
|= Header 1 |= Header 2 |= Header 3
| Cell 1 | Cell 2 | Cell 3
| Cell 4 | Cell 5 | Cell 6
```

### Images
```
[[image:AttachmentName.png]]
[[image:Space.Page@attachment.png||width="500"]]
```

## Nested Spaces

Magic Suite documentation uses nested space structure:

### Main Spaces
- **MagicSuite** - Main documentation space
  - **MagicSuite.DataMagic** - DataMagic documentation
  - **MagicSuite.ReportMagic** - ReportMagic documentation
  - **MagicSuite.AlertMagic** - AlertMagic documentation
  - **MagicSuite.CLI** - CLI documentation
  - **MagicSuite.Admin** - Admin documentation
  - **MagicSuite.Connect** - Connect documentation

### Accessing Nested Pages
```powershell
# Format: "ParentSpace.ChildSpace"
.\.github\tools\XWiki.ps1 -Action Get -Space "MagicSuite.DataMagic" -PageName "Installation"
```

## Content Encoding

XWiki REST API expects content in specific format:

### HTML for XWiki 2.1 Syntax
```html
<h1>Main Heading</h1>
<h2>Subheading</h2>
<p>Paragraph text</p>
<ul>
  <li>List item 1</li>
  <li>List item 2</li>
</ul>
```

### Plain Text for XWiki Syntax
Use XWiki markup (shown above) when syntax parameter is `xwiki/2.1`

## Testing Documentation

### Verification Checklist
When testing XWiki pages:
1. ✓ Page exists and is accessible
2. ✓ All links are valid (no 404s)
3. ✓ Images load correctly
4. ✓ Code examples are accurate
5. ✓ Version information is current
6. ✓ Screenshots reflect latest UI
7. ✓ Navigation structure is correct

### Common Test Cases
```powershell
# Test 1: Verify page exists
$page = .\.github\tools\XWiki.ps1 -Action Get -Space "MagicSuite" -PageName "Overview"
if ($page) { Write-Host "✓ Page exists" } else { Write-Host "✗ Page not found" }

# Test 2: Check for required content
if ($page.content -match "DataMagic") {
    Write-Host "✓ Content includes DataMagic"
} else {
    Write-Host "✗ Missing DataMagic reference"
}

# Test 3: Verify version matches
if ($page.content -match "v4\.1\.") {
    Write-Host "✓ Version reference found"
} else {
    Write-Host "✗ Version not documented"
}
```

## Common Pitfalls

### Space Names
- ❌ **Wrong**: Using `/` as separator (`MagicSuite/DataMagic`)
- ✅ **Correct**: Using `.` as separator (`MagicSuite.DataMagic`)

### Page Names
- ❌ **Wrong**: URL encoding manually (`User%20Guide`)
- ✅ **Correct**: Use exact page name, script handles encoding (`User Guide`)

### Content Format
- ❌ **Wrong**: Mixing HTML and XWiki syntax
- ✅ **Correct**: Use one consistent format throughout page

### Authentication
- ❌ **Wrong**: Hardcoding credentials in scripts
- ✅ **Correct**: Use environment variables (`$env:XWIKI_USERNAME`, `$env:XWIKI_PASSWORD`)

## Browser Testing

When testing docs UI (not using XWiki.ps1):
1. Use Playwright tests in `playwright/Magic Suite/Docs/`
2. Always use `--project=firefox`
3. Authenticate first: `npx playwright test auth.setup --project=firefox`
4. Run specific docs tests: `npx playwright test docs-verification --project=firefox`

## Extending XWiki.ps1

When adding new functionality:
1. Follow existing REST API patterns
2. Handle authentication correctly
3. Encode URLs properly for spaces and page names
4. Return structured data (PSCustomObject)
5. Add error handling for common issues
6. Document parameters and examples
