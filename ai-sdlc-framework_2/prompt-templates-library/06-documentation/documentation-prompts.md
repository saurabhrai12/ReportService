# Documentation Prompts

## DOC-001: API Documentation Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating API reference documentation

```markdown
Generate comprehensive API documentation.

## API Code/Specification
```{LANGUAGE}
{API_CODE}
```

## Documentation Format
{FORMAT}
<!-- OpenAPI/Swagger, Markdown, Postman Collection -->

## Generate:

### For Each Endpoint

#### Basic Information
- HTTP Method and Path
- Summary (one line)
- Description (detailed)
- Authentication required

#### Request
- Headers
- Path parameters
- Query parameters
- Request body schema
- Example request

#### Response
- Status codes
- Response body schema
- Example responses (success and error)

#### Usage
- Code examples in {LANGUAGES}
- Common use cases
- Rate limiting notes

### Additional Sections
- Authentication guide
- Error code reference
- Pagination guide
- Versioning policy
- Changelog

## Output Format
```yaml
# OpenAPI 3.0 format (or specified format)
```
```

---

## DOC-002: Code Documentation Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating docstrings and code comments

```markdown
Generate documentation for this code.

## Code
```{LANGUAGE}
{CODE}
```

## Documentation Style
{STYLE}
<!-- Google style, NumPy style, JSDoc, JavaDoc -->

## Generate:

### Module/File Documentation
- Purpose
- Dependencies
- Usage example

### Class Documentation
- Description
- Attributes
- Example usage

### Function/Method Documentation
- Description
- Parameters with types
- Return value
- Raises/Throws
- Example

### Inline Comments
- Complex logic explanations
- Algorithm descriptions
- TODO/FIXME where appropriate

## Output
Fully documented code with:
- Consistent style
- Complete type information
- Practical examples
- Cross-references where relevant
```

---

## DOC-003: README Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating project README files

```markdown
Generate a README for this project.

## Project Information
- Name: {PROJECT_NAME}
- Type: {PROJECT_TYPE}
- Language: {LANGUAGE}
- Purpose: {PURPOSE}

## Key Features
{FEATURES}

## Target Audience
{AUDIENCE}

## Generate README With:

### Essential Sections
1. **Title and Description**
   - Project name with badges
   - One-paragraph description
   - Key features list

2. **Installation**
   - Prerequisites
   - Step-by-step instructions
   - Platform-specific notes

3. **Quick Start**
   - Minimal example to get running
   - Expected output

4. **Usage**
   - Common use cases with examples
   - Configuration options
   - CLI reference (if applicable)

5. **API Reference** (if library)
   - Link to full docs
   - Quick reference of main functions

6. **Contributing**
   - How to contribute
   - Development setup
   - Code style guidelines

7. **License**

### Optional Sections (include if relevant)
- Architecture overview
- Deployment guide
- FAQ
- Troubleshooting
- Roadmap
- Acknowledgments

## Output
Complete README.md with proper Markdown formatting
```

---

## DOC-004: Architecture Decision Record (ADR)
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Documenting architecture decisions

```markdown
Create an Architecture Decision Record.

## Decision Context
{CONTEXT}

## Decision Required
{DECISION_NEEDED}

## Constraints
{CONSTRAINTS}

## Generate ADR:

### Title
ADR-{NUMBER}: {DECISION_TITLE}

### Status
{STATUS}
<!-- Proposed, Accepted, Deprecated, Superseded -->

### Context
- What is the issue?
- Why is a decision needed?
- What constraints exist?

### Decision Drivers
- Key factors influencing the decision
- Priority of each factor

### Considered Options
For each option:
- Option description
- Pros
- Cons
- Effort estimate

### Decision
- Chosen option
- Rationale for choice

### Consequences
- Positive consequences
- Negative consequences
- Risks and mitigations

### Validation
- How will we know if this was the right decision?
- Metrics to track
- Review date

### References
- Related ADRs
- External resources
- Discussion links

## Output Format
Standard ADR Markdown template
```

---

## DOC-005: Runbook Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating operational runbooks

