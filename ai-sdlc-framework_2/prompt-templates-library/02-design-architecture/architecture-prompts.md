# Design & Architecture Prompts

## ARCH-001: System Architecture Review
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Reviewing and improving system architecture

```markdown
Review this system architecture and provide recommendations.

## Architecture Description
{ARCHITECTURE_DESCRIPTION}

## Architecture Diagram (describe or paste)
{ARCHITECTURE_DIAGRAM}

## Context
- Domain: {DOMAIN}
- Scale: {EXPECTED_SCALE}
- Team Size: {TEAM_SIZE}
- Constraints: {CONSTRAINTS}

## Review Against:

### 1. Design Principles
- Single Responsibility
- Loose Coupling
- High Cohesion
- Separation of Concerns

### 2. Quality Attributes
- **Scalability**: Can it handle 10x growth?
- **Reliability**: Single points of failure?
- **Performance**: Bottlenecks?
- **Security**: Attack surface, data protection?
- **Maintainability**: Can it be easily modified?
- **Testability**: Can components be tested in isolation?

### 3. Operational Concerns
- Deployment complexity
- Monitoring and observability
- Disaster recovery
- Cost efficiency

### 4. Industry Patterns
- Is it following established patterns appropriately?
- Anti-patterns present?

## Output
1. **Strengths**: What's working well
2. **Concerns**: Issues identified (prioritized by severity)
3. **Recommendations**: Specific improvements with rationale
4. **Trade-offs**: If changes made, what are the trade-offs
5. **Questions**: Areas needing clarification
```

---

## ARCH-002: Microservices Decomposition
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Breaking down monolith or designing microservices

```markdown
Recommend microservices decomposition for this system.

## Current System
{SYSTEM_DESCRIPTION}

## Domain Model
{DOMAIN_ENTITIES}

## Business Capabilities
{BUSINESS_CAPABILITIES}

## Constraints
- Team structure: {TEAM_STRUCTURE}
- Deployment: {DEPLOYMENT_CONSTRAINTS}
- Data consistency requirements: {CONSISTENCY_REQUIREMENTS}

## Provide:

### 1. Proposed Services
For each service:
- Name and responsibility
- Bounded context
- Data it owns
- APIs it exposes
- Dependencies on other services

### 2. Service Boundaries Rationale
- Why these boundaries?
- Domain-driven design alignment
- Team ownership mapping

### 3. Data Strategy
- Which service owns which data?
- How to handle shared data needs?
- Event-driven vs synchronous communication

### 4. Migration Path
- Recommended decomposition order
- Strangler fig pattern opportunities
- Risk mitigation strategies

### 5. Concerns
- Services that might be too fine-grained
- Services that might be too coarse
- Potential distributed system challenges

## Anti-patterns to Avoid
- Distributed monolith
- Chatty services
- Shared databases
- Circular dependencies
```

---

## ARCH-003: Database Schema Design
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Designing database schema from requirements

```markdown
Design a database schema for this system.

## Requirements
{REQUIREMENTS}

## Entities and Relationships
{ENTITIES}

## Target Database
{DATABASE_TYPE}
<!-- PostgreSQL, MySQL, Snowflake, MongoDB, etc. -->

## Scale Expectations
- Records: {RECORD_VOLUMES}
- Read/Write ratio: {READ_WRITE_RATIO}
- Growth rate: {GROWTH_RATE}

## Provide:

### 1. Schema Design
```sql
-- Include:
-- - Table definitions with appropriate data types
-- - Primary keys and foreign keys
-- - Indexes for common query patterns
-- - Constraints (unique, check, not null)
```

### 2. Design Decisions
For each significant decision:
- What was decided
- Alternatives considered
- Rationale for choice

### 3. Normalization Assessment
- Current normal form
- Denormalization decisions (if any) with rationale

### 4. Query Patterns
Common queries this schema optimizes for:
- Query description
- Expected performance
- Index support

### 5. Data Integrity
- Referential integrity approach
- Soft delete vs hard delete strategy
- Audit trail approach

### 6. Future Considerations
- How schema handles expected changes
- Migration strategy for schema evolution
```

---

