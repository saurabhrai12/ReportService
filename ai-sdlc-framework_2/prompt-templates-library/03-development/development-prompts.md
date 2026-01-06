# Development Prompts

## DEV-001: Code Generation from Requirements
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Generating code from specifications

```markdown
Generate code implementation based on these requirements.

## Requirements
{REQUIREMENTS}

## Technical Context
- Language: {LANGUAGE}
- Framework: {FRAMEWORK}
- Project conventions: {CONVENTIONS}

## Existing Code Context
{RELATED_CODE}

## Constraints
- Must integrate with: {INTEGRATION_POINTS}
- Performance requirements: {PERFORMANCE}
- Error handling approach: {ERROR_HANDLING}

## Generate:
1. Implementation code following project conventions
2. Input validation
3. Error handling
4. Inline comments for complex logic
5. Type hints/annotations (if applicable)

## Output Format
- Production-ready code
- Explanation of design decisions
- Usage example
- Edge cases handled
```

---

## DEV-002: Refactoring Assistant
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Improving existing code quality

```markdown
Refactor this code to improve quality while preserving behavior.

## Code to Refactor
```{LANGUAGE}
{CODE}
```

## Concerns to Address
{SPECIFIC_CONCERNS}
<!-- Examples: reduce complexity, improve readability, fix code smells -->

## Constraints
- Must maintain backward compatibility: Yes/No
- Breaking change tolerance: {TOLERANCE}
- Performance must not degrade

## Refactoring Goals
1. [ ] Reduce cyclomatic complexity
2. [ ] Improve naming
3. [ ] Extract reusable components
4. [ ] Apply design patterns where appropriate
5. [ ] Improve testability
6. [ ] Remove code duplication

## Provide:
1. **Refactored code** with improvements applied
2. **Changes summary** - what was changed and why
3. **Before/after comparison** - key improvements
4. **Test impact** - any tests that need updating
5. **Migration notes** - if callers need updates
```

---

## DEV-003: Debug Assistance
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Troubleshooting bugs and errors

```markdown
Help debug this issue.

## Problem Description
{PROBLEM_DESCRIPTION}

## Error Message
```
{ERROR_MESSAGE}
```

## Relevant Code
```{LANGUAGE}
{CODE}
```

## What I've Tried
{ATTEMPTED_SOLUTIONS}

## Environment
- Language version: {VERSION}
- OS: {OS}
- Dependencies: {DEPENDENCIES}

## Analyze:
1. **Root cause** - What's causing the error
2. **Explanation** - Why this happens
3. **Solution** - Code fix with explanation
4. **Prevention** - How to avoid this in the future
5. **Similar issues** - Related problems to watch for
```

---

## DEV-004: Code Explanation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Understanding unfamiliar code

```markdown
Explain this code in detail.

## Code
```{LANGUAGE}
{CODE}
```

## Context
- Project type: {PROJECT_TYPE}
- This code is responsible for: {RESPONSIBILITY}

## Explain:
1. **Overview** - What does this code do at a high level?
2. **Line-by-line walkthrough** - Explain each significant section
3. **Data flow** - How data moves through the code
4. **Dependencies** - What external components does it rely on?
5. **Side effects** - What state changes occur?
6. **Edge cases** - What special cases does it handle?
7. **Potential issues** - Any concerns with this implementation?

## Target Audience
{AUDIENCE}
<!-- junior developer, senior developer, non-technical stakeholder -->
```

---

## DEV-005: Performance Optimization
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Improving code performance

```markdown
Optimize this code for performance.

## Code to Optimize
```{LANGUAGE}
{CODE}
```

## Performance Issue
- Current behavior: {CURRENT_PERFORMANCE}
- Target: {TARGET_PERFORMANCE}
- Bottleneck area: {BOTTLENECK}

## Constraints
- Memory constraints: {MEMORY}
- Must maintain readability: Yes/No
- Can use additional dependencies: Yes/No

## Analyze and Optimize:
1. **Performance analysis** - Where are the bottlenecks?
2. **Optimized code** - Improved implementation
3. **Optimizations applied**:
   - Algorithm improvements
   - Data structure changes
   - Caching opportunities
   - Parallelization potential
   - Memory optimizations
4. **Expected improvement** - Estimated performance gain
5. **Trade-offs** - What are we sacrificing for performance?
6. **Benchmarking approach** - How to verify improvement
```

