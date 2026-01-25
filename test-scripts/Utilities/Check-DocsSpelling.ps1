<#
.SYNOPSIS
    Spider MagicSuite docs from Blogger and check for spelling/grammar issues.

.DESCRIPTION
    This script fetches all documentation pages from the MagicSuite Blogger blog,
    extracts text content from HTML, and runs spelling checks to identify potential
    issues. Results are saved to a markdown report.

.PARAMETER OutputPath
    Path to save the spelling report. Default: test-results/docs-spelling-report.md

.PARAMETER SaveContent
    If specified, saves extracted text content to docs-content/ folder for review.

.PARAMETER CustomDictionary
    Path to a custom dictionary file with additional valid words (one per line).

.EXAMPLE
    # Run spelling check and generate report
    .\Check-DocsSpelling.ps1

    # Save extracted content for manual review
    .\Check-DocsSpelling.ps1 -SaveContent

    # Use custom dictionary
    .\Check-DocsSpelling.ps1 -CustomDictionary ".\my-dictionary.txt"

.NOTES
    Requires: .github/tools/Blogger.ps1
    No authentication required - uses public Atom feed.
#>

param(
    [string]$OutputPath = "test-results/docs-spelling-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md",
    [switch]$SaveContent,
    [string]$CustomDictionary
)

$ErrorActionPreference = "Stop"
$scriptRoot = $PSScriptRoot
$repoRoot = (Get-Item $scriptRoot).Parent.Parent.FullName

# MagicSuite-specific terms that should not be flagged as spelling errors
$magicSuiteTerms = @(
    # Product names
    "MagicSuite", "DataMagic", "ReportMagic", "AlertMagic", "ConnectMagic", 
    "MonitorMagic", "ProMagic", "NCalc", "NCalc101",
    
    # Company/Brand
    "Panoramic", "PanoramicData", "Meraki", "LogicMonitor", "Cisco",
    "ConnectWise", "Autotask", "Datto", "HaloPSA", "Halo",
    
    # Technical terms
    "API", "APIs", "OAuth", "OAuth2", "JSON", "SQL", "HTML", "CSS",
    "CLI", "SDK", "REST", "CRUD", "URL", "URLs", "URI", "URIs",
    "webhook", "webhooks", "endpoint", "endpoints", "metadata",
    "async", "sync", "config", "configs", "param", "params",
    "enum", "enums", "bool", "boolean", "int", "datetime",
    "namespace", "namespaces", "dropdown", "dropdowns",
    "checkbox", "checkboxes", "tooltip", "tooltips",
    "navbar", "sidebar", "toolbar", "popup", "popups",
    "login", "logout", "signup", "username", "usernames",
    "timestamp", "timestamps", "dataset", "datasets",
    "datastore", "datastores", "readonly", "inline",
    "pre-configured", "pre-built", "pre-defined",
    "multi-tenant", "multi-select", "multi-line",
    
    # Cloud/Infrastructure
    "Kubernetes", "K8s", "Azure", "AWS", "GCP", "SaaS", "MSP", "MSPs",
    "VM", "VMs", "ITSM", "DevOps", "AIOps", "Observability",
    
    # File/Format types
    "CSV", "XML", "YAML", "PowerShell", "Blazor", "dotnet", ".NET",
    "xlsx", "pdf", "png", "jpg", "svg",
    
    # Misc technical
    "refactored", "deprecated", "serialized", "deserialized",
    "parameterized", "initialized", "instantiated", "concatenated",
    "deduplicated", "de-duplicates", "productised", "customisable",
    "onboarding", "onboarded", "offboarding"
)

# Common words that might be flagged but are valid
$commonValidWords = @(
    "etc", "e.g.", "i.e.", "vs", "v1", "v2", "v3", "v4",
    "README", "changelog", "admin", "admins"
)

# Build dictionary
$dictionary = @{}
foreach ($term in ($magicSuiteTerms + $commonValidWords)) {
    $dictionary[$term.ToLower()] = $true
}