## ARCH-004: API Design Review
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Reviewing REST/GraphQL API design

```markdown
Review this API design and provide recommendations.

## API Specification
{API_SPEC}
<!-- OpenAPI/Swagger, GraphQL schema, or endpoint descriptions -->

## Context
- API Type: REST / GraphQL / gRPC
- Consumers: {API_CONSUMERS}
- Authentication: {AUTH_METHOD}

## Review Against:

### 1. RESTful Principles (if REST)
- Resource naming conventions
- HTTP method usage
- Status code appropriateness
- HATEOAS compliance (if applicable)

### 2. Consistency
- Naming conventions
- Request/response formats
- Error handling patterns
- Pagination approach

### 3. Security
- Authentication mechanism
- Authorization model
- Input validation
- Rate limiting
- Sensitive data exposure

### 4. Usability
- Developer experience
- Documentation completeness
- Discoverability
- Versioning strategy

### 5. Performance
- Payload sizes
- N+1 query potential
- Caching opportunities
- Batch operation support

## Output
1. **Issues**: Problems found (Critical/Major/Minor)
2. **Recommendations**: Specific improvements
3. **Best Practices**: Patterns to adopt
4. **Breaking Changes**: If recommendations require breaking changes, how to handle
```

---

## ARCH-005: Event-Driven Architecture Design
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Designing event-driven systems

```markdown
Design an event-driven architecture for this system.

## Business Requirements
{REQUIREMENTS}

## Current Architecture
{CURRENT_STATE}

## Event Sources
{EVENT_SOURCES}

## Consumers
{EVENT_CONSUMERS}

## Provide:

### 1. Event Catalog
For each event:
```yaml
event_name: OrderPlaced
description: Triggered when customer completes checkout
producer: order-service
schema:
  order_id: string (UUID)
  customer_id: string (UUID)
  items: array
  total_amount: decimal
  timestamp: ISO8601
consumers:
  - inventory-service (update stock)
  - notification-service (send confirmation)
  - analytics-service (track metrics)
```

### 2. Event Flow Diagrams
- Producer → Broker → Consumer flows
- Saga/choreography patterns if applicable

### 3. Infrastructure Recommendations
- Message broker choice (Kafka, RabbitMQ, SNS/SQS, EventBridge)
- Partitioning strategy
- Retention policies

### 4. Reliability Patterns
- At-least-once vs exactly-once delivery
- Idempotency approach
- Dead letter queue handling
- Replay capability

### 5. Monitoring Strategy
- Key metrics to track
- Alerting thresholds
- Tracing approach

### 6. Schema Evolution
- Versioning strategy
- Backward compatibility approach
```

---

## ARCH-006: Cloud Architecture Design
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Designing AWS/Azure/GCP architecture

```markdown
Design a cloud architecture for this system.

## Requirements
{REQUIREMENTS}

## Cloud Provider
{CLOUD_PROVIDER}
<!-- AWS, Azure, GCP -->

## Constraints
- Budget: {BUDGET}
- Compliance: {COMPLIANCE_REQUIREMENTS}
- Team expertise: {TEAM_SKILLS}

## Workload Characteristics
- Traffic patterns: {TRAFFIC_PATTERNS}
- Data volume: {DATA_VOLUME}
- Availability requirements: {AVAILABILITY_SLA}

## Provide:

### 1. Architecture Diagram
ASCII or description of:
- Compute components
- Data stores
- Networking
- Security boundaries

### 2. Service Selection
| Component | Service Choice | Rationale | Alternatives Considered |
|-----------|---------------|-----------|------------------------|

### 3. Networking Design
- VPC/VNet structure
- Subnet strategy
- Security groups/NSGs
- Load balancing approach

### 4. Security Architecture
- IAM structure
- Encryption (at rest, in transit)
- Secrets management
- Network security

### 5. Cost Estimate
- Monthly cost breakdown by service
- Cost optimization recommendations
- Reserved vs on-demand strategy

### 6. Disaster Recovery
- RPO/RTO targets
- Backup strategy
- Multi-region approach (if needed)

### 7. IaC Approach
- Recommended IaC tool
- Module structure
- State management
```

---

