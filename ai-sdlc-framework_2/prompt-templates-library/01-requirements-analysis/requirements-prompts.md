# Requirements Analysis Prompts

## REQ-001: Extract Requirements from Business Document
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Converting business documents to structured requirements

```markdown
Analyze this business document and extract structured requirements.

## Document
{BUSINESS_DOCUMENT}

## Output Format
For each requirement identified, provide:
1. **ID**: REQ-XXX
2. **Title**: Brief descriptive title
3. **Description**: Detailed requirement description
4. **Type**: Functional | Non-Functional | Constraint
5. **Priority**: Must Have | Should Have | Could Have | Won't Have
6. **Acceptance Criteria**: Testable conditions for completion
7. **Dependencies**: Related requirements
8. **Ambiguities**: Any unclear aspects needing clarification

## Additional Instructions
- Flag any conflicting requirements
- Identify implicit requirements not explicitly stated
- Note any missing information that should be clarified with stakeholders
```

---

## REQ-002: Generate User Stories from Requirements
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Converting requirements to agile user stories

```markdown
Convert these requirements into user stories following the standard format.

## Requirements
{REQUIREMENTS_LIST}

## Context
- Product: {PRODUCT_NAME}
- Target Users: {USER_PERSONAS}
- Sprint Goal: {SPRINT_GOAL}

## For Each User Story, Provide:
1. **Story**: As a [user type], I want [goal] so that [benefit]
2. **Acceptance Criteria**: Given/When/Then format (minimum 3 criteria)
3. **Story Points**: Estimate (1, 2, 3, 5, 8, 13)
4. **Technical Notes**: Implementation considerations
5. **Dependencies**: Other stories or external dependencies
6. **Test Scenarios**: High-level test cases

## Constraints
- Each story should be completable within one sprint
- Stories should be independent where possible
- Include edge cases in acceptance criteria
```

---

## REQ-003: Requirements Gap Analysis
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Identifying missing or incomplete requirements

```markdown
Perform a gap analysis on these requirements for a {SYSTEM_TYPE} system.

## Current Requirements
{REQUIREMENTS}

## System Context
- Domain: {DOMAIN}
- Users: {USER_TYPES}
- Integrations: {EXTERNAL_SYSTEMS}
- Compliance: {COMPLIANCE_REQUIREMENTS}

## Analyze For:
1. **Missing Functional Requirements**
   - Core functionality gaps
   - Edge cases not addressed
   - User journey gaps

2. **Missing Non-Functional Requirements**
   - Performance (response time, throughput)
   - Scalability (users, data volume)
   - Security (authentication, authorization, data protection)
   - Availability (uptime, disaster recovery)
   - Maintainability (logging, monitoring, updates)

3. **Integration Gaps**
   - API contracts undefined
   - Data flow unclear
   - Error handling between systems

4. **Compliance Gaps**
   - Regulatory requirements missing
   - Audit trail requirements
   - Data retention policies

## Output
For each gap:
- Description of what's missing
- Why it matters
- Suggested requirement to add
- Priority recommendation
```

---

## REQ-004: Impact Analysis for Requirement Change
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Assessing impact of requirement changes

```markdown
Analyze the impact of this requirement change on the existing system.

## Proposed Change
{CHANGE_DESCRIPTION}

## Current System
- Architecture: {ARCHITECTURE_SUMMARY}
- Affected Components: {COMPONENT_LIST}
- Current Behavior: {CURRENT_BEHAVIOR}

## Existing Requirements
{RELATED_REQUIREMENTS}

## Analyze:
1. **Direct Impact**
   - Components requiring modification
   - Database schema changes
   - API contract changes
   - UI changes

2. **Indirect Impact**
   - Downstream systems affected
   - Reporting/analytics impact
   - Performance implications
   - Security considerations

3. **Testing Impact**
   - Test cases requiring updates
   - Regression testing scope
   - New test scenarios needed

4. **Effort Estimate**
   - Development effort (story points or hours)
   - Testing effort
   - Documentation updates
   - Deployment considerations

5. **Risk Assessment**
   - Technical risks
   - Business risks
   - Mitigation strategies

## Recommendation
- Proceed / Proceed with modifications / Defer / Reject
- Rationale
```

---

## REQ-005: Stakeholder Questions Generator
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Preparing for requirements gathering sessions

