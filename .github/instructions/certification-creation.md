# Certification Creation Instructions

## Purpose
Instructions for creating certification quizzes using the standardized JSON format for quiz/certification systems.

## JSON Structure Overview

The certification JSON format consists of:
- **Quiz metadata** (name, description, settings)
- **Topics** (subject areas with multiple questions)
- **Questions** (individual quiz items with answer options)
- **Answer Options** (multiple choice answers with correctness flags)

## Complete JSON Template

```json
{
  "Name": "[Certification Title]",
  "Description": "[Brief description for API/system use]",
  "DescriptionHtml": "<p>[HTML formatted description for display]</p>",
  "CooldownDays": [number],
  "PassPercentage": [percentage],
  "PermittedTimeMinutes": [time limit],
  "NewSessionValidFromUtc": "[ISO date string]",
  "NewSessionValidToUtc": "[ISO date string]",
  "Topics": [
    {
      "Name": "[Topic Name]",
      "Description": "[Topic description]",
      "DescriptionHtml": "<p>[HTML topic description]</p>",
      "Position": [integer],
      "QuestionCount": [number of questions],
      "Questions": [
        {
          "Name": "[Question identifier]",
          "Description": "[Plain text question]",
          "DescriptionHtml": "<p>[HTML formatted question]</p>",
          "QuestionType": "[SingleCorrectAnswer|MultipleCorrectAnswer]",
          "HelpUrl": "[optional help URL or null]",
          "AnswerOptions": [
            {
              "DescriptionHtml": "<p>[Answer text in HTML]</p>",
              "IsCorrect": [true|false]
            }
          ]
        }
      ]
    }
  ]
}
```

## Field Specifications

### Quiz Level Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `Name` | String | Yes | Certification title | "AWS Cloud Practitioner Certification" |
| `Description` | String | Yes | Brief description | "Foundational AWS cloud knowledge assessment" |
| `DescriptionHtml` | String | Yes | HTML formatted description | `"<p>Test your understanding of AWS basics</p>"` |
| `CooldownDays` | Integer | Yes | Days between retakes | `30` |
| `PassPercentage` | Integer | Yes | Minimum score to pass (0-100) | `70` |
| `PermittedTimeMinutes` | Integer | Yes | Time limit in minutes | `90` |
| `NewSessionValidFromUtc` | String | Yes | Start date (ISO format) | `"2026-01-01T00:00:00Z"` |
| `NewSessionValidToUtc` | String | Yes | End date (ISO format) | `"2027-01-01T00:00:00Z"` |

### Topic Level Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `Name` | String | Yes | Topic name | "EC2 Fundamentals" |
| `Description` | String | Yes | Topic description | "Virtual compute instances" |
| `DescriptionHtml` | String | Yes | HTML formatted description | `"<p>Amazon EC2 basics</p>"` |
| `Position` | Integer | Yes | Display order (1, 2, 3...) | `1` |
| `QuestionCount` | Integer | Yes | Number of questions in topic | `5` |

### Question Level Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `Name` | String | Yes | Question identifier | "EC2-Instance-Types" |
| `Description` | String | Yes | Plain text question | "What is EC2?" |
| `DescriptionHtml` | String | Yes | HTML formatted question | `"<p>What is Amazon EC2?</p>"` |
| `QuestionType` | String | Yes | Answer type | `"SingleCorrectAnswer"` or `"MultipleCorrectAnswer"` |
| `HelpUrl` | String | Optional | Link to help/documentation | `"https://docs.aws.amazon.com/ec2/"` or `null` |

### Answer Option Fields

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `DescriptionHtml` | String | Yes | HTML formatted answer | `"<p>Virtual compute service</p>"` |
| `IsCorrect` | Boolean | Yes | Whether this is a correct answer | `true` or `false` |

## Question Types

### SingleCorrectAnswer
- Only ONE answer can be marked as correct (`IsCorrect: true`)
- All other answers must be `IsCorrect: false`
- Used for traditional multiple choice questions