# Load custom dictionary if provided
if ($CustomDictionary -and (Test-Path $CustomDictionary)) {
    Get-Content $CustomDictionary | ForEach-Object {
        if ($_.Trim()) {
            $dictionary[$_.Trim().ToLower()] = $true
        }
    }
    Write-Host "Loaded custom dictionary: $CustomDictionary" -ForegroundColor Gray
}

function Remove-HtmlTags {
    param([string]$Html)
    
    # Remove script and style blocks entirely
    $text = $Html -replace '(?s)<script[^>]*>.*?</script>', ''
    $text = $text -replace '(?s)<style[^>]*>.*?</style>', ''
    
    # Remove HTML comments
    $text = $text -replace '(?s)<!--.*?-->', ''
    
    # Convert common HTML entities
    $text = $text -replace '&nbsp;', ' '
    $text = $text -replace '&amp;', '&'
    $text = $text -replace '&lt;', '<'
    $text = $text -replace '&gt;', '>'
    $text = $text -replace '&quot;', '"'
    $text = $text -replace '&#39;', "'"
    $text = $text -replace '&[a-zA-Z]+;', ' '
    
    # Add newlines for block elements
    $text = $text -replace '<br\s*/?>', "`n"
    $text = $text -replace '</p>', "`n`n"
    $text = $text -replace '</div>', "`n"
    $text = $text -replace '</li>', "`n"
    $text = $text -replace '</h[1-6]>', "`n`n"
    
    # Remove all remaining HTML tags
    $text = $text -replace '<[^>]+>', ''
    
    # Clean up whitespace
    $text = $text -replace '\r\n', "`n"
    $text = $text -replace '[ \t]+', ' '
    $text = $text -replace '\n{3,}', "`n`n"
    $text = $text.Trim()
    
    return $text
}

