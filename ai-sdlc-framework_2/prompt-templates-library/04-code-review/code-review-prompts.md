# Code Review Prompts

## CR-001: Comprehensive Code Review
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Thorough review of code changes

```markdown
Perform a comprehensive code review on this code.

## Code to Review
```{LANGUAGE}
{CODE}
```

## Context
- Purpose: {PURPOSE}
- Related ticket: {TICKET_ID}
- Author experience level: {EXPERIENCE_LEVEL}

## Review Criteria

### 1. Correctness
- Does the code do what it's supposed to do?
- Are edge cases handled?
- Is the logic sound?

### 2. Security
- Input validation
- SQL injection risks
- XSS vulnerabilities
- Authentication/authorization
- Sensitive data handling

### 3. Performance
- Algorithm efficiency
- Database query optimization
- Memory usage
- Unnecessary computations

### 4. Maintainability
- Code readability
- Naming conventions
- Code organization
- DRY principle adherence
- SOLID principles

### 5. Testing
- Test coverage
- Test quality
- Edge case testing

### 6. Documentation
- Code comments (where needed)
- API documentation
- Complex logic explanations

## Output Format
For each finding:
- **Location**: File and line number/section
- **Severity**: Critical | Major | Minor | Suggestion
- **Category**: Security | Performance | Maintainability | Bug | Style
- **Issue**: Description of the problem
- **Recommendation**: How to fix it
- **Code example**: If applicable
```

---

## CR-002: Security-Focused Code Review
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Security audit of code changes

```markdown
Perform a security-focused code review.

## Code to Review
```{LANGUAGE}
{CODE}
```

## Application Context
- Type: {APP_TYPE} (web, API, mobile, etc.)
- Authentication: {AUTH_METHOD}
- Data sensitivity: {DATA_SENSITIVITY}

## Check For:

### OWASP Top 10
1. **Injection** (SQL, NoSQL, OS, LDAP)
2. **Broken Authentication**
3. **Sensitive Data Exposure**
4. **XML External Entities (XXE)**
5. **Broken Access Control**
6. **Security Misconfiguration**
7. **Cross-Site Scripting (XSS)**
8. **Insecure Deserialization**
9. **Using Components with Known Vulnerabilities**
10. **Insufficient Logging & Monitoring**

### Additional Checks
- Hardcoded secrets or credentials
- Insecure cryptography
- Race conditions
- Path traversal
- SSRF vulnerabilities
- Insecure direct object references

## Output Format
| Severity | Vulnerability | Location | Description | Remediation | CWE ID |
|----------|--------------|----------|-------------|-------------|--------|

Include code examples for fixes.
```

---

## CR-003: Performance Code Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Performance-focused code analysis

```markdown
Review this code for performance issues.

## Code to Review
```{LANGUAGE}
{CODE}
```

## Context
- Expected load: {EXPECTED_LOAD}
- Current performance: {CURRENT_METRICS}
- Performance requirements: {REQUIREMENTS}

## Analyze:

### Algorithm Efficiency
- Time complexity analysis
- Space complexity analysis
- Better algorithm alternatives

### Database Operations
- N+1 query problems
- Missing indexes
- Inefficient queries
- Connection handling

### Memory Management
- Memory leaks
- Large object allocations
- Caching opportunities
- Object lifecycle

### I/O Operations
- Blocking operations
- Connection pooling
- Batch processing opportunities
- Streaming vs buffering

### Concurrency
- Thread safety issues
- Lock contention
- Async opportunities
- Parallelization potential

## Output
For each issue:
- **Issue**: Description
- **Impact**: Estimated performance impact
- **Current complexity**: O(?)
- **Recommended fix**: Solution
- **Expected improvement**: Estimated gain
```

---

## CR-004: Pull Request Review Summary
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Generating PR review summary

```markdown
Generate a pull request review summary.

## PR Description
{PR_DESCRIPTION}

## Files Changed
{FILES_CHANGED}

## Code Diff
```diff
{CODE_DIFF}
```

## Generate:

### 1. Change Summary
- What this PR does (2-3 sentences)
- Key changes made

### 2. Review Findings

#### Approved Items ✅
- What looks good

#### Requested Changes 🔴
- Critical issues that must be fixed

#### Suggestions 💡
- Optional improvements

### 3. Testing Recommendations
- What should be tested
- Suggested test cases
- Regression concerns

### 4. Review Decision
- **Approve**: Ready to merge
- **Request Changes**: Issues must be addressed
- **Comment**: Questions or discussion needed

### 5. Follow-up Items
- Technical debt created
- Documentation needed
- Future improvements to consider
```

---

## CR-005: Code Style Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Style and convention compliance

```markdown
Review this code for style and convention compliance.

## Code to Review
```{LANGUAGE}
{CODE}
```

## Style Guide
{STYLE_GUIDE_REFERENCE}
<!-- PEP 8, Airbnb JS, Google Java, or custom -->

## Check:

### Naming Conventions
- Variable names (clarity, case style)
- Function/method names (verb phrases, clarity)
- Class names (noun phrases, PascalCase)
- Constants (UPPER_SNAKE_CASE)

### Code Organization
- File structure
- Import organization
- Function length
- Class organization

### Formatting
- Indentation
- Line length
- Whitespace usage
- Bracket placement

### Documentation
- Function docstrings
- Class docstrings
- Inline comments (meaningful, not redundant)

### Best Practices
- Magic numbers/strings
- Dead code
- TODO/FIXME comments
- Consistent patterns

## Output
| Line | Issue | Rule | Suggestion |
|------|-------|------|------------|
```

