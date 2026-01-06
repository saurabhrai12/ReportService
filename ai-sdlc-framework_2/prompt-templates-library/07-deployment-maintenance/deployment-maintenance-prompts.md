# Deployment & Maintenance Prompts

## DEPLOY-001: CI/CD Pipeline Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating CI/CD pipeline configurations

```markdown
Generate a CI/CD pipeline for this project.

## Project Details
- Language: {LANGUAGE}
- Framework: {FRAMEWORK}
- Deployment target: {TARGET}

## Pipeline Platform
{PLATFORM}
<!-- GitHub Actions, GitLab CI, Jenkins, Azure DevOps -->

## Requirements
- Build steps: {BUILD_STEPS}
- Test requirements: {TEST_REQUIREMENTS}
- Deployment strategy: {STRATEGY}
- Environments: {ENVIRONMENTS}

## Generate Pipeline With:

### Stages
1. **Build**
   - Dependency installation
   - Compilation/transpilation
   - Asset generation

2. **Test**
   - Unit tests
   - Integration tests
   - Code quality checks
   - Security scans

3. **Deploy to Dev**
   - Automatic on merge to develop

4. **Deploy to Staging**
   - Automatic on merge to main
   - Smoke tests

5. **Deploy to Production**
   - Manual approval
   - Canary/blue-green deployment
   - Health checks

### Additional Features
- Caching strategy
- Parallel execution
- Artifact management
- Secret handling
- Notifications

## Output
```yaml
# Complete pipeline configuration
```

## Also Provide:
1. Required secrets/variables
2. Setup instructions
3. Troubleshooting guide
```

---

## DEPLOY-002: Kubernetes Manifest Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating K8s deployment configurations

```markdown
Generate Kubernetes manifests for this application.

## Application
- Name: {APP_NAME}
- Image: {CONTAINER_IMAGE}
- Port: {PORT}

## Requirements
- Replicas: {REPLICAS}
- Resources: {RESOURCE_REQUIREMENTS}
- Environment: {ENVIRONMENT}
- Config/Secrets: {CONFIG_REQUIREMENTS}

## Generate Manifests:

### Deployment
```yaml
# Include:
# - Resource limits/requests
# - Health checks (liveness, readiness)
# - Rolling update strategy
# - Environment variables
```

### Service
```yaml
# ClusterIP/LoadBalancer/NodePort
```

### ConfigMap
```yaml
# Non-sensitive configuration
```

### Secret
```yaml
# Sensitive configuration (placeholder values)
```

### HPA (if needed)
```yaml
# Autoscaling configuration
```

### Ingress (if needed)
```yaml
# External access configuration
```

### Network Policy
```yaml
# Network security rules
```

## Also Provide:
1. Kustomize overlays for different environments
2. Helm chart structure (if preferred)
3. Deployment checklist
```

---

## DEPLOY-003: Infrastructure as Code Generation
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating Terraform/CloudFormation

```markdown
Generate infrastructure as code for this architecture.

## Architecture
{ARCHITECTURE_DESCRIPTION}

## Cloud Provider
{PROVIDER}

## IaC Tool
{TOOL}
<!-- Terraform, CloudFormation, Pulumi, CDK -->

## Requirements
- Environment: {ENVIRONMENT}
- Region: {REGION}
- Compliance: {COMPLIANCE}
- Budget: {BUDGET}

## Generate:

### Module Structure
```
modules/
├── networking/
├── compute/
├── database/
├── security/
└── monitoring/
```

### Resources
```hcl
# Include:
# - VPC/networking
# - Compute resources
# - Database
# - Storage
# - IAM/security
# - Monitoring
```

### Variables
```hcl
# Parameterized inputs
```

### Outputs
```hcl
# Useful outputs for other modules
```

### State Configuration
```hcl
# Remote state backend
```

## Also Provide:
1. Module documentation
2. Variable descriptions
3. Example tfvars for each environment
4. CI/CD integration for IaC
```

---

## DEPLOY-004: Deployment Checklist Generation
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Creating deployment checklists