function Get-SpellingIssues {
    param(
        [string]$Text,
        [string]$PageTitle
    )
    
    $issues = @()
    
    # Extract words (excluding code-like patterns, URLs, emails)
    $words = [regex]::Matches($Text, '\b[a-zA-Z]{3,}\b') | ForEach-Object { $_.Value }
    
    # Common misspellings dictionary
    $commonMisspellings = @{
        "teh" = "the"
        "recieve" = "receive"
        "occured" = "occurred"
        "seperate" = "separate"
        "definately" = "definitely"
        "occurance" = "occurrence"
        "accomodate" = "accommodate"
        "wierd" = "weird"
        "untill" = "until"
        "calender" = "calendar"
        "enviroment" = "environment"
        "goverment" = "government"
        "independant" = "independent"
        "liason" = "liaison"
        "millenium" = "millennium"
        "neccessary" = "necessary"
        "occassion" = "occasion"
        "persistant" = "persistent"
        "priviledge" = "privilege"
        "publically" = "publicly"
        "reccomend" = "recommend"
        "refered" = "referred"
        "relevent" = "relevant"
        "resistence" = "resistance"
        "responsable" = "responsible"
        "succesful" = "successful"
        "supercede" = "supersede"
        "threshhold" = "threshold"
        "tommorow" = "tomorrow"
        "transfered" = "transferred"
        "truely" = "truly"
        "unfortunatly" = "unfortunately"
        "usualy" = "usually"
        "wether" = "whether"
        "writting" = "writing"
        "acheive" = "achieve"
        "agressive" = "aggressive"
        "apparant" = "apparent"
        "arguement" = "argument"
        "begining" = "beginning"
        "beleive" = "believe"
        "buisness" = "business"
        "catagory" = "category"
        "collegue" = "colleague"
        "comming" = "coming"
        "commitee" = "committee"
        "completly" = "completely"
        "concious" = "conscious"
        "copywrite" = "copyright"
        "desparate" = "desperate"
        "developement" = "development"
        "diffrent" = "different"
        "dissapear" = "disappear"
        "dissapoint" = "disappoint"
        "embarass" = "embarrass"
        "existance" = "existence"
        "experiance" = "experience"
        "Febuary" = "February"
        "finaly" = "finally"
        "foriegn" = "foreign"
        "fourty" = "forty"
        "freind" = "friend"
        "furthur" = "further"
        "gaurd" = "guard"
        "happend" = "happened"
        "harrass" = "harass"
        "heighth" = "height"
        "heros" = "heroes"
        "humourous" = "humorous"
        "immediatly" = "immediately"
        "incidently" = "incidentally"
        "interuption" = "interruption"
        "knowlege" = "knowledge"
        "lightening" = "lightning"
        "maintainance" = "maintenance"
        "manuever" = "maneuver"
        "mispell" = "misspell"
        "noticable" = "noticeable"
        "occurence" = "occurrence"
        "paralell" = "parallel"
        "pasttime" = "pastime"
        "percieve" = "perceive"
        "performence" = "performance"
        "permissable" = "permissible"
        "personell" = "personnel"
        "posession" = "possession"
        "potatos" = "potatoes"
        "preceed" = "precede"
        "prefered" = "preferred"
        "presance" = "presence"
        "privelege" = "privilege"
        "probly" = "probably"
        "procede" = "proceed"
        "profesional" = "professional"
        "prominant" = "prominent"
        "pronounciation" = "pronunciation"
        "questionaire" = "questionnaire"
        "realy" = "really"
        "recieved" = "received"
        "reconize" = "recognize"
        "rediculous" = "ridiculous"
        "refference" = "reference"
        "religous" = "religious"
        "repitition" = "repetition"
        "rythm" = "rhythm"
        "sargent" = "sergeant"
        "scedule" = "schedule"
        "scholorship" = "scholarship"
        "sence" = "sense"
        "sentance" = "sentence"
        "similer" = "similar"
        "sincerly" = "sincerely"
        "speach" = "speech"
        "strenght" = "strength"
        "succede" = "succeed"
        "suprise" = "surprise"
        "tendancy" = "tendency"
        "therefor" = "therefore"
        "thier" = "their"
        "tounge" = "tongue"
        "tryed" = "tried"
        "tyrany" = "tyranny"
        "underate" = "underrate"
        "unecessary" = "unnecessary"
        "usefull" = "useful"
        "vaccuum" = "vacuum"
        "vegetable" = "vegetable"
        "vehical" = "vehicle"
        "visable" = "visible"
        "wich" = "which"
        "withdrawl" = "withdrawal"
    }
    
    # Check each word
    $wordCounts = @{}
    foreach ($word in $words) {
        $lower = $word.ToLower()
        
        # Skip if in dictionary
        if ($dictionary[$lower]) { continue }
        
        # Skip numbers, very short words
        if ($word -match '^\d+$') { continue }
        if ($word.Length -lt 3) { continue }
        
        # Skip camelCase or PascalCase (likely code)
        if ($word -cmatch '^[a-z]+[A-Z]' -or $word -cmatch '^[A-Z][a-z]+[A-Z]') { continue }
        
        # Skip ALL CAPS (likely acronyms)
        if ($word -cmatch '^[A-Z]{2,}$') { continue }
        
        # Check for known misspellings
        if ($commonMisspellings[$lower]) {
            if (-not $wordCounts[$lower]) {
                $issues += [PSCustomObject]@{
                    Type = "Misspelling"
                    Word = $word
                    Suggestion = $commonMisspellings[$lower]
                    Page = $PageTitle
                }
                $wordCounts[$lower] = 1
            }
        }
    }
    
    return $issues
}