---

## CR-006: Test Code Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Reviewing test quality

```markdown
Review these tests for quality and coverage.

## Test Code
```{LANGUAGE}
{TEST_CODE}
```

## Code Being Tested
```{LANGUAGE}
{PRODUCTION_CODE}
```

## Evaluate:

### Test Coverage
- Are all public methods tested?
- Are edge cases covered?
- Are error conditions tested?
- Missing test scenarios

### Test Quality
- Test isolation (no dependencies between tests)
- Proper assertions
- Clear test names (describe what is tested)
- Arrange-Act-Assert pattern
- No logic in tests

### Test Maintainability
- DRY in test setup
- Appropriate use of fixtures/mocks
- Test data management
- Readability

### Test Reliability
- Flaky test potential
- Time-dependent tests
- External dependency handling
- Deterministic behavior

## Output
1. **Coverage gaps**: Missing test cases
2. **Quality issues**: Problems with existing tests
3. **Suggested tests**: Additional tests to write
4. **Refactoring suggestions**: How to improve test code
```

---

## CR-007: API Contract Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Reviewing API changes for compatibility

```markdown
Review this API change for backward compatibility.

## Current API
```
{CURRENT_API}
```

## Proposed API
```
{PROPOSED_API}
```

## API Consumers
{CONSUMERS}

## Analyze:

### Breaking Changes
- Removed endpoints
- Changed request schemas
- Changed response schemas
- Changed authentication
- Changed behavior

### Non-Breaking Changes
- New endpoints
- New optional fields
- Additive changes

### Deprecation Concerns
- Fields being removed
- Endpoints being removed
- Migration path for consumers

## Output
1. **Breaking changes**: List with impact assessment
2. **Migration requirements**: What consumers must do
3. **Versioning recommendation**: How to handle the change
4. **Communication plan**: What to tell API consumers
5. **Rollback plan**: How to revert if issues arise
```

---

## CR-008: Database Migration Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Reviewing database schema changes

```markdown
Review this database migration.

## Migration Script
```sql
{MIGRATION}
```

## Current Schema
```sql
{CURRENT_SCHEMA}
```

## Review For:

### Safety
- Data loss risk
- Locking concerns
- Transaction handling
- Rollback capability

### Performance
- Table locking duration
- Index creation impact
- Data copy operations
- Expected execution time

### Compatibility
- Application compatibility
- Query compatibility
- ORM compatibility

### Data Integrity
- Constraint changes
- Default value handling
- NOT NULL additions
- Foreign key implications

## Output
1. **Risk assessment**: High/Medium/Low with explanation
2. **Deployment recommendations**: 
   - Maintenance window needed?
   - Steps to execute
   - Monitoring during migration
3. **Rollback script**: SQL to undo changes
4. **Testing recommendations**: How to verify success
```

---

## CR-009: Infrastructure Code Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Reviewing Terraform/CloudFormation/etc.

```markdown
Review this infrastructure code.

## IaC Code
```{LANGUAGE}
{IAC_CODE}
```
<!-- Terraform, CloudFormation, Pulumi, etc. -->

## Context
- Environment: {ENVIRONMENT}
- Cloud provider: {PROVIDER}
- Compliance requirements: {COMPLIANCE}

## Review For:

### Security
- IAM permissions (least privilege)
- Network security (security groups, NACLs)
- Encryption settings
- Public exposure
- Secrets management

### Cost
- Instance sizing
- Resource over-provisioning
- Missing cost tags
- Reserved capacity opportunities

### Reliability
- Multi-AZ deployment
- Auto-scaling configuration
- Backup configuration
- Disaster recovery

### Maintainability
- Resource naming conventions
- Tagging strategy
- Module organization
- Variable usage
- State management

### Best Practices
- Provider version pinning
- Resource dependencies
- Lifecycle rules
- Drift detection

## Output
| Category | Issue | Severity | Recommendation |
|----------|-------|----------|----------------|
```

---

## CR-010: Dependency Update Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Reviewing dependency version updates

```markdown
Review these dependency updates.

## Dependency Changes
```
{DEPENDENCY_DIFF}
```
<!-- package.json diff, requirements.txt diff, etc. -->

## Analyze For Each Update:

### Changelog Review
- Breaking changes in new version
- Security fixes included
- New features added
- Deprecations

### Compatibility
- Node/Python/Java version requirements
- Peer dependency conflicts
- Integration compatibility

### Security
- Known vulnerabilities in new version
- CVEs fixed by update
- Security advisories

### Testing Impact
- Tests that might be affected
- New test requirements
- Integration test needs

## Output
| Package | Old | New | Risk | Breaking Changes | Notes |
|---------|-----|-----|------|------------------|-------|

### Recommendations
1. **Approve**: Safe to update
2. **Caution**: Update with additional testing
3. **Block**: Do not update (with rationale)
```