### MultipleCorrectAnswer
- MULTIPLE answers can be marked as correct
- Users must select ALL correct answers to get the question right
- Used for "select all that apply" style questions

## Creation Guidelines

### 1. Planning Your Certification

Before creating the JSON:
- ✅ Define learning objectives
- ✅ Identify 3-7 main topic areas
- ✅ Plan 5-15 questions per topic
- ✅ Set appropriate difficulty level
- ✅ Determine time limits and passing scores

### 2. Content Best Practices

**Questions:**
- Use clear, unambiguous language
- Avoid trick questions
- Test practical knowledge, not memorization
- Include realistic scenarios when possible
- Balance easy/medium/hard difficulty

**Answer Options:**
- Provide 4 answer choices for single correct
- Make incorrect answers plausible but clearly wrong
- Avoid "all of the above" or "none of the above"
- Keep answers roughly the same length

**Topics:**
- Group related questions logically
- Balance question count across topics
- Order topics from basic to advanced
- Use descriptive topic names

### 3. Technical Requirements

**Naming Conventions:**
- Quiz names: Use title case, be descriptive
- Topic names: Clear, concise subject areas
- Question names: Use kebab-case identifiers like "aws-s3-buckets"

**HTML Formatting:**
- Always wrap text in `<p>` tags for basic content
- Use `<strong>` for emphasis, `<em>` for italics
- Use `<code>` for technical terms or commands
- Use `<ul><li>` for lists when needed

**Dates:**
- Use UTC timezone: `"2026-01-01T00:00:00Z"`
- Set realistic validity periods (usually 1-2 years)
- Consider certification renewal cycles

**Timing:**
- 1-2 minutes per question as baseline
- Add extra time for complex scenarios
- Consider target audience experience level

## Example Implementations

### Simple IT Knowledge Certification
```json
{
  "Name": "Basic IT Support Certification",
  "Description": "Fundamental IT troubleshooting and support skills",
  "DescriptionHtml": "<p>Test your basic IT support knowledge covering hardware, software, and networking fundamentals.</p>",
  "CooldownDays": 7,
  "PassPercentage": 75,
  "PermittedTimeMinutes": 45,
  "NewSessionValidFromUtc": "2026-01-01T00:00:00Z",
  "NewSessionValidToUtc": "2026-12-31T23:59:59Z",
  "Topics": [
    {
      "Name": "Hardware Basics",
      "Description": "Computer hardware components and troubleshooting",
      "DescriptionHtml": "<p>Questions about computer hardware components, common issues, and basic troubleshooting steps.</p>",
      "Position": 1,
      "QuestionCount": 6,
      "Questions": [
        {
          "Name": "ram-function",
          "Description": "What is the primary function of RAM?",
          "DescriptionHtml": "<p>What is the primary function of RAM (Random Access Memory)?</p>",
          "QuestionType": "SingleCorrectAnswer",
          "HelpUrl": "https://example.com/hardware-guide",
          "AnswerOptions": [
            {
              "DescriptionHtml": "<p>Permanent storage of files</p>",
              "IsCorrect": false
            },
            {
              "DescriptionHtml": "<p>Temporary storage for running programs</p>",
              "IsCorrect": true
            },
            {
              "DescriptionHtml": "<p>Processing calculations</p>",
              "IsCorrect": false
            },
            {
              "DescriptionHtml": "<p>Connecting to the internet</p>",
              "IsCorrect": false
            }
          ]
        }
      ]
    }
  ]
}
```