function Get-GrammarIssues {
    param(
        [string]$Text,
        [string]$PageTitle
    )
    
    $issues = @()
    
    # Common grammar patterns to check (excluding multiple spaces - too noisy from HTML)
    # Note: a/an checks removed as they have too many false positives (user, XLSX, etc.)
    $patterns = @(
        # Removed a/an checks - too many false positives with technical terms
        @{ Pattern = '\b(its)\s+(a|the|an)\b'; Suggestion = "Check: 'its' (possessive) vs 'it''s' (it is)"; Type = "Grammar" }
        @{ Pattern = '\b(your)\s+(welcome|the\s+best)\b'; Suggestion = "Check: 'your' (possessive) vs 'you''re' (you are)"; Type = "Grammar" }
        @{ Pattern = '\b(their)\s+(is|are|was|were)\b'; Suggestion = "Check: 'their' (possessive) vs 'there' (location) vs 'they''re' (they are)"; Type = "Grammar" }
        @{ Pattern = '\b(alot)\b'; Suggestion = "Should be 'a lot' (two words)"; Type = "Spelling" }
        @{ Pattern = '\b(can not)\b'; Suggestion = "Consider 'cannot' (one word)"; Type = "Style" }
        @{ Pattern = '\.{2}(?!\.)'; Suggestion = "Double period - use single period or ellipsis (...)"; Type = "Punctuation" }
        @{ Pattern = '\?\?+'; Suggestion = "Multiple question marks"; Type = "Punctuation" }
        @{ Pattern = '!!+'; Suggestion = "Multiple exclamation marks"; Type = "Punctuation" }
        @{ Pattern = '\b(very\s+unique|most\s+unique)\b'; Suggestion = "'Unique' is absolute - doesn't need qualifiers"; Type = "Style" }
        @{ Pattern = '\b(could\s+of|would\s+of|should\s+of)\b'; Suggestion = "Should be 'could have', 'would have', 'should have'"; Type = "Grammar" }
        @{ Pattern = '\b(less)\s+\w+s\b'; Suggestion = "Consider 'fewer' for countable items"; Type = "Style" }
        @{ Pattern = '\bi\b(?![.\)])'; Suggestion = "Capitalize 'I' (personal pronoun)"; Type = "Grammar" }
        @{ Pattern = '\b(irregardless)\b'; Suggestion = "Use 'regardless' instead"; Type = "Grammar" }
        @{ Pattern = '\b(supposably)\b'; Suggestion = "Use 'supposedly' instead"; Type = "Spelling" }
        @{ Pattern = '\b(firstly|secondly|thirdly)\b'; Suggestion = "Consider 'first', 'second', 'third' (simpler)"; Type = "Style" }
    )
    
    foreach ($check in $patterns) {
        $matches = [regex]::Matches($Text, $check.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($match in $matches) {
            $issues += [PSCustomObject]@{
                Type = $check.Type
                Word = $match.Value.Trim()
                Suggestion = $check.Suggestion
                Page = $PageTitle
            }
        }
    }
    
    return $issues
}

# Main execution
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  MagicSuite Documentation Spelling & Grammar Check" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# Get all pages from Blogger
Write-Host "Fetching documentation pages from Blogger..." -ForegroundColor Yellow
$bloggerScript = Join-Path $repoRoot ".github\tools\Blogger.ps1"

if (-not (Test-Path $bloggerScript)) {
    Write-Error "Blogger.ps1 not found at: $bloggerScript"
    exit 1
}

$pagesJson = & $bloggerScript -Action list-pages -AsJson
$pages = ($pagesJson | ConvertFrom-Json).items

Write-Host "Found $($pages.Count) pages to analyze" -ForegroundColor Green
Write-Host ""

# Create output directories
if ($SaveContent) {
    $contentDir = Join-Path $repoRoot "docs-content"
    if (-not (Test-Path $contentDir)) {
        New-Item -ItemType Directory -Path $contentDir -Force | Out-Null
    }
}

$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path (Join-Path $repoRoot $outputDir))) {
    New-Item -ItemType Directory -Path (Join-Path $repoRoot $outputDir) -Force | Out-Null
}

# Process each page
$allIssues = @()
$pageStats = @()