```markdown
Generate clarifying questions for a requirements gathering session.

## Project Overview
{PROJECT_DESCRIPTION}

## Initial Information Available
{KNOWN_INFORMATION}

## Stakeholder Role
{STAKEHOLDER_ROLE}

## Generate Questions For:

1. **Business Context**
   - Business drivers and goals
   - Success metrics
   - Timeline and constraints

2. **User Needs**
   - Who are the users?
   - What problems are they solving?
   - Current pain points

3. **Functional Requirements**
   - Core workflows
   - Data requirements
   - Business rules

4. **Non-Functional Requirements**
   - Performance expectations
   - Security requirements
   - Compliance needs

5. **Integration Requirements**
   - Existing systems to integrate
   - Data sources and destinations
   - Third-party dependencies

6. **Constraints and Assumptions**
   - Budget limitations
   - Technology constraints
   - Organizational constraints

## Format
For each question:
- The question itself
- Why this information is important
- Possible follow-up questions based on likely answers
```

---

## REQ-006: Requirements Validation Checklist
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Validating requirements quality

```markdown
Validate these requirements against quality criteria.

## Requirements to Validate
{REQUIREMENTS}

## Validate Each Requirement Against:

### SMART Criteria
- [ ] **Specific**: Is it clear and unambiguous?
- [ ] **Measurable**: Can completion be objectively verified?
- [ ] **Achievable**: Is it technically feasible?
- [ ] **Relevant**: Does it align with project goals?
- [ ] **Time-bound**: Is there a clear timeline?

### Quality Attributes
- [ ] **Complete**: All necessary information included?
- [ ] **Consistent**: No conflicts with other requirements?
- [ ] **Testable**: Can acceptance be verified?
- [ ] **Traceable**: Can be linked to business need?
- [ ] **Prioritized**: Clear importance level?

### Common Issues to Flag
- Vague terms: "fast", "user-friendly", "secure", "efficient"
- Missing quantities: "support many users" → how many?
- Assumed knowledge: Technical jargon without definition
- Gold plating: Nice-to-haves mixed with must-haves
- Implementation details: "Use React" in business requirements

## Output
For each requirement:
- Pass/Fail status
- Issues identified
- Suggested improvements
- Rewritten requirement (if needed)
```

---

## REQ-007: Compliance Requirements Mapper
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Mapping features to compliance requirements

```markdown
Map system features to compliance requirements.

## System Features
{FEATURE_LIST}

## Applicable Regulations
{REGULATIONS} 
<!-- Examples: GDPR, HIPAA, SOC2, PCI-DSS, SOX -->

## For Each Feature, Identify:

1. **Applicable Compliance Controls**
   - Regulation/Standard
   - Specific control or article
   - Requirement description

2. **Current Implementation Status**
   - Fully Compliant / Partially Compliant / Not Compliant / Not Applicable

3. **Gaps**
   - What's missing
   - Risk level (High/Medium/Low)

4. **Remediation Requirements**
   - Technical changes needed
   - Process changes needed
   - Documentation required

5. **Evidence Requirements**
   - What audit evidence is needed
   - How to collect/store evidence
   - Retention period

## Output Format
| Feature | Regulation | Control | Status | Gap | Remediation | Evidence |
|---------|------------|---------|--------|-----|-------------|----------|
```

---

## REQ-008: User Persona Generator
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating user personas from research data

```markdown
Create detailed user personas based on this research data.

## Research Data
{USER_RESEARCH_DATA}
<!-- Include: interview notes, survey results, analytics, support tickets -->

## Product Context
- Product: {PRODUCT_NAME}
- Domain: {DOMAIN}
- Key Features: {FEATURES}

## For Each Persona, Generate:

1. **Demographics**
   - Name (fictional)
   - Role/Title
   - Industry
   - Experience level

2. **Goals**
   - Primary goals
   - Secondary goals
   - Success metrics from their perspective

3. **Pain Points**
   - Current frustrations
   - Workarounds they use
   - Time/money costs of current state

4. **Behaviors**
   - How they work
   - Tools they use
   - Decision-making process

5. **Technical Profile**
   - Tech savviness
   - Devices used
   - Accessibility needs

6. **Quotes**
   - Representative quotes capturing their voice

7. **Scenarios**
   - 2-3 typical usage scenarios
   - Edge case scenarios

## Deliverable
Create 3-5 distinct personas covering the primary user segments.
```