---

## DEV-006: SQL Query Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Writing SQL queries from requirements

```markdown
Generate SQL query for this requirement.

## Requirement
{REQUIREMENT_DESCRIPTION}

## Database Schema
```sql
{SCHEMA}
```

## Database Platform
{DATABASE}
<!-- PostgreSQL, MySQL, Snowflake, SQL Server, etc. -->

## Query Requirements
- Expected result columns: {COLUMNS}
- Filtering criteria: {FILTERS}
- Sorting: {SORT_ORDER}
- Aggregations needed: {AGGREGATIONS}

## Generate:
1. **SQL query** - Optimized for the target platform
2. **Explanation** - How the query works
3. **Index recommendations** - Indexes that would improve performance
4. **Alternative approaches** - Other ways to achieve the same result
5. **Performance considerations** - Potential issues at scale
```

---

## DEV-007: SQL Query Optimization
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Improving slow SQL queries

```markdown
Optimize this SQL query.

## Current Query
```sql
{QUERY}
```

## Execution Plan (if available)
```
{EXECUTION_PLAN}
```

## Table Statistics
- Table sizes: {TABLE_SIZES}
- Existing indexes: {INDEXES}
- Query frequency: {FREQUENCY}

## Performance Issue
- Current execution time: {CURRENT_TIME}
- Target execution time: {TARGET_TIME}

## Provide:
1. **Optimized query** - Improved SQL
2. **Changes made**:
   - Join order optimization
   - Index utilization
   - Subquery elimination
   - Predicate pushdown
   - Aggregation improvements
3. **Index recommendations** - New indexes to create
4. **Schema recommendations** - Table changes if beneficial
5. **Expected improvement** - Estimated performance gain
```

---

## DEV-008: Stored Procedure Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating stored procedures from logic

```markdown
Generate a stored procedure for this business logic.

## Business Logic
{BUSINESS_LOGIC}

## Database Platform
{DATABASE}

## Input Parameters
{INPUT_PARAMETERS}

## Expected Output
{OUTPUT_DESCRIPTION}

## Requirements
- Transaction handling: {TRANSACTION_REQUIREMENTS}
- Error handling: {ERROR_HANDLING}
- Logging: {LOGGING_REQUIREMENTS}
- Performance: {PERFORMANCE_REQUIREMENTS}

## Generate:
```sql
-- Include:
-- - Parameter validation
-- - Transaction management
-- - Error handling with meaningful messages
-- - Logging/audit trail (if required)
-- - Comments explaining complex logic
```

## Also Provide:
1. **Usage example** - How to call the procedure
2. **Test cases** - Sample inputs and expected outputs
3. **Performance notes** - Considerations for optimization
```

---

## DEV-009: API Endpoint Implementation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Implementing REST API endpoints

```markdown
Implement this API endpoint.

## Endpoint Specification
- Method: {HTTP_METHOD}
- Path: {PATH}
- Description: {DESCRIPTION}

## Request
```json
{REQUEST_SCHEMA}
```

## Response
```json
{RESPONSE_SCHEMA}
```

## Framework
{FRAMEWORK}
<!-- FastAPI, Express, Spring Boot, etc. -->

## Business Logic
{BUSINESS_LOGIC}

## Generate:
1. **Route handler** with proper decorators/annotations
2. **Request validation** using framework conventions
3. **Business logic** implementation
4. **Response formatting**
5. **Error handling** with appropriate status codes
6. **Authentication/authorization** checks (if applicable)

## Include:
- Input validation
- Error responses for common cases (400, 401, 403, 404, 500)
- Logging
- OpenAPI/Swagger documentation (if applicable)
```

---

## DEV-010: Data Class/Model Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating data models from schemas