```markdown
Create an operational runbook for this system/process.

## System/Process
{SYSTEM_DESCRIPTION}

## Operations Context
- Environment: {ENVIRONMENT}
- Team: {TEAM}
- Escalation: {ESCALATION_PATH}

## Generate Runbook:

### Overview
- Purpose of this runbook
- When to use it
- Prerequisites

### System Information
- Architecture diagram reference
- Key components
- Dependencies
- Access requirements

### Standard Operating Procedures

#### {PROCEDURE_NAME}
**Purpose**: {PURPOSE}
**When to run**: {TRIGGER}
**Estimated time**: {TIME}
**Risk level**: {RISK}

**Steps**:
1. [ ] Step with command/action
   ```bash
   {COMMAND}
   ```
   Expected output: {EXPECTED}

2. [ ] Next step...

**Verification**: How to confirm success
**Rollback**: How to undo if needed

### Troubleshooting Guide

| Symptom | Possible Cause | Resolution |
|---------|---------------|------------|
| {SYMPTOM} | {CAUSE} | {RESOLUTION} |

### Emergency Procedures
- Incident response
- Emergency contacts
- Escalation procedures

### Appendix
- Common commands reference
- Log locations
- Monitoring links
- Related documentation

## Output
Complete runbook in operational format
```

---

## DOC-006: Technical Design Document
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating technical design documents

```markdown
Create a technical design document.

## Feature/Project
{FEATURE_DESCRIPTION}

## Requirements
{REQUIREMENTS}

## Generate Design Document:

### 1. Overview
- Problem statement
- Goals and non-goals
- Success metrics

### 2. Background
- Current state
- Why change is needed
- Related work

### 3. Proposed Solution
- High-level approach
- Architecture diagram
- Key components

### 4. Detailed Design

#### Data Model
- Schema changes
- Data flow

#### API Design
- New endpoints
- Contract changes

#### Component Design
- Class/module structure
- Interfaces

### 5. Implementation Plan
- Milestones
- Dependencies
- Rollout strategy

### 6. Alternatives Considered
- Other approaches
- Why not chosen

### 7. Operational Considerations
- Monitoring
- Alerting
- Deployment

### 8. Security Considerations
- Threat model
- Mitigations

### 9. Testing Strategy
- Test plan
- Coverage requirements

### 10. Open Questions
- Unresolved issues
- Areas needing input

### 11. Timeline
- Phases
- Estimated dates

## Output
Complete design document
```

---

## DOC-007: Release Notes Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating release notes from commits/PRs

```markdown
Generate release notes from these changes.

## Changes
{CHANGES}
<!-- Git log, PR list, or change descriptions -->

## Version
{VERSION}

## Audience
{AUDIENCE}
<!-- Technical, end-user, both -->

## Generate Release Notes:

### Header
- Version number
- Release date
- Summary (2-3 sentences)

### What's New (Features)
- Feature descriptions (user-focused)
- Screenshots/demos if applicable
- How to use new features

### Improvements
- Performance improvements
- UX improvements
- Quality of life changes

### Bug Fixes
- Fixed issues (reference ticket numbers)
- Impact of fixes

### Breaking Changes
- What changed
- Migration guide
- Deprecation warnings

### Known Issues
- Current limitations
- Workarounds

### Dependencies
- Updated dependencies
- Security patches

### Acknowledgments
- Contributors
- Community contributions

## Output Format
```markdown
# Release {VERSION}
**Release Date**: {DATE}

## Highlights
{SUMMARY}

## New Features
...
```
```

---

## DOC-008: Onboarding Documentation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating developer onboarding guides

