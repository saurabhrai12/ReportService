# Testing Prompts

## TEST-001: Unit Test Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Generating unit tests for code

```markdown
Generate comprehensive unit tests for this code.

## Code to Test
```{LANGUAGE}
{CODE}
```

## Testing Framework
{FRAMEWORK}
<!-- pytest, Jest, JUnit, NUnit, etc. -->

## Requirements
- Minimum coverage target: {COVERAGE_TARGET}
- Mocking approach: {MOCKING_LIBRARY}
- Test data strategy: {TEST_DATA_APPROACH}

## Generate Tests For:

### Happy Path
- Normal input scenarios
- Expected successful outcomes

### Edge Cases
- Empty inputs
- Boundary values (min, max)
- Null/None/undefined handling
- Single element collections
- Maximum size inputs

### Error Cases
- Invalid inputs
- Exception scenarios
- Timeout handling
- Resource unavailable

### Special Cases
- Concurrency (if applicable)
- Idempotency (if applicable)
- State transitions

## Output Format
```{LANGUAGE}
# Include:
# - Descriptive test names (test_should_X_when_Y)
# - Arrange-Act-Assert structure
# - Clear assertions with messages
# - Setup and teardown if needed
# - Parameterized tests for similar cases
```

## Also Provide:
1. Test coverage summary
2. Additional scenarios to consider
3. Integration test recommendations
```

---

## TEST-002: Integration Test Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating integration tests

```markdown
Generate integration tests for this component.

## Component Under Test
{COMPONENT_DESCRIPTION}

## Dependencies
{DEPENDENCIES}
<!-- Database, APIs, message queues, etc. -->

## Test Environment
- Environment: {TEST_ENVIRONMENT}
- Test doubles: {TEST_DOUBLE_STRATEGY}

## Integration Points to Test
{INTEGRATION_POINTS}

## Generate Tests For:

### API Integration
- Request/response validation
- Authentication flows
- Error handling from external services

### Database Integration
- CRUD operations
- Transaction handling
- Data integrity

### Message Queue Integration
- Message publishing
- Message consumption
- Dead letter handling

### External Service Integration
- Service availability
- Timeout handling
- Retry behavior

## Test Setup Requirements
```{LANGUAGE}
# Include:
# - Test fixtures
# - Database seeding
# - Mock service setup
# - Cleanup procedures
```

## Output
1. Integration test code
2. Test environment setup instructions
3. CI/CD configuration for running tests
4. Test data management approach
```

---

## TEST-003: API Test Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating API endpoint tests

```markdown
Generate API tests for these endpoints.

## API Specification
```yaml
{API_SPEC}
```
<!-- OpenAPI/Swagger spec or endpoint descriptions -->

## Testing Tool
{TOOL}
<!-- pytest + requests, Postman/Newman, REST Assured, etc. -->

## Generate Tests For Each Endpoint:

### Positive Tests
- Valid requests with expected responses
- Different valid input combinations
- Response schema validation

### Negative Tests
- Missing required fields
- Invalid field values
- Invalid authentication
- Rate limit testing

### Security Tests
- Authentication requirements
- Authorization (access control)
- Input validation (injection attempts)
- Sensitive data in responses

### Performance Tests
- Response time assertions
- Concurrent request handling

## Output Format
```{LANGUAGE}
# For each endpoint:
# - Test valid request/response
# - Test each error case
# - Test authentication
# - Test authorization levels
# - Schema validation
```

## Also Include:
1. Test data fixtures
2. Authentication setup
3. Environment configuration
4. CI/CD integration notes
```

---

## TEST-004: Test Data Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating realistic test data

```markdown
Generate test data for this schema.

## Schema
```
{SCHEMA}
```

## Requirements
- Number of records: {COUNT}
- Realistic data: {REALISM_REQUIREMENTS}
- Edge cases to include: {EDGE_CASES}
- Relationships: {RELATIONSHIP_REQUIREMENTS}

## Constraints
- Must not contain real PII
- Must satisfy all constraints (FK, unique, etc.)
- Must cover all enum values

## Generate:

### 1. Factory/Builder Functions
```{LANGUAGE}
# Functions to generate test data programmatically
# Support for:
# - Default values
# - Override specific fields
# - Related object creation
```

### 2. Static Test Fixtures
```json
# Representative test data sets:
# - Minimal valid record
# - Fully populated record
# - Edge case records
# - Related record sets
```

### 3. SQL Seed Data
```sql
# Database seed scripts
# Order respects foreign keys
# Includes cleanup script
```

### 4. Test Scenarios
| Scenario | Data Characteristics | Purpose |
|----------|---------------------|---------|
```