```markdown
Generate a deployment checklist for this release.

## Release Information
- Version: {VERSION}
- Changes: {CHANGES}
- Risk level: {RISK}

## Environment
{ENVIRONMENT}

## Generate Checklist:

### Pre-Deployment
- [ ] Code changes reviewed and approved
- [ ] All tests passing
- [ ] Release notes prepared
- [ ] Stakeholders notified
- [ ] Rollback plan documented
- [ ] Database migrations tested
- [ ] Feature flags configured
- [ ] Monitoring dashboards ready

### Deployment
- [ ] Take database backup
- [ ] Enable maintenance mode (if needed)
- [ ] Apply database migrations
- [ ] Deploy application
- [ ] Verify health checks
- [ ] Disable maintenance mode

### Post-Deployment
- [ ] Smoke tests passing
- [ ] Monitoring shows normal metrics
- [ ] No error rate increase
- [ ] Performance within SLA
- [ ] Feature verification complete
- [ ] Stakeholders updated

### Rollback Triggers
- Error rate > {THRESHOLD}
- Response time > {THRESHOLD}
- Critical functionality broken
- Data corruption detected

### Rollback Procedure
1. [ ] Announce rollback
2. [ ] Revert application
3. [ ] Revert database (if applicable)
4. [ ] Verify rollback successful
5. [ ] Post-mortem scheduled

## Sign-offs
| Role | Name | Sign-off |
|------|------|----------|
| Dev Lead | | |
| QA Lead | | |
| Ops | | |
```

---

## MAINT-001: Incident Analysis
**Rating:** ⭐⭐⭐⭐⭐ | **Use Case:** Analyzing production incidents

```markdown
Analyze this production incident.

## Incident Information
- Severity: {SEVERITY}
- Duration: {DURATION}
- Impact: {IMPACT}

## Timeline
{TIMELINE}

## Error Logs
```
{LOGS}
```

## Metrics (describe or paste)
{METRICS}

## Analyze:

### 1. What Happened
- Sequence of events
- Root cause identification
- Contributing factors

### 2. Impact Assessment
- Users affected
- Business impact
- Data impact

### 3. Resolution
- Actions taken
- What worked
- What didn't work

### 4. Root Cause Analysis
- 5 Whys analysis
- Fishbone diagram factors
- Systemic issues identified

### 5. Prevention Recommendations
| Recommendation | Priority | Effort | Impact |
|----------------|----------|--------|--------|

### 6. Monitoring Gaps
- What should have alerted but didn't
- New alerts to add

### 7. Process Improvements
- Communication gaps
- Response time improvements
- Documentation needs

## Output
Complete incident post-mortem document
```

---

## MAINT-002: Log Analysis
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Analyzing application logs

```markdown
Analyze these logs for issues.

## Logs
```
{LOGS}
```

## Context
- Application: {APPLICATION}
- Time period: {TIME_PERIOD}
- Known issues: {KNOWN_ISSUES}

## Analyze:

### Error Summary
| Error Type | Count | First Seen | Last Seen | Sample Message |
|------------|-------|------------|-----------|----------------|

### Patterns Identified
- Recurring errors
- Correlated events
- Timing patterns
- User/session patterns

### Root Cause Hypothesis
For each significant error pattern:
- Likely cause
- Evidence supporting hypothesis
- Recommended investigation

### Performance Indicators
- Request latency trends
- Throughput patterns
- Resource utilization signals

### Recommendations
1. Immediate actions
2. Short-term fixes
3. Long-term improvements

### Queries
```
# Useful log queries for continued investigation
```

## Output
Structured analysis with actionable recommendations
```

---

## MAINT-003: Performance Diagnostics
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Diagnosing performance issues

```markdown
Diagnose this performance issue.

## Problem Description
{PROBLEM}

## Symptoms
- Response time: {RESPONSE_TIME}
- Throughput: {THROUGHPUT}
- Resource usage: {RESOURCE_USAGE}

## Metrics/Profiling Data
{METRICS}

## Recent Changes
{CHANGES}

## Analyze:

### Bottleneck Identification
- CPU bound vs I/O bound
- Memory pressure
- Network latency
- Database performance

### Root Cause Analysis
- Primary bottleneck
- Contributing factors
- Evidence

### Performance Profile
```
{PROFILE_INTERPRETATION}
```

### Recommendations
| Fix | Expected Impact | Effort | Priority |
|-----|-----------------|--------|----------|

### Quick Wins
- Immediate improvements possible

### Long-term Optimizations
- Architectural changes needed

### Monitoring Recommendations
- Key metrics to track
- Alert thresholds

## Output
Diagnostic report with prioritized fixes
```

---

## MAINT-004: Dependency Audit
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Auditing project dependencies