foreach ($page in $pages) {
    Write-Host "  Analyzing: $($page.title)..." -ForegroundColor Gray
    
    # Extract text from HTML
    $plainText = Remove-HtmlTags -Html $page.content
    
    # Save content if requested
    if ($SaveContent) {
        $safeTitle = $page.title -replace '[\\/:*?"<>|]', '_'
        $contentFile = Join-Path $contentDir "$safeTitle.txt"
        $plainText | Out-File -FilePath $contentFile -Encoding UTF8
    }
    
    # Get spelling issues
    $spellingIssues = Get-SpellingIssues -Text $plainText -PageTitle $page.title
    
    # Get grammar issues
    $grammarIssues = Get-GrammarIssues -Text $plainText -PageTitle $page.title
    
    $pageIssues = $spellingIssues + $grammarIssues
    $allIssues += $pageIssues
    
    $pageStats += [PSCustomObject]@{
        Title = $page.title
        WordCount = ([regex]::Matches($plainText, '\b\w+\b')).Count
        IssueCount = $pageIssues.Count
        URL = $page.url
    }
}

Write-Host ""
Write-Host "Analysis complete!" -ForegroundColor Green

# Generate report
$reportContent = @"
# MagicSuite Documentation Quality Report

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Pages Analyzed:** $($pages.Count)
**Total Issues Found:** $($allIssues.Count)

---

## Summary by Page

| Page | Word Count | Issues |
|------|------------|--------|
"@

foreach ($stat in ($pageStats | Sort-Object -Property IssueCount -Descending)) {
    $reportContent += "`n| [$($stat.Title)]($($stat.URL)) | $($stat.WordCount) | $($stat.IssueCount) |"
}

$reportContent += @"


---

## Issues by Type

"@

$issuesByType = $allIssues | Group-Object -Property Type | Sort-Object -Property Count -Descending

foreach ($group in $issuesByType) {
    $reportContent += "`n### $($group.Name) ($($group.Count) issues)`n`n"
    
    $groupedByPage = $group.Group | Group-Object -Property Page
    foreach ($pageGroup in $groupedByPage) {
        $reportContent += "**$($pageGroup.Name)**`n"
        foreach ($issue in $pageGroup.Group) {
            $reportContent += "- ``$($issue.Word)`` - $($issue.Suggestion)`n"
        }
        $reportContent += "`n"
    }
}

$reportContent += @"

---

## Custom Dictionary

The following terms are pre-approved and will not be flagged:

### Product Names
$(($magicSuiteTerms | Where-Object { $_ -match 'Magic|Panoramic|Meraki|Logic|Cisco|Connect|Auto|Datto|Halo' }) -join ', ')

### Technical Terms
$(($magicSuiteTerms | Where-Object { $_ -match 'API|OAuth|JSON|SQL|CLI|SDK|REST|URL|webhook|async|config|enum|bool' }) -join ', ')

---

## Notes

- This report uses pattern-matching heuristics, not a full spell-checker
- Some technical terms may be incorrectly flagged
- Review each issue in context before making changes
- Add false positives to the custom dictionary

"@

# Save report
$fullOutputPath = Join-Path $repoRoot $OutputPath
$reportContent | Out-File -FilePath $fullOutputPath -Encoding UTF8

Write-Host ""
Write-Host "Report saved to: $OutputPath" -ForegroundColor Cyan

if ($SaveContent) {
    Write-Host "Content saved to: docs-content/" -ForegroundColor Cyan
}

# Display summary
Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""
Write-Host "  Pages analyzed:  $($pages.Count)" -ForegroundColor White
Write-Host "  Total issues:    $($allIssues.Count)" -ForegroundColor $(if ($allIssues.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($issuesByType) {
    Write-Host "  Issues by type:" -ForegroundColor White
    foreach ($group in $issuesByType) {
        Write-Host "    - $($group.Name): $($group.Count)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "  Top pages with issues:" -ForegroundColor White
$pageStats | Sort-Object -Property IssueCount -Descending | Select-Object -First 5 | ForEach-Object {
    if ($_.IssueCount -gt 0) {
        Write-Host "    - $($_.Title): $($_.IssueCount) issues" -ForegroundColor Gray
    }
}

Write-Host ""