## ARCH-007: Technical Debt Assessment
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Evaluating and prioritizing technical debt

```markdown
Assess technical debt in this system and prioritize remediation.

## System Overview
{SYSTEM_DESCRIPTION}

## Known Issues
{KNOWN_ISSUES}

## Codebase Metrics (if available)
- Test coverage: {COVERAGE}
- Cyclomatic complexity: {COMPLEXITY}
- Dependency age: {DEPENDENCY_INFO}
- Code duplication: {DUPLICATION}

## Assess:

### 1. Debt Inventory
For each debt item:
| ID | Category | Description | Impact | Effort | Priority |
|----|----------|-------------|--------|--------|----------|

Categories:
- Code quality
- Architecture
- Dependencies
- Documentation
- Testing
- Infrastructure
- Security

### 2. Impact Analysis
For high-priority items:
- Business impact
- Developer productivity impact
- Risk if not addressed

### 3. Remediation Roadmap
- Quick wins (high impact, low effort)
- Strategic investments (high impact, high effort)
- Housekeeping (low impact, low effort)
- Deprioritize (low impact, high effort)

### 4. Prevention Strategies
- Processes to prevent debt accumulation
- Metrics to track debt levels
- Team practices to adopt

### 5. Investment Recommendation
- Suggested % of sprint capacity for debt reduction
- Milestone targets
```

---

## ARCH-008: Data Pipeline Architecture
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Designing ETL/ELT data pipelines

```markdown
Design a data pipeline architecture for this use case.

## Requirements
{DATA_REQUIREMENTS}

## Source Systems
{SOURCE_SYSTEMS}
<!-- Include: system type, data format, volume, frequency -->

## Target Systems
{TARGET_SYSTEMS}
<!-- Data warehouse, data lake, operational systems -->

## Current State (if migration)
{CURRENT_PIPELINE}

## Provide:

### 1. Pipeline Architecture
```
[Sources] → [Ingestion] → [Processing] → [Storage] → [Serving]
```
Detail each layer:
- Components and tools
- Data flow
- Transformation logic

### 2. Technology Stack
| Layer | Technology | Rationale |
|-------|------------|-----------|
| Ingestion | | |
| Processing | | |
| Orchestration | | |
| Storage | | |
| Monitoring | | |

### 3. Data Modeling
- Source to target mapping
- Transformation rules
- Data quality rules
- Schema design for target

### 4. Orchestration Design
- Job dependencies
- Scheduling strategy
- Failure handling
- Retry policies

### 5. Data Quality Framework
- Validation rules
- Quality metrics
- Alerting thresholds
- Remediation workflows

### 6. Performance Considerations
- Batch vs streaming decisions
- Partitioning strategy
- Incremental processing approach
- Parallelization opportunities

### 7. Operational Concerns
- Monitoring dashboards
- Alerting strategy
- Runbooks for common issues
- SLA definitions
```

---

## ARCH-009: Security Architecture Review
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Security-focused architecture review

```markdown
Perform a security architecture review.

## System Architecture
{ARCHITECTURE}

## Data Classification
{DATA_TYPES}
<!-- What sensitive data is handled -->

## Compliance Requirements
{COMPLIANCE}

## Review:

### 1. Authentication & Authorization
- Identity provider integration
- MFA implementation
- Session management
- API authentication
- Service-to-service auth

### 2. Data Protection
- Encryption at rest
- Encryption in transit
- Key management
- Data masking/tokenization
- PII handling

### 3. Network Security
- Network segmentation
- Firewall rules
- WAF configuration
- DDoS protection
- Private endpoints

### 4. Application Security
- Input validation
- Output encoding
- Injection prevention
- CSRF/XSS protection
- Secrets management

### 5. Logging & Monitoring
- Security event logging
- Audit trails
- SIEM integration
- Alerting rules
- Incident response

### 6. Vulnerability Management
- Dependency scanning
- Container scanning
- Infrastructure scanning
- Penetration testing

## Output
1. **Findings**: Issues by severity (Critical/High/Medium/Low)
2. **Recommendations**: Remediation steps
3. **Quick Wins**: Low-effort, high-impact improvements
4. **Roadmap**: Prioritized security improvements
```
