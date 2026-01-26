# Generated Smoke Tests

This folder contains auto-generated Playwright smoke tests created by the `Generate-SmokeTest.ps1` script.

## How It Works

1. Script analyzes JIRA ticket description
2. Detects the affected page/component
3. Selects an appropriate test template based on keywords
4. Generates a minimal Playwright test
5. Saves it here for execution

## Running Generated Tests

```bash
# Single test
npx playwright test ms-22886-smoke --project=firefox

# All generated tests
npx playwright test Generated --project=firefox
```

## Templates Available

| Template | Triggers | What It Tests |
|----------|----------|---------------|
| button | "button should", "click", "visible" | Button visibility and clickability |
| dark-mode | "dark mode", "theme", "light mode" | Theme toggle and visual consistency |
| error-message | "error message", "toast", "notification" | Error display and content |
| modal | "modal", "dialog", "popup" | Modal open/close behavior |
| display | "should display", "column", "dropdown" | Element visibility |
| generic | (fallback) | Page load and screenshots |

## Customization

Generated tests are starting points. After generation:
1. Review the test file
2. Add specific assertions for the ticket
3. Update selectors if auto-detection was wrong
4. Move to appropriate permanent folder if keeping

## Naming Convention

`{issue-key}-smoke.spec.ts`

Example: `ms-22886-smoke.spec.ts`

## Evidence

Screenshots are saved to `playwright/screenshots/` with pattern:
`{issue-key}-{state}.png`

## Note

These are auto-generated tests. They provide a starting point for verification but should be reviewed before using results as definitive evidence.