```markdown
Audit dependencies for this project.

## Dependency List
{DEPENDENCIES}
<!-- package.json, requirements.txt, pom.xml, etc. -->

## Analyze:

### Security Vulnerabilities
| Package | Version | Vulnerability | Severity | CVE | Fixed In |
|---------|---------|--------------|----------|-----|----------|

### Outdated Packages
| Package | Current | Latest | Behind By | Breaking Changes |
|---------|---------|--------|-----------|------------------|

### License Compliance
| Package | License | Compliance Status | Notes |
|---------|---------|------------------|-------|

### Unused Dependencies
- Packages imported but not used
- Dev dependencies in production

### Duplicate Dependencies
- Same package different versions
- Conflicting requirements

### Recommendations
1. **Critical**: Security fixes needed
2. **High**: Major version updates recommended
3. **Medium**: Minor updates available
4. **Low**: Nice to have

### Update Plan
| Phase | Packages | Risk | Testing Required |
|-------|----------|------|------------------|

## Output
Complete dependency audit report
```

---

## MAINT-005: Capacity Planning
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Planning infrastructure capacity

```markdown
Create a capacity plan based on these metrics.

## Current State
- Infrastructure: {INFRASTRUCTURE}
- Current usage: {USAGE}
- Growth trend: {GROWTH}

## Business Context
- Expected growth: {BUSINESS_GROWTH}
- Upcoming events: {EVENTS}
- Budget constraints: {BUDGET}

## Analyze:

### Current Capacity Utilization
| Resource | Capacity | Current Use | % Utilized |
|----------|----------|-------------|------------|
| CPU | | | |
| Memory | | | |
| Storage | | | |
| Network | | | |
| Database | | | |

### Growth Projections
```
{GROWTH_ANALYSIS}
```

### Capacity Runway
| Resource | Exhaustion Date | At Current Growth |
|----------|-----------------|-------------------|

### Scaling Recommendations

#### Short-term (0-3 months)
- Immediate needs
- Quick optimizations

#### Medium-term (3-12 months)
- Planned scaling
- Architecture changes

#### Long-term (12+ months)
- Strategic changes
- Technology migrations

### Cost Analysis
| Option | Monthly Cost | Capacity Gain | $/unit |
|--------|-------------|---------------|--------|

### Risk Assessment
- Single points of failure
- Scaling bottlenecks
- Cost risks

## Output
Comprehensive capacity plan with timeline and budget
```

---

## MAINT-006: Database Maintenance Plan
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Creating database maintenance schedules

```markdown
Create a database maintenance plan.

## Database
- Platform: {DATABASE}
- Size: {SIZE}
- Usage pattern: {USAGE}
- Criticality: {CRITICALITY}

## Current State
{CURRENT_ISSUES}

## Generate Maintenance Plan:

### Daily Tasks
| Task | Time | Duration | Impact | Automated |
|------|------|----------|--------|-----------|
| Backup verification | | | | |
| Log cleanup | | | | |
| Connection monitoring | | | | |

### Weekly Tasks
| Task | Day | Duration | Impact | Automated |
|------|-----|----------|--------|-----------|
| Index maintenance | | | | |
| Statistics update | | | | |
| Space monitoring | | | | |

### Monthly Tasks
| Task | Week | Duration | Impact | Automated |
|------|------|----------|--------|-----------|
| Full integrity check | | | | |
| Fragmentation analysis | | | | |
| Security audit | | | | |

### Quarterly Tasks
- Performance baseline comparison
- Capacity planning review
- DR test

### Maintenance Scripts
```sql
-- Include scripts for each task
```

### Monitoring Queries
```sql
-- Health check queries
```

### Alert Thresholds
| Metric | Warning | Critical |
|--------|---------|----------|

## Output
Complete maintenance plan with schedules and scripts
```

---

## MAINT-007: Security Patch Assessment
**Rating:** ⭐⭐⭐⭐ | **Use Case:** Evaluating security patches

```markdown
Assess this security patch for deployment.

## Patch Information
- CVE: {CVE}
- Severity: {SEVERITY}
- Affected component: {COMPONENT}

## Patch Details
{PATCH_DESCRIPTION}

## Current Environment
{ENVIRONMENT}

## Assess:

### Vulnerability Analysis
- Attack vector
- Exploitability
- Impact if exploited
- Current exposure

### Patch Compatibility
- Version compatibility
- Dependencies affected
- Breaking changes

### Testing Requirements
| Test Type | Scope | Priority |
|-----------|-------|----------|
| Unit tests | | |
| Integration tests | | |
| Security tests | | |
| Performance tests | | |

### Deployment Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

### Timeline Recommendation
- Urgency level
- Recommended deployment window
- Rollback time required

### Deployment Plan
1. Pre-deployment steps
2. Deployment steps
3. Verification steps
4. Rollback steps

### Communication Plan
- Stakeholders to notify
- Timeline communication
- Post-deployment notification

## Output
Patch assessment with deployment recommendation
```