```markdown
Generate data models from this schema.

## Schema Definition
{SCHEMA}
<!-- JSON Schema, database schema, or description -->

## Target Language
{LANGUAGE}

## Framework (if applicable)
{FRAMEWORK}
<!-- Pydantic, TypeScript interfaces, JPA entities, etc. -->

## Requirements
- Validation rules: {VALIDATION}
- Serialization: {SERIALIZATION}
- ORM integration: {ORM}

## Generate:
1. **Data classes/models** with:
   - Type annotations
   - Validation rules
   - Default values
   - Documentation strings

2. **Related utilities**:
   - Factory methods
   - Conversion methods
   - Comparison methods

3. **Example usage**

4. **Validation rules explanation**
```

---

## DEV-011: Regex Pattern Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating and explaining regular expressions

```markdown
Create a regex pattern for this use case.

## What to Match
{MATCH_DESCRIPTION}

## Examples
Should match:
{POSITIVE_EXAMPLES}

Should NOT match:
{NEGATIVE_EXAMPLES}

## Language/Engine
{REGEX_ENGINE}
<!-- Python, JavaScript, PCRE, etc. -->

## Provide:
1. **Regex pattern** - The regular expression
2. **Explanation** - Break down each part of the pattern
3. **Test cases** - Additional test cases
4. **Edge cases** - Cases that might be tricky
5. **Performance notes** - Any backtracking concerns
6. **Alternative patterns** - Other approaches if applicable
```

---

## DEV-012: Async/Concurrent Code
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Writing async or concurrent code

```markdown
Implement concurrent/async solution for this problem.

## Problem
{PROBLEM_DESCRIPTION}

## Current Sequential Code (if refactoring)
```{LANGUAGE}
{SEQUENTIAL_CODE}
```

## Concurrency Requirements
- Type: Async I/O / Parallel processing / Both
- Language: {LANGUAGE}
- Framework: {FRAMEWORK}

## Constraints
- Max concurrent operations: {MAX_CONCURRENT}
- Resource limits: {RESOURCE_LIMITS}
- Error handling: How to handle partial failures

## Generate:
1. **Async/concurrent implementation**
2. **Explanation of approach**:
   - Why this concurrency pattern
   - How work is distributed
   - Synchronization approach
3. **Error handling** - How failures are managed
4. **Resource management** - Connection pools, semaphores, etc.
5. **Testing approach** - How to test concurrent code
6. **Common pitfalls** - Race conditions, deadlocks to avoid
```

---

## DEV-013: Migration Script Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating database migrations

```markdown
Generate database migration scripts.

## Change Required
{CHANGE_DESCRIPTION}

## Current Schema
```sql
{CURRENT_SCHEMA}
```

## Target Schema
```sql
{TARGET_SCHEMA}
```

## Database Platform
{DATABASE}

## Migration Framework
{FRAMEWORK}
<!-- Alembic, Flyway, Liquibase, Django migrations, etc. -->

## Generate:
1. **Up migration** - Apply the change
2. **Down migration** - Rollback the change
3. **Data migration** (if needed) - Transform existing data
4. **Validation queries** - Verify migration success
5. **Rollback plan** - Steps if migration fails
6. **Deployment notes**:
   - Expected downtime
   - Pre-migration steps
   - Post-migration verification
```

---

## DEV-014: Exception/Error Handling
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Implementing robust error handling

```markdown
Implement error handling for this code.

## Code
```{LANGUAGE}
{CODE}
```

## Error Scenarios to Handle
{ERROR_SCENARIOS}

## Requirements
- Logging: {LOGGING_REQUIREMENTS}
- User-facing messages: {MESSAGE_REQUIREMENTS}
- Recovery: {RECOVERY_REQUIREMENTS}

## Generate:
1. **Custom exception classes** (if needed)
2. **Try-catch/error handling blocks**
3. **Error logging** with appropriate levels
4. **User-friendly error messages**
5. **Recovery/retry logic** where applicable
6. **Error propagation strategy**

## Best Practices Applied:
- Don't catch generic exceptions
- Log with context
- Fail fast when appropriate
- Clean up resources in finally/defer
```
