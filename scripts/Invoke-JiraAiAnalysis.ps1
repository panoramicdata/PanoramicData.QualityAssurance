<#
.SYNOPSIS
    Analyzes a JIRA ticket using an LLM and outputs structured JSON.

.DESCRIPTION
    Fetches a JIRA ticket, sends it to an LLM API for analysis, and returns
    categorization, priority assessment, effort estimation, and more.

.PARAMETER IssueKey
    The JIRA issue key (e.g., MS-12345)

.PARAMETER Provider
    LLM provider: OpenAI, AzureOpenAI, Anthropic, or GitHubModels

.EXAMPLE
    .\Invoke-JiraAiAnalysis.ps1 -IssueKey MS-12345 -Provider OpenAI
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$IssueKey,

    [Parameter(Mandatory = $false)]
    [ValidateSet("OpenAI", "AzureOpenAI", "Anthropic", "GitHubModels")]
    [string]$Provider = "OpenAI"
)

$ErrorActionPreference = "Stop"

# --- Configuration (set via environment variables) ---
# OPENAI_API_KEY, ANTHROPIC_API_KEY, AZURE_OPENAI_KEY, AZURE_OPENAI_ENDPOINT
# GITHUB_TOKEN (for GitHub Models)

# --- Fetch JIRA Ticket ---
$jiraScript = Join-Path $PSScriptRoot "..\..\.github\tools\JIRA.ps1"
$ticketJson = & $jiraScript -Action GetFull -IssueKey $IssueKey | ConvertFrom-Json

$ticketContent = @"
Issue Key: $($ticketJson.key)
Summary: $($ticketJson.fields.summary)
Description: $($ticketJson.fields.description)
Type: $($ticketJson.fields.issuetype.name)
Status: $($ticketJson.fields.status.name)
Priority: $($ticketJson.fields.priority.name)
Labels: $($ticketJson.fields.labels -join ", ")
Components: $(($ticketJson.fields.components | ForEach-Object { $_.name }) -join ", ")
Reporter: $($ticketJson.fields.reporter.displayName)
Created: $($ticketJson.fields.created)
"@

# --- LLM Prompt ---
$systemPrompt = @"
You are a JIRA ticket analyzer. Analyze the provided ticket and return a JSON object with:
{
  "issueKey": "string",
  "classification": {
    "type": "bug|feature|task|improvement|support",
    "confidence": 0.0-1.0
  },
  "priorityAssessment": {
    "suggested": "critical|high|medium|low",
    "reasoning": "string"
  },
  "effortEstimate": {
    "tShirtSize": "XS|S|M|L|XL",
    "hoursRange": { "min": number, "max": number },
    "reasoning": "string"
  },
  "components": ["suggested", "components"],
  "tags": ["auto-generated", "tags"],
  "riskFactors": ["list of potential risks"],
  "suggestedAssignee": {
    "role": "frontend|backend|fullstack|qa|devops",
    "skills": ["required", "skills"]
  },
  "summary": "One-line summary of the analysis"
}
Return ONLY valid JSON, no markdown.
"@

# --- Provider-specific API calls ---
function Invoke-OpenAI {
    param($System, $User)
    $headers = @{
        "Authorization" = "Bearer $env:OPENAI_API_KEY"
        "Content-Type"  = "application/json"
    }
    $body = @{
        model    = "gpt-4o"
        messages = @(
            @{ role = "system"; content = $System }
            @{ role = "user"; content = $User }
        )
        response_format = @{ type = "json_object" }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers $headers -Body $body
    return $response.choices[0].message.content
}

function Invoke-Anthropic {
    param($System, $User)
    $headers = @{
        "x-api-key"         = $env:ANTHROPIC_API_KEY
        "anthropic-version" = "2023-06-01"
        "Content-Type"      = "application/json"
    }
    $body = @{
        model      = "claude-sonnet-4-20250514"
        max_tokens = 2048
        system     = $System
        messages   = @(
            @{ role = "user"; content = $User }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post -Headers $headers -Body $body
    return $response.content[0].text
}

function Invoke-AzureOpenAI {
    param($System, $User)
    $endpoint = $env:AZURE_OPENAI_ENDPOINT
    $deployment = $env:AZURE_OPENAI_DEPLOYMENT ?? "gpt-4o"
    $apiVersion = "2024-02-15-preview"
    
    $headers = @{
        "api-key"      = $env:AZURE_OPENAI_KEY
        "Content-Type" = "application/json"
    }
    $body = @{
        messages = @(
            @{ role = "system"; content = $System }
            @{ role = "user"; content = $User }
        )
        response_format = @{ type = "json_object" }
    } | ConvertTo-Json -Depth 10

    $uri = "$endpoint/openai/deployments/$deployment/chat/completions?api-version=$apiVersion"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
    return $response.choices[0].message.content
}

function Invoke-GitHubModels {
    param($System, $User)
    $headers = @{
        "Authorization" = "Bearer $env:GITHUB_TOKEN"
        "Content-Type"  = "application/json"
    }
    $body = @{
        model    = "gpt-4o"
        messages = @(
            @{ role = "system"; content = $System }
            @{ role = "user"; content = $User }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://models.inference.ai.azure.com/chat/completions" -Method Post -Headers $headers -Body $body
    return $response.choices[0].message.content
}

# --- Execute Analysis ---
$userPrompt = "Analyze this JIRA ticket:`n`n$ticketContent"

$result = switch ($Provider) {
    "OpenAI"       { Invoke-OpenAI -System $systemPrompt -User $userPrompt }
    "Anthropic"    { Invoke-Anthropic -System $systemPrompt -User $userPrompt }
    "AzureOpenAI"  { Invoke-AzureOpenAI -System $systemPrompt -User $userPrompt }
    "GitHubModels" { Invoke-GitHubModels -System $systemPrompt -User $userPrompt }
}

# Output JSON result
$result