```markdown
Create onboarding documentation for new developers.

## Project/Team
{PROJECT_DESCRIPTION}

## Tech Stack
{TECH_STACK}

## Generate Onboarding Guide:

### Day 1: Getting Started
- [ ] Account setup
  - Required accounts
  - Access requests
  
- [ ] Development environment
  - Required software
  - Installation steps
  - Verification commands

- [ ] Repository setup
  - Clone repositories
  - Initial configuration
  - First build

### Week 1: Understanding the System
- Architecture overview
- Key components
- Data flow
- Common patterns used

### First Tasks
- Suggested starter issues
- Pair programming opportunities
- Code walkthrough schedule

### Key Resources
| Resource | Location | Description |
|----------|----------|-------------|
| Codebase | {REPO} | Main repository |
| Documentation | {DOCS} | Technical docs |
| Wiki | {WIKI} | Team knowledge base |
| Runbooks | {RUNBOOKS} | Operational procedures |

### Team Processes
- Sprint ceremonies
- Code review process
- Deployment process
- On-call rotation

### Who to Ask
| Topic | Contact |
|-------|---------|
| Architecture | {PERSON} |
| Frontend | {PERSON} |
| Backend | {PERSON} |
| DevOps | {PERSON} |

### Common Issues & Solutions
- Setup problems FAQ
- Debugging tips
- Where to find logs

### 30-60-90 Day Goals
- 30 days: {GOALS}
- 60 days: {GOALS}
- 90 days: {GOALS}

## Output
Complete onboarding guide
```

---

## DOC-009: Troubleshooting Guide
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating systematic troubleshooting docs

```markdown
Create a troubleshooting guide for this system.

## System
{SYSTEM_DESCRIPTION}

## Known Issues
{KNOWN_ISSUES}

## Generate Troubleshooting Guide:

### Diagnostic Framework

#### Information Gathering
1. Error messages
2. Logs to check
3. Metrics to review
4. Recent changes

#### Triage Questions
- When did it start?
- Who is affected?
- What changed?
- Is it reproducible?

### Issue Categories

#### {CATEGORY_1}
**Symptoms**: {SYMPTOMS}
**Possible causes**:
1. {CAUSE_1}
   - Verification: {HOW_TO_VERIFY}
   - Solution: {SOLUTION}
   
2. {CAUSE_2}
   - Verification: {HOW_TO_VERIFY}
   - Solution: {SOLUTION}

#### {CATEGORY_2}
...

### Decision Trees
```
Issue: Service unavailable
├── Can you reach the server?
│   ├── No → Check network/DNS
│   └── Yes → Check service status
│       ├── Service down → Check logs, restart
│       └── Service up → Check dependencies
```

### Log Analysis Guide
| Log Location | What to Look For | Common Patterns |
|--------------|------------------|-----------------|

### Escalation Criteria
- When to escalate
- Who to contact
- What information to provide

### Post-Incident
- Root cause analysis template
- Documentation updates needed
- Prevention measures

## Output
Complete troubleshooting guide with decision trees
```

---

## DOC-010: Data Dictionary Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating data dictionaries from schemas

```markdown
Generate a data dictionary from this schema.

## Schema
```sql
{SCHEMA}
```

## Context
- System: {SYSTEM}
- Domain: {DOMAIN}

## Generate Data Dictionary:

### Table: {TABLE_NAME}
**Description**: {DESCRIPTION}
**Owner**: {OWNER}
**Update Frequency**: {FREQUENCY}

#### Columns
| Column | Type | Nullable | Default | Description | Business Rules |
|--------|------|----------|---------|-------------|----------------|
| {COL} | {TYPE} | {NULL} | {DEFAULT} | {DESC} | {RULES} |

#### Primary Key
- Columns: {COLUMNS}
- Type: {NATURAL/SURROGATE}

#### Foreign Keys
| Column | References | On Delete | On Update |
|--------|------------|-----------|-----------|

#### Indexes
| Name | Columns | Type | Purpose |
|------|---------|------|---------|

#### Constraints
| Name | Type | Definition | Purpose |
|------|------|------------|---------|

#### Sample Data
```sql
{SAMPLE_QUERY}
```

### Relationships Diagram
```
{TABLE_A} 1--* {TABLE_B} (FK: column_name)
```

### Data Lineage
- Source: {SOURCE}
- Transformations: {TRANSFORMATIONS}
- Downstream: {CONSUMERS}

### Data Quality Rules
| Rule | Check | Threshold |
|------|-------|-----------|

## Output
Complete data dictionary document
```