### Professional Software Development Certification
```json
{
  "Name": "Full-Stack Developer Certification - Level 1",
  "Description": "Core web development skills assessment",
  "DescriptionHtml": "<p>Comprehensive evaluation of fundamental web development skills including HTML, CSS, JavaScript, and basic backend concepts.</p>",
  "CooldownDays": 30,
  "PassPercentage": 80,
  "PermittedTimeMinutes": 120,
  "NewSessionValidFromUtc": "2026-01-01T00:00:00Z",
  "NewSessionValidToUtc": "2027-01-01T00:00:00Z",
  "Topics": [
    {
      "Name": "Frontend Development",
      "Description": "HTML, CSS, and JavaScript fundamentals",
      "DescriptionHtml": "<p>Core frontend technologies and best practices for building user interfaces.</p>",
      "Position": 1,
      "QuestionCount": 10,
      "Questions": [
        {
          "Name": "html-semantic-tags",
          "Description": "Which HTML tags are semantic?",
          "DescriptionHtml": "<p>Which of the following HTML tags are considered semantic elements? <em>Select all that apply.</em></p>",
          "QuestionType": "MultipleCorrectAnswer",
          "HelpUrl": "https://developer.mozilla.org/en-US/docs/Web/HTML/Element",
          "AnswerOptions": [
            {
              "DescriptionHtml": "<p><code>&lt;header&gt;</code></p>",
              "IsCorrect": true
            },
            {
              "DescriptionHtml": "<p><code>&lt;div&gt;</code></p>",
              "IsCorrect": false
            },
            {
              "DescriptionHtml": "<p><code>&lt;article&gt;</code></p>",
              "IsCorrect": true
            },
            {
              "DescriptionHtml": "<p><code>&lt;span&gt;</code></p>",
              "IsCorrect": false
            }
          ]
        }
      ]
    },
    {
      "Name": "Backend Development",
      "Description": "Server-side programming and databases",
      "DescriptionHtml": "<p>Backend development concepts including APIs, databases, and server architecture.</p>",
      "Position": 2,
      "QuestionCount": 8,
      "Questions": [
        {
          "Name": "rest-api-methods",
          "Description": "What HTTP method is used to create resources?",
          "DescriptionHtml": "<p>In REST API design, which HTTP method is typically used to create new resources?</p>",
          "QuestionType": "SingleCorrectAnswer",
          "HelpUrl": "https://restfulapi.net/http-methods/",
          "AnswerOptions": [
            {
              "DescriptionHtml": "<p>GET</p>",
              "IsCorrect": false
            },
            {
              "DescriptionHtml": "<p>POST</p>",
              "IsCorrect": true
            },
            {
              "DescriptionHtml": "<p>PUT</p>",
              "IsCorrect": false
            },
            {
              "DescriptionHtml": "<p>DELETE</p>",
              "IsCorrect": false
            }
          ]
        }
      ]
    }
  ]
}
```

## Validation Checklist

Before finalizing your certification JSON:

### Structure Validation
- ✅ All required fields are present
- ✅ JSON syntax is valid (use a JSON validator)
- ✅ Date formats are ISO 8601 with UTC timezone
- ✅ All HTML is properly formatted and valid
- ✅ Question counts match actual number of questions

### Content Validation
- ✅ All questions have clear, unambiguous language
- ✅ Each SingleCorrectAnswer has exactly one correct answer
- ✅ MultipleCorrectAnswer questions have appropriate number of correct answers
- ✅ Answer options are balanced and plausible
- ✅ Topics are logically organized and cover the subject comprehensively

### Settings Validation
- ✅ Pass percentage is appropriate for difficulty level
- ✅ Time limit allows sufficient time per question
- ✅ Cooldown period matches organizational requirements
- ✅ Validity dates are realistic and account for content updates

### Accessibility & Usability
- ✅ Questions are readable and understandable
- ✅ HTML content displays properly
- ✅ Help URLs are accessible and relevant
- ✅ Content is appropriate for target audience

## Common Pitfalls to Avoid

### Structural Issues
- ❌ **Missing required fields** - All fields marked as required must be present
- ❌ **Invalid JSON syntax** - Use a validator to check syntax
- ❌ **Incorrect date formats** - Must use ISO 8601 with UTC timezone
- ❌ **Mismatched question counts** - QuestionCount must equal actual questions