---

## TEST-005: Test Case Generation from Requirements
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating test cases from user stories

```markdown
Generate test cases from these requirements.

## Requirements/User Stories
{REQUIREMENTS}

## Acceptance Criteria
{ACCEPTANCE_CRITERIA}

## Generate Test Cases:

### Format for Each Test Case
| ID | Title | Priority | Type | Preconditions | Steps | Expected Result | Test Data |
|----|-------|----------|------|---------------|-------|-----------------|-----------|

### Categories to Cover

#### Functional Tests
- Verify each acceptance criterion
- User workflow tests
- Business rule validation

#### Boundary Tests
- Input limits
- Date ranges
- Quantity limits

#### Negative Tests
- Invalid inputs
- Unauthorized access
- System unavailable

#### Usability Tests (if UI)
- Error message clarity
- Navigation
- Accessibility

### Traceability Matrix
| Requirement ID | Test Case IDs |
|----------------|---------------|

## Output
1. Complete test case document
2. Test execution priority order
3. Automation recommendations
4. Risk-based testing focus areas
```

---

## TEST-006: SQL Query Testing
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Testing SQL queries and stored procedures

```markdown
Generate tests for this SQL query/procedure.

## SQL to Test
```sql
{SQL_CODE}
```

## Schema Context
```sql
{SCHEMA}
```

## Database Platform
{DATABASE}

## Generate:

### Test Data Setup
```sql
-- Create test scenarios
-- Include edge cases
-- Setup for each test case
```

### Test Cases

#### Correctness Tests
- Returns expected results for known input
- Handles empty result sets
- Correct aggregations
- Proper join behavior

#### Edge Cases
- NULL handling
- Empty tables
- Single row tables
- Maximum data volumes

#### Performance Tests
- Execution plan validation
- Query timing assertions
- Index usage verification

#### Data Integrity Tests
- Transaction behavior
- Constraint enforcement
- Concurrent access

### Cleanup Scripts
```sql
-- Rollback test data
-- Reset sequences
```

## Output Format
```sql
-- Test case: {description}
-- Arrange
{setup_sql}
-- Act
{query_under_test}
-- Assert
{validation_query}
-- Cleanup
{cleanup_sql}
```
```

---

## TEST-007: E2E Test Scenario Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating end-to-end test scenarios

```markdown
Generate end-to-end test scenarios for this feature.

## Feature Description
{FEATURE}

## User Flows
{USER_FLOWS}

## System Components
{COMPONENTS}

## Testing Tool
{TOOL}
<!-- Cypress, Playwright, Selenium, etc. -->

## Generate Scenarios:

### Critical Path Tests
- Main user journeys
- Core business workflows
- Revenue-impacting flows

### Alternative Paths
- Secondary workflows
- Different user types
- Feature variations

### Error Scenarios
- Network failures
- Invalid states
- Session expiration
- Concurrent users

### Cross-Browser/Device
- Browser compatibility
- Mobile responsiveness
- Different screen sizes

## Output Format
```gherkin
Feature: {feature_name}

  Background:
    Given {common_setup}

  @critical @smoke
  Scenario: {scenario_name}
    Given {precondition}
    When {action}
    Then {expected_result}
```

## Also Provide:
1. Page object structure (if applicable)
2. Test data requirements
3. Environment setup
4. CI/CD configuration
```

---

## TEST-008: Mutation Testing Gaps
**Rating:** ⭐⭐⭐ | **Use Case:** Identifying weak tests via mutation analysis

```markdown
Analyze these tests for mutation testing weaknesses.

## Production Code
```{LANGUAGE}
{PRODUCTION_CODE}
```

## Current Tests
```{LANGUAGE}
{TEST_CODE}
```

## Analyze:

### Potential Surviving Mutations
For each section of code, identify mutations that would NOT be caught:

1. **Boundary mutations**: Off-by-one changes
2. **Operator mutations**: < to <=, + to -, etc.
3. **Return value mutations**: Returning null, wrong value
4. **Exception mutations**: Removing throws
5. **Conditional mutations**: Negating conditions
6. **Constant mutations**: Changing magic numbers

### Weak Assertions
- Tests that don't verify important behavior
- Assertions that are too broad
- Missing assertions

### Recommendations
For each gap:
| Mutation | Location | Test Gap | Recommended Test |
|----------|----------|----------|------------------|

## Output
1. List of likely surviving mutations
2. Tests to add/strengthen
3. Priority based on risk
```

---

