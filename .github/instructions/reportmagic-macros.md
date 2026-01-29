# ReportMagic Core and Core Like Macros Testing Instructions

## Overview

This guide covers creating comprehensive `.rmscript` test files for ReportMagic Core macros and 'core-like' macros based on official documentation.

## Documentation Source

### Core Macros (Complete List - 47 Total)
**Base URL:** https://docs.magicsuite.net/ReportMagic/Macros/Core/

ReportMagic has 47 Core macros organized by category:

**Array & Collection:**
- Array.Count, Array, Map

**Flow Control:**
- Break, Continue, ForEach, If, Switch, Stop, Section

**Calculation & Data:**
- Calculate, Inc, Random, LinearRegression

**String Operations:**
- String, Substring, StringIndex, Regex, SearchAndReplace

**Object & Variable:**
- Object, Convert, IsSet, Unset, Delete, Settings

**Document:**
- DocumentBookmark, DocumentBreak, DocumentInsertSection, DocumentSection

**Table:**
- DeleteRow, RepeatRow, FormatTableCell, FormatTableRow, InsertTableCellImage

**Email:**
- Email, EmailFile, EmailReport

**Utility:**
- Comment, Ignore, Execute, Sleep, Stopwatch, Color, Link

**Debug & Error:**
- Breakpoint, ThrowException, Warning

Each macro has its own documentation page:
- https://docs.magicsuite.net/ReportMagic/Macros/Core/Array
- https://docs.magicsuite.net/ReportMagic/Macros/Core/Calculate
- https://docs.magicsuite.net/ReportMagic/Macros/Core/String
- etc.

### Core-Like Macros (Complete List - 66 Total)
These additional macros are also treated as 'core-like' for testing purposes:

**Dictionary (3 macros):**
- Dictionary.Item, Dictionary.Keys, Dictionary.Values
- https://docs.magicsuite.net/ReportMagic/Macros/Dictionary

**Function (2 macros):**
- Function.Call, Function.Define
- https://docs.magicsuite.net/ReportMagic/Macros/Function

**Json (2 macros):**
- Json.Item, Json.List
- https://docs.magicsuite.net/ReportMagic/Macros/Json

**List (20 macros):**
- List.Add, List.Analysis, List.Complement, List.Count, List.Dequeue, List.Duplicates, List.First, List.Graph, List.GroupBy, List.IndicesOf, List.Intersection, List.Item, List.Range, List.SelectColumns, List.Select, List.Sort, List.Table, List.Union, List.Where, List.SummaryValue
- https://docs.magicsuite.net/ReportMagic/Macros/List

**Object (6 macros):**
- Object.ArrayCount, Object.Graph, Object.Property, Object.Type, Object.Unpack, Object.UnpackVariables
- https://docs.magicsuite.net/ReportMagic/Macros/Object

**Table (9 macros):**
- Table.ColumnCount, Table.Delete, Table.Graph, Table.MergeCells, Table.RowCount, Table.Save, Table.Sort, Table.Format, Table.WorldMap
- https://docs.magicsuite.net/ReportMagic/Macros/Table

**Time (8 macros):**
- Calendar, CronHumanReadable, CronRunDate, DateRange, DateTime, DateTime.IsInWorkHours, TimeSpan, DateTime.WorkHoursDuration
- https://docs.magicsuite.net/ReportMagic/Macros/Time

**Variable (3 macros):**
- Variable.Image, Variable.List, Variable.Property
- https://docs.magicsuite.net/ReportMagic/Macros/Variable

**Kroki (1 macro):**
- Kroki.Image
- https://docs.magicsuite.net/ReportMagic/Macros/Kroki

**Cache (5 macros):**
- Cache.Expires, Cache.Get, Cache.IsSet, Cache.Set, Cache.Unset
- https://docs.magicsuite.net/ReportMagic/Macros/Cache

## File Location

### Core Macros
All Core macro rmscript files are stored in:
```
test-scripts/ReportMagic/Macros/Core/{MacroName}.rmscript
```

### Core-Like Macros
Core-like macro rmscript files are stored in their respective folders:
```
test-scripts/ReportMagic/Macros/{MacroName}.rmscript
```
For example:
- `test-scripts/ReportMagic/Macros/Dictionary.rmscript`
- `test-scripts/ReportMagic/Macros/Function.rmscript`
- `test-scripts/ReportMagic/Macros/Json.rmscript`
- etc.

## File Structure

Each rmscript file must follow this structure:

```rmscript
// {MacroName} Macro - Examples
// Purpose: {Brief description from documentation}
// Source: https://docs.magicsuite.net/ReportMagic/Macros/{Core/}{MacroName}

// Example 1: {Description}
[MacroSyntax: parameters]

// Example 2: {Description}
[MacroSyntax: parameters]

// Parameter Tests

// Test: {Parameter name and purpose}
[MacroSyntax: parameter=value]

// Test: {Another parameter}
[MacroSyntax: parameter=value]
```

**Note:** For Core macros, the source URL includes `/Core/` in the path. For core-like macros, it doesn't.

## Content Requirements

### 1. Official Documentation Examples
- Include **ALL** examples from the macro's documentation page
- Copy syntax exactly as shown
- Include any output comments from the documentation

### 2. Parameter Tests
Test each available parameter from the documentation:

**Common Parameters** (available on most macros):
- `comment` - Documentation/readability
- `if` - Conditional execution
- `mode` - Legacy vs Normal mode
- `failureText` - Error message text
- `failureVariable` - Variable to create on failure
- `errorOnOverflow` - NCalc overflow handling
- `obfuscation` - Data obfuscation type
- `warning` - Warning message

**Macro-Specific Parameters:**
- Refer to the macro's documentation for its unique parameters
- Test the `storeAsHidden` (or `=>Variable`) parameter with different variable names

### 3. Variety Tests
Include tests for:
- **Empty values** (e.g., empty arrays `[]`)
- **Special characters** in strings
- **Mixed data types** (numbers, strings, booleans, nulls)
- **Nested structures** (objects within arrays, etc.)
- **Edge cases** (large numbers, negative values, etc.)

### 4. NO Complex Examples
- **Do NOT** create complex multi-level scenarios
- Keep it focused on documentation examples and parameter testing
- Avoid elaborate business logic examples

## Technical Rules

### JsonPath Limitations
When using `Object.Property` macro with jsonPath:

❌ **Wrong** - Cannot nest array access:
```rmscript
[Object.Property: value={=OrderData}, jsonPath="$[0].products[0].name", =>FirstProductName]
```

✅ **Correct** - Break into separate steps:
```rmscript
[Object.Property: value={=OrderData}, jsonPath="$[0]", =>FirstOrder]
[Object.Property: value={=FirstOrder}, jsonPath="$.products[0].name", =>FirstProductName]
```

### Error-Free Requirement
- **All macros must execute without errors**
- Test syntax carefully
- Use intermediate variables when accessing nested properties
- Follow the exact parameter names from documentation

### JSON Syntax
Two valid approaches for JSON values:

**Using `<json>` tags:**
```rmscript
[Array: value=<json>[ "a", false, { "b" : false } ]</json>, =>TheArray]
```

**Using backticks:**
```rmscript
[Array: value=`[ "a", false, { "b" : false } ]`, =>TheArray]
```

## Example: Array.rmscript

Location: `test-scripts/ReportMagic/Macros/Core/Array.rmscript`

Structure:
1. Header comment (name, purpose, source URL)
2. 4 official examples from documentation
3. 13 parameter tests covering:
   - comment, if, mode (Normal/Legacy)
   - failureText, failureVariable, errorOnOverflow
   - Empty arrays, mixed types, nested arrays
   - Special characters, large numbers

Total: 17 working macro examples, no errors, no complex scenarios

## Creating New Macro Files

### Step 1: Fetch Documentation
**Core Macros:**
```
https://docs.magicsuite.net/ReportMagic/Macros/Core/{MacroName}
```

**Core-Like Macros:**
```
https://docs.magicsuite.net/ReportMagic/Macros/{MacroName}
```

### Step 2: Extract Information
- Macro purpose (from "Purpose" section)
- All examples (from "Examples" section)
- All parameters (from "Usage" section table)
- Parameter types and defaults

### Step 3: Create rmscript File
1. Add header comment with purpose and source URL
2. Copy all documentation examples
3. Create parameter tests for each available parameter
4. Add variety tests (empty, special chars, edge cases)
5. Verify all macros execute without errors

### Step 4: Test and Validate
- Run the rmscript file in ReportMagic
- Fix any syntax errors
- Ensure all macros complete successfully
- Check that variables are created correctly

## Common Pitfalls

### JsonPath Issues
- ❌ Nested array access in single jsonPath
- ✅ Break into multiple steps with intermediate variables

### Parameter Syntax
- ❌ Wrong parameter names or typos
- ✅ Check documentation for exact parameter names

### JSON Formatting
- ❌ Unmatched quotes, brackets, or JSON tags
- ✅ Use consistent quoting and validate JSON structure

### Variable Naming
- ❌ Reusing variable names causing conflicts
- ✅ Use descriptive, unique variable names

### Mode Confusion
- ❌ Not understanding Legacy vs Normal mode
- ✅ Test both modes to see differences in variable storage

## Quick Reference

| Task | Action |
|------|--------|
| Find Core macro docs | https://docs.magicsuite.net/ReportMagic/Macros/Core/{Name} |
| Find core-like macro docs | https://docs.magicsuite.net/ReportMagic/Macros/{Name} |
| Create Core file | `test-scripts/ReportMagic/Macros/Core/{Name}.rmscript` |
| Create core-like file | `test-scripts/ReportMagic/Macros/{Name}.rmscript` |
| Fetch page content | Use fetch_webpage tool with URL |
| Test macros | Run rmscript file in ReportMagic Report Studio |
| Fix jsonPath errors | Break nested access into multiple steps |

## Best Practices

1. **Start simple** - Get official examples working first
2. **Add systematically** - Add parameter tests one at a time
3. **Test frequently** - Run the file after each addition
4. **Document clearly** - Use descriptive comments for each test
5. **Keep focused** - No complex business scenarios, just testing

## Resources

- **Documentation:** https://docs.magicsuite.net/ReportMagic/Macros/Core/
- **Example File:** [test-scripts/ReportMagic/Macros/Core/Array.rmscript](../../test-scripts/ReportMagic/Macros/Core/Array.rmscript)
- **ReportMagic Docs Tests:** [test-scripts/ReportMagic/Docs/](../../test-scripts/ReportMagic/Docs/)