### Content Issues
- ❌ **Ambiguous questions** - Questions should have one clear interpretation
- ❌ **Multiple correct answers in SingleCorrectAnswer** - Only one can be true
- ❌ **No correct answers in MultipleCorrectAnswer** - Must have at least one
- ❌ **Obvious or trick answers** - Keep quality high, avoid gotcha questions

### Configuration Issues
- ❌ **Unrealistic time limits** - Too short causes stress, too long enables cheating
- ❌ **Inappropriate pass percentage** - Should match industry standards
- ❌ **Wrong cooldown period** - Consider learning time between attempts
- ❌ **Invalid date ranges** - Check start/end dates are logical

### HTML Formatting Issues
- ❌ **Missing paragraph tags** - Always wrap text in `<p>` tags
- ❌ **Unclosed HTML tags** - Ensure all tags are properly closed
- ❌ **Unsafe HTML content** - Stick to basic formatting tags
- ❌ **Inconsistent formatting** - Use consistent style throughout

## Advanced Features

### Complex Questions
For scenarios requiring code examples or detailed explanations:

```json
{
  "Name": "javascript-debugging",
  "Description": "Debug the JavaScript code",
  "DescriptionHtml": "<p>What will the following JavaScript code output?</p><pre><code>let x = 5;\nlet y = '5';\nconsole.log(x == y);\nconsole.log(x === y);</code></pre>",
  "QuestionType": "SingleCorrectAnswer",
  "HelpUrl": "https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Equality",
  "AnswerOptions": [
    {
      "DescriptionHtml": "<p><code>true, true</code></p>",
      "IsCorrect": false
    },
    {
      "DescriptionHtml": "<p><code>true, false</code></p>",
      "IsCorrect": true
    },
    {
      "DescriptionHtml": "<p><code>false, true</code></p>",
      "IsCorrect": false
    },
    {
      "DescriptionHtml": "<p><code>false, false</code></p>",
      "IsCorrect": false
    }
  ]
}
```

### Using Lists in Questions
For questions with multiple parts or criteria:

```json
{
  "Name": "security-best-practices",
  "Description": "Which are good security practices?",
  "DescriptionHtml": "<p>Which of the following are considered cybersecurity best practices? <em>Select all that apply.</em></p><ul><li>For password management</li><li>For software updates</li><li>For network security</li></ul>",
  "QuestionType": "MultipleCorrectAnswer",
  "HelpUrl": "https://example.com/security-guide",
  "AnswerOptions": [
    {
      "DescriptionHtml": "<p>Use the same password for all accounts</p>",
      "IsCorrect": false
    },
    {
      "DescriptionHtml": "<p>Enable two-factor authentication</p>",
      "IsCorrect": true
    },
    {
      "DescriptionHtml": "<p>Install software updates promptly</p>",
      "IsCorrect": true
    },
    {
      "DescriptionHtml": "<p>Connect to any available WiFi</p>",
      "IsCorrect": false
    }
  ]
}
```

## Integration Notes

When implementing this JSON format:

### System Integration
- Ensure your quiz engine supports both question types
- Implement proper scoring for MultipleCorrectAnswer (all-or-nothing vs partial credit)
- Handle HTML rendering securely
- Validate JSON structure before processing

### User Experience
- Display topic progress clearly
- Show remaining time prominently
- Provide clear instructions for MultipleCorrectAnswer questions
- Allow review of answers before submission

### Security Considerations
- Sanitize HTML content to prevent XSS attacks
- Don't expose correct answers in client-side code
- Implement proper session management
- Enforce cooldown periods server-side

---

**Best Practice**: Start with a small pilot certification (2-3 topics, 10-15 questions) to test your implementation before creating larger, more complex certifications.

**Validation Tools**: Use online JSON validators and HTML validators to check your content before deployment.

**Version Control**: Keep certification versions tracked, as you may need to update content while maintaining historical results.