## TEST-009: Load Test Script Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating performance/load tests

```markdown
Generate load test scripts for this system.

## System Under Test
{SYSTEM_DESCRIPTION}

## Endpoints/Operations
{ENDPOINTS}

## Performance Requirements
- Target throughput: {THROUGHPUT}
- Response time SLA: {RESPONSE_TIME}
- Concurrent users: {CONCURRENT_USERS}
- Test duration: {DURATION}

## Testing Tool
{TOOL}
<!-- k6, Locust, JMeter, Gatling -->

## Generate:

### Load Test Script
```{LANGUAGE}
# Include:
# - Virtual user scenarios
# - Think time/pacing
# - Ramp-up strategy
# - Data parameterization
# - Assertions for SLAs
```

### Test Scenarios

#### Baseline Test
- Normal expected load
- Establish performance baseline

#### Stress Test
- Beyond expected load
- Find breaking point

#### Spike Test
- Sudden load increase
- Recovery behavior

#### Endurance Test
- Sustained load over time
- Memory leaks, degradation

### Monitoring Points
- Response times (p50, p95, p99)
- Error rates
- Throughput
- Resource utilization

## Output
1. Load test script code
2. Test execution instructions
3. Results analysis template
4. CI/CD integration for performance regression
```

---

## TEST-010: Test Automation Strategy
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Planning test automation approach

```markdown
Create a test automation strategy for this project.

## Project Context
{PROJECT_DESCRIPTION}

## Current Testing State
- Existing tests: {EXISTING_TESTS}
- Coverage: {CURRENT_COVERAGE}
- Pain points: {PAIN_POINTS}

## Technology Stack
{TECH_STACK}

## Generate Strategy:

### Test Pyramid
```
         /\
        /  \  E2E (5-10%)
       /----\
      /      \  Integration (20-30%)
     /--------\
    /          \  Unit (60-70%)
   /------------\
```

### Tool Recommendations
| Test Level | Tool | Rationale |
|------------|------|-----------|

### Automation Priority
1. High-value, frequently run tests
2. Regression-prone areas
3. Time-consuming manual tests
4. Data-driven test scenarios

### Implementation Roadmap
| Phase | Focus | Tests to Add | Timeline |
|-------|-------|--------------|----------|

### CI/CD Integration
- When to run which tests
- Parallelization strategy
- Failure handling
- Reporting

### Maintenance Strategy
- Test code ownership
- Review process
- Flaky test handling
- Test data management

### Metrics & KPIs
- Coverage targets
- Execution time targets
- Flaky test threshold
- Automation ROI

## Deliverables
1. Strategy document
2. Tool evaluation matrix
3. Implementation backlog
4. Team training needs
```

---

## TEST-011: Accessibility Test Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating accessibility tests

```markdown
Generate accessibility tests for this component.

## Component
{COMPONENT_CODE}

## Standards
{STANDARDS}
<!-- WCAG 2.1 AA, Section 508, etc. -->

## Testing Tool
{TOOL}
<!-- axe, Pa11y, Lighthouse, etc. -->

## Test Categories:

### Perceivable
- Alt text for images
- Video captions
- Color contrast
- Text resizing

### Operable
- Keyboard navigation
- Focus management
- Skip links
- Touch targets

### Understandable
- Labels and instructions
- Error identification
- Consistent navigation

### Robust
- Valid HTML
- ARIA usage
- Compatibility

## Output Format
```{LANGUAGE}
// Automated accessibility tests
// Manual testing checklist
// Screen reader testing script
```

## Deliverables
1. Automated test code
2. Manual test checklist
3. Common issues to check
4. Remediation guidance for failures
```

---

## TEST-012: Contract Test Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating consumer-driven contract tests

```markdown
Generate contract tests for this API integration.

## Consumer
{CONSUMER_DESCRIPTION}

## Provider API
```yaml
{API_SPEC}
```

## Interactions to Test
{INTERACTIONS}

## Contract Testing Tool
{TOOL}
<!-- Pact, Spring Cloud Contract, etc. -->

## Generate:

### Consumer Tests
```{LANGUAGE}
# What the consumer expects from the provider
# - Expected request format
# - Expected response format
# - Error scenarios
```

### Provider Verification
```{LANGUAGE}
# Provider verifies it meets consumer expectations
# - Setup test state
# - Verify against contracts
```

### Contract Scenarios
| Scenario | Request | Response | State |
|----------|---------|----------|-------|

## Output
1. Consumer contract tests
2. Provider verification tests
3. Contract broker configuration
4. CI/CD integration for contract verification
```
