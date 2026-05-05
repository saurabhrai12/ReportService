# AI in SDLC: Complete Strategy & Implementation Guide (v2.0)

> **What changed in v2.0:** Honest measurement methodology, realistic expectations and failure modes, expanded governance (model versioning, IP, vendor risk), role-specific playbooks, deeper context-engineering guidance, attribution methodology for metrics, and a living-document maintenance process. See [Appendix A: Changelog](#appendix-a-changelog) for the full diff against v1.0.

---

## Executive Summary

This document provides a framework for implementing AI tools across the Software Development Lifecycle (SDLC). It includes adoption strategy, security guardrails, governance policies, prompt templates, role-specific playbooks, and metrics tracking with honest attribution methodology.

**Key principles guiding this version:**

1. **Targets are ranges, not promises.** Every metric target includes the conditions under which it's achievable and the methodology for measuring it.
2. **Failure is expected.** A productivity dip in weeks 2–4 is normal. Teams that don't acknowledge it lose executive support before gains materialize.
3. **AI is a tool, not a strategy.** Context engineering, review discipline, and governance matter more than tool selection.
4. **The document is alive.** Quarterly reviews, named owners, and changelog entries are mandatory, not aspirational.

---

## Quick Navigation by Use Case

| I want to... | Go to |
|---|---|
| Understand if AI helps for my role | [Section 10: Role-Specific Playbooks](#10-role-specific-playbooks) |
| Know what AI is *bad* at | [Section 4: Realistic Expectations & Failure Modes](#4-realistic-expectations--failure-modes) |
| Set up data classification | [Section 5: Security Guardrails](#5-security-guardrails-high-level) |
| Generate user stories | Prompt library → REQ-002 |
| Track adoption honestly | [Section 8: Metrics & Attribution Methodology](#8-metrics--attribution-methodology) |
| Calculate realistic ROI | [Section 8.4: ROI With Honest Assumptions](#84-roi-with-honest-assumptions) |
| Manage project context for AI | [Section 7: Context Engineering](#7-context-engineering) |
| Handle a model version change | [Section 6.2: Model & Version Governance](#62-model--version-governance) |
| Update this document | [Section 12: Living Document Mechanics](#12-living-document-mechanics) |

---

## Table of Contents

1. [AI Integration Across SDLC Phases](#1-ai-integration-across-sdlc-phases)
2. [Adoption Framework & Roadmap](#2-adoption-framework--roadmap)
3. [Acceptable Use Policy (High-Level)](#3-acceptable-use-policy-high-level)
4. [Realistic Expectations & Failure Modes](#4-realistic-expectations--failure-modes)
5. [Security Guardrails (High-Level)](#5-security-guardrails-high-level)
6. [Governance: Model, IP, Vendor, Open Source](#6-governance-model-ip-vendor-open-source)
7. [Context Engineering](#7-context-engineering)
8. [Metrics & Attribution Methodology](#8-metrics--attribution-methodology)
9. [Prompt Templates Library](#9-prompt-templates-library)
10. [Role-Specific Playbooks](#10-role-specific-playbooks)
11. [Implementation Checklist](#11-implementation-checklist)
12. [Living Document Mechanics](#12-living-document-mechanics)
13. [Appendices](#13-appendices)

---

## 1. AI Integration Across SDLC Phases

### Phase-by-Phase AI Applications

The table below describes *where AI helps*. The "Realistic Range" column reflects observed outcomes across organizations with mature engineering practices. Outcomes vary widely; see Section 4 for conditions under which gains evaporate.

| SDLC Phase | AI Use Cases | Realistic Range (mature teams) | Key Risks |
|---|---|---|---|
| **Requirements & Analysis** | Requirements extraction, user story generation, gap analysis, compliance mapping | 20–35% faster documentation | Hallucinated requirements; loss of stakeholder nuance |
| **Design & Architecture** | API design, schema design, ADR drafts, security review checklists | Variable; best for first drafts and reviews, not novel design | Plausible-but-wrong architecture; missing non-functional concerns |
| **Development** | Code generation, refactoring, debugging, SQL, boilerplate | 15–35% faster on well-scoped tasks | Subtle bugs in generated code; over-reliance for complex logic |
| **Code Review** | First-pass review, security/style scanning, PR summaries | 20–40% faster first-pass review | Missed semantic issues; review fatigue if AI is verbose |
| **Testing** | Unit test scaffolding, test data, E2E scenarios, edge case generation | 25–45% faster test creation | Tests that pass but don't actually verify behavior |
| **Documentation** | API docs, READMEs, ADRs, runbooks, release notes | 30–50% faster | Stale docs if not regenerated alongside code |
| **Deployment** | CI/CD scaffolding, IaC drafts, K8s manifests | Modest gains; high risk if unchecked | Insecure-by-default configs; outdated patterns |
| **Maintenance** | Log analysis, incident postmortems, performance triage | 15–30% faster initial triage | Confident wrong root-cause analysis |

> **Note on ranges:** These reflect *observed* gains in organizations with measurement discipline, not vendor marketing claims. The lower end of each range is more likely in the first 6 months. See Section 8 for measurement methodology.

---

## 2. Adoption Framework & Roadmap

### Four-Phase Implementation (Revised Timeline)

The original v1.0 timeline (8 weeks pilot → expansion at week 11) was too aggressive. Six weeks of pilot data with weekly retros yields ~3 sprints of usable signal — not enough to distinguish noise from impact. The revised timeline below adds explicit Go/No-Go gates and extends the pilot.

```
PHASE 1          PHASE 2              PHASE 3              PHASE 4
Foundation       Pilot                Expansion            Optimization
(Weeks 1-4)      (Weeks 5-16)         (Weeks 17-26)        (Ongoing)
                 [Go/No-Go @ wk 16]   [Review @ wk 26]

Setup            Test + Measure       Scale + Train        Optimize + Iterate
Security         Refine prompts       Build playbooks      Custom workflows
Train champions  Honest evaluation    Community of practice Continuous ROI
```

### Go/No-Go Gate Criteria (End of Phase 2)

Expansion requires meeting **at least 3 of 5** criteria with documented evidence:

1. **Adoption ≥ 60%** of pilot team actively using AI tools weekly
2. **Net positive sentiment** (≥ 60% would recommend continuing) on quarterly survey
3. **No critical security/policy incidents** attributable to AI use
4. **At least one quantified efficiency gain** with attribution methodology applied (Section 8.3)
5. **Documented playbook** of what worked and what didn't, ready to transfer

If fewer than 3 are met: extend pilot, do not expand. This is the most important governance decision in the entire program.

### Phase Details

#### Phase 1: Foundation (Weeks 1-4)

| Week | Activities | Deliverables |
|---|---|---|
| 1 | Executive sponsorship, tool selection, security review kickoff | Sponsor identified; tool shortlist |
| 2 | Acceptable use policy finalized; SSO and access provisioned | Policy v1.0; access live for pilot team |
| 3 | Pre-commit hooks deployed; audit logging configured | Hooks in place; logging dashboard |
| 4 | Baseline metrics collection started; champions trained | 4-week baseline window begins |

#### Phase 2: Pilot (Weeks 5-16) — *Extended from v1.0's 6 weeks to 12 weeks*

| Weeks | Focus |
|---|---|
| 5-8 | Onboarding, initial prompt template usage, daily friction logging |
| 9-12 | Mid-pilot retro; refine prompts; address blockers; **expect productivity dip in weeks 2–4 of pilot use** |
| 13-16 | Stabilization; gather honest metrics; prepare Go/No-Go evidence |

#### Phase 3: Expansion (Weeks 17-26)

- Train additional teams using documented pilot learnings (not just successes)
- Establish community of practice with rotating ownership
- Build CI/CD integrations only after manual workflows are stable
- Deploy role-specific playbooks (Section 10)

#### Phase 4: Optimization (Ongoing, Quarterly Cadence)

- Quarterly ROI review with attribution methodology applied
- Prompt library curation: archive stale templates, promote validated ones
- Model/version governance reviews (Section 6.2)
- Annual policy refresh

---

## 3. Acceptable Use Policy (High-Level)

### Approved vs Prohibited Usage

| ✅ Permitted | ⚠️ Requires Approval | 🚫 Prohibited |
|---|---|---|
| Code generation & completion | Processing anonymized customer data | Inputting Red Zone data (Section 5) |
| Test generation | Automated AI pipelines reading prod data | Generating malicious code |
| Documentation writing | Training/fine-tuning on company data | Bypassing security controls |
| Debugging assistance | AI access to production systems | Unreviewed legal/financial decisions |
| Learning & research | Regulated data (PCI/HIPAA/GDPR) processing | Using unapproved tools or models |

### Code Review Requirements

All AI-generated code must:
1. Go through standard code review process — no exceptions
2. Be understood by the committer before merge (the "explain it back" test)
3. Include tests written or reviewed by the human committer
4. Be attributed in commit message for substantial AI contributions (>20 lines or non-trivial logic)

### Attribution Template

```
# Commit message footer (preferred over inline comments):
AI-Assisted: Initial draft with Claude Sonnet 4.5
Reviewed-by: Saurabh K
Modifications: Added error handling, replaced regex with parser, added tests
```

### Incident Reporting

Report immediately if you:
- Accidentally input prohibited data into an AI tool
- Discover policy violations (yours or others')
- Receive AI output containing apparent leaked credentials, PII, or proprietary code
- Identify new attack patterns or risks

**Contact:** security@company.com | Slack: #security-incidents

> **Detailed policy document:** `ai-acceptable-use-policy.md`

---

## 4. Realistic Expectations & Failure Modes

> *This section is new in v2.0. It is the most important section to read before setting targets.*

### 4.1 The Productivity Dip Is Real

Most teams experience a measurable productivity *decrease* in weeks 2–4 of serious AI adoption. Causes include:

- Time spent learning prompt patterns
- Debugging AI-generated code that "looked right"
- Context-switching between AI and manual workflows
- Calibrating trust (initially over-trusting, then under-trusting)

**Plan for it.** Communicate it to executives upfront. Teams that hide the dip lose credibility when it appears in metrics. The dip typically resolves by week 6–8 if the team has good prompt templates and review discipline.

### 4.2 Where AI Consistently Underperforms

Document these honestly so teams don't waste time:

| Domain | Why AI Struggles | What to Do Instead |
|---|---|---|
| **Complex distributed-system debugging** | Requires runtime state, network traces, timing — AI sees only static code | Use AI for hypothesis generation; humans for verification |
| **Novel domain logic** | No training data for your specific business rules | Document the domain heavily in CLAUDE.md; expect partial help |
| **Performance-critical optimization** | AI suggests plausible patterns that may regress under real load | Always benchmark; never trust AI perf claims without measurement |
| **Security-critical code paths** | AI can produce subtly insecure code with confident framing | Mandatory human security review; static analysis as backstop |
| **Cross-cutting refactors** | Limited context window can't hold the whole change | Break into smaller AI-assisted steps with strong tests between |
| **Concurrency and async correctness** | Race conditions are hard to reason about from text | Treat AI output as a starting point; pair with stress tests |
| **Legacy system integration** | AI doesn't know your specific quirks and undocumented behavior | Heavy context investment; or skip AI for these areas |

### 4.3 Common Anti-Patterns

Watch for these in pilot teams. They predict program failure.

1. **Prompt-and-paste** — Code goes from AI directly into PR without the committer reading it. Detection: ask the committer to explain a non-obvious line. If they can't, fail the review.

2. **Over-reliance on AI for architectural decisions** — Architecture requires understanding tradeoffs that depend on context AI doesn't have (org politics, future roadmap, team skills). Use AI to *evaluate* options, not to *choose* them.

3. **Junior developers skipping fundamentals** — If a junior never struggles with debugging, they won't develop debugging intuition. Establish "AI-free" time or tasks for skill-building.

4. **Prompt template hoarding** — Champion writes great prompts but doesn't share. Library becomes a graveyard of one-off templates.

5. **Metrics theater** — Teams optimize for measured metrics (PRs merged, lines of code) instead of outcomes (defects, user value).

6. **Context window exhaustion** — Stuffing 50-page CLAUDE.md files into every request. Token budget runs out before useful work begins. See Section 7.

7. **Confident hallucination acceptance** — AI confidently cites APIs that don't exist, libraries that don't have the function, behaviors that aren't real. Always verify against official docs for non-trivial claims.

### 4.4 Honest Conversations to Have With Executives

Before kickoff, agree on:

- Productivity will likely *decrease* before it increases
- The first quarter's metrics may not show clear ROI
- Some teams will benefit much more than others; that's normal
- Quality and developer satisfaction are leading indicators; velocity follows
- Some pilots fail. That's information, not failure of the program

---

## 5. Security Guardrails (High-Level)

### 5.1 Data Classification Framework

```
🔴 RED ZONE - NEVER SHARE
├── Credentials: API keys, passwords, tokens, certificates, .env contents
├── PII: SSN, credit cards, health records, personal customer data
├── Production data: Real customer records, financial transactions
├── Security: Vulnerability reports, pen test results, exploit code
└── Regulated data: PCI-scoped, PHI, GDPR personal data, export-controlled

🟡 YELLOW ZONE - SANITIZE FIRST
├── Database schemas with sensitive column names
├── Log files (may contain IPs, user IDs, session tokens)
├── Config files (may have endpoint URLs, internal hostnames)
├── Stack traces and error messages (internal paths, hostnames)
└── Internal architecture diagrams with non-public details

🟢 GREEN ZONE - SAFE TO USE
├── Public documentation and open-source code
├── Generic algorithms and design patterns
├── Synthetic test data clearly marked as such
├── Public APIs and well-known frameworks
└── Non-confidential technical discussions
```

### 5.2 Technical Controls Summary

| Control | Purpose | Implementation |
|---|---|---|
| Pre-commit hooks | Prevent secrets in code | detect-secrets, gitleaks |
| Prompt sanitizer | Runtime data protection at the IDE/proxy layer | Custom Python library |
| Audit logging | Usage tracking & compliance | Centralized SIEM ingestion |
| Network controls | Approved tools only | Egress proxy, allowlist |
| IDE configuration | Exclude sensitive files from AI context | `.aiignore` patterns |
| DLP integration | Catch policy violations in real time | Existing DLP rules extended |

### 5.3 Quick Reference Card

```
BEFORE USING AI TOOLS - ASK YOURSELF:

🔴 STOP - Does my prompt contain:
   • Passwords, API keys, tokens, certificates?
   • Customer PII or production data?
   • Confidential business information?
   → If YES: Do NOT proceed. Remove sensitive data.

🟡 CAUTION - Have I:
   • Sanitized database schemas and configs?
   • Removed identifying information from logs?
   • Replaced internal hostnames with placeholders?
   → If NO: Sanitize before proceeding.

🟢 PROCEED - My prompt contains only:
   • Public information and generic patterns
   • Properly sanitized data
   → Safe to use approved AI tools.
```

> **Detailed implementation:** `ai-security-guardrails-implementation.md`

---

## 6. Governance: Model, IP, Vendor, Open Source

> *This section is new in v2.0 and addresses governance gaps in the original.*

### 6.1 Why This Matters

AI tools are not static. Models update, vendors change terms, training data composition shifts, and IP/licensing positions evolve. A program without explicit governance for these dynamics will accumulate risk silently.

### 6.2 Model & Version Governance

**Pin models when correctness depends on consistency.**

For automated pipelines, evaluations, and any workflow where behavior change would cause regressions:

- Always specify exact model versions (e.g., `claude-sonnet-4-5-20250929`) rather than aliases
- Maintain a "current pinned version" record in `.ai-context/MODELS.md`
- Define a regression test suite that runs on model changes
- Establish a rollback path if a new model degrades a workflow

**For interactive developer use:**

- Latest stable model is generally appropriate
- Communicate model changes via the AI champions channel
- Capture surprising behavior changes in a shared log

**Process for model upgrades in pipelines:**

1. New model released → champion runs regression suite in dev
2. If regression suite passes → trial in staging for 1 week
3. If staging stable → coordinated rollout with rollback ready
4. If regression suite fails → file issue, stay on pinned version

### 6.3 IP, Licensing, and Code Provenance

Open questions every organization should answer in writing:

| Question | Recommended Default Position |
|---|---|
| Can AI-generated code go into proprietary products? | Yes, with human review and attribution |
| Can AI-generated code go into open-source contributions? | Check OSS project's policy; many require disclosure (Linux kernel, Apache projects, etc.) |
| What about code derived from training data? | Use vendor's IP indemnification where offered; avoid AI for IP-sensitive components (e.g., patent-relevant algorithms) |
| Who owns AI-generated code? | Per current US Copyright Office guidance, purely AI-generated work is not copyrightable; human-authored modifications create the copyrightable contribution. Document the human contribution. |
| Can we use AI on customer code under NDA? | Only with explicit customer consent and contractual coverage; default to no |

> **Note:** This is general guidance, not legal advice. Have your legal team review and finalize positions specific to your jurisdiction and contracts.

### 6.4 Vendor Risk Management

Plan for the day your primary AI provider has an outage, deprecates a model, or changes terms.

**Required vendor risk artifacts:**

1. **Vendor inventory** — Which AI tools are in use, by whom, for what?
2. **Data flow diagram** — What data goes where? Required for SOC 2 / ISO controls.
3. **Fallback plan** — If primary vendor is down for 24 hours, what happens? For 1 week?
4. **Contract review schedule** — Quarterly review of terms, especially data retention and training-on-customer-data clauses.
5. **Exit plan** — How would we migrate prompt templates and workflows to an alternative vendor?

**Contractual must-haves:**

- Data is not used for training on customer/proprietary data without explicit opt-in
- Reasonable SLA with documented incident response
- Clear data retention and deletion terms
- Subprocessor disclosure
- Indemnification for IP claims (where available)

### 6.5 Open Source Contributions

If your org contributes to OSS:

- Maintain a list of OSS projects' AI-generated-code policies (Apache, Linux kernel, GNOME, etc., have varying stances)
- Default to disclosure even when not required
- Train contributors on per-project rules
- Don't submit AI-only contributions to projects that prohibit them

---

## 7. Context Engineering

> *Expanded substantially in v2.0. Context engineering is where the leverage actually lives.*

### 7.1 Why Context Beats Prompting

A great prompt with bad context produces mediocre output. Adequate prompts with excellent context produce excellent output. Most organizations underinvest here.

### 7.2 Project Context Architecture

```
project-root/
├── CLAUDE.md                    # Entry point — short, points to deeper docs
├── .ai-context/
│   ├── PROJECT_CONTEXT.md       # 1-page system overview
│   ├── ARCHITECTURE.md          # Patterns, key components, dependencies
│   ├── CONVENTIONS.md           # Coding standards, naming, testing patterns
│   ├── DOMAIN_GLOSSARY.md       # Business terms (critical for non-trivial domains)
│   ├── DECISIONS.md             # ADRs in compressed form
│   ├── CURRENT_SPRINT.md        # Active work, known issues, in-flight changes
│   ├── MODELS.md                # Pinned model versions per workflow
│   └── ANTIPATTERNS.md          # "Don't do X here" — codifies tribal knowledge
├── .aiignore                    # Files to exclude from AI context
└── .claude/
    └── settings.json            # Tool-specific settings
```

### 7.3 Token Budget Discipline

Modern context windows are large but not infinite, and *quality of attention degrades with size*. Stuffing everything into context is an anti-pattern.

**Heuristic budget allocation for a typical coding task (~200K token model):**

| Section | Target % | Notes |
|---|---|---|
| System / instructions | 5% | Keep terse |
| CLAUDE.md and core context | 10% | Should fit in ~20K tokens |
| Retrieved relevant code | 30% | Use search/RAG, not paste-everything |
| Current task description | 5% | Specific, scoped |
| Working code being edited | 30% | The actual file(s) under change |
| Output budget | 20% | Reserved for response |

**Anti-pattern:** A 50-page CLAUDE.md that consumes 60% of the context window before the task even starts.

### 7.4 Effective CLAUDE.md Template

```markdown
# Project: Order Service

## What This Is
Order processing API. Handles cart → checkout → fulfillment for the e-commerce
platform. ~50K orders/day. Owned by Commerce Squad.

## Tech Stack
- Python 3.11, FastAPI, SQLAlchemy
- Postgres (orders), Redis (cart), Snowflake (analytics replica)
- Deployed on AWS ECS Fargate behind ALB

## Critical Patterns
- All money values use Decimal, never float
- All timestamps stored UTC, displayed in user's tz at API boundary
- Idempotency: every mutating endpoint accepts Idempotency-Key header
- Error responses follow RFC 7807 Problem Details

## Before You Code
1. Read .ai-context/CONVENTIONS.md (5 min) — naming and test patterns
2. Check .ai-context/CURRENT_SPRINT.md — avoid conflicting changes
3. Run `make lint test` before committing

## Common Tasks
- New endpoint → docs/adding-endpoints.md
- Schema change → docs/schema-changes.md (requires migration review)
- New event → docs/event-publishing.md

## Don't
- Don't add new ORM models without ADR (we're consolidating to 3 aggregates)
- Don't bypass the ServiceContext for cross-aggregate calls
- Don't use sync DB calls in async handlers (we had an outage from this)
```

Key properties: under 200 lines, points to deeper docs, includes "don't" guidance.

### 7.5 Keeping Context From Drifting

Context rot is the #1 long-term failure mode. Mitigations:

| Mechanism | What It Does | Owner |
|---|---|---|
| PR template question | "Did this change require updating CLAUDE.md or .ai-context/?" | Reviewer enforces |
| Quarterly context audit | Review all `.ai-context/` files for staleness | Tech lead |
| Auto-generated sections | Architecture diagram from code, API list from OpenAPI spec | CI |
| Linked decision log | ADR adds entry to DECISIONS.md automatically | ADR template |
| Sprint kick-off update | Tech lead updates CURRENT_SPRINT.md at start of sprint | Tech lead |

### 7.6 Real-World Example (Sanitized)

For a Snowflake-native data platform project, the team found high leverage in:

- A `DOMAIN_GLOSSARY.md` defining terms like "structured product," "layering," "settlement window" — without it, AI confused financial-industry terms with their generic meanings
- An `ANTIPATTERNS.md` listing things like "don't generate dynamic SQL with f-strings" and "don't bypass the audit table writes" — codified painful past lessons
- A short CLAUDE.md (~80 lines) that pointed to deeper docs rather than inlining them
- A pinned model version because a model update changed how it generated stored procedures, breaking the deployment pipeline

The unsuccessful attempt: a 600-line CLAUDE.md that tried to inline all conventions. AI responses degraded noticeably; team reverted to the short version.

---

## 8. Metrics & Attribution Methodology

> *Substantially revised in v2.0. The original section presented targets without measurement methodology, which made the numbers easy to dismiss.*

### 8.1 The Attribution Problem

Velocity, defect rates, and review times change for many reasons: team composition, project complexity, holiday schedules, on-call rotation load, hiring, attrition, code freeze cycles. Attributing changes to AI requires either:

1. **Comparison group** (control team or matched historical period)
2. **Interrupted time-series analysis** (clear before/after with stability checks)
3. **Self-reported time savings** with sanity checks (least rigorous, but useful)

Most organizations use option 3 informally. This guide recommends combining (2) and (3) with explicit acknowledgment of confounders.

### 8.2 Recommended Measurement Approach

| Approach | Rigor | Effort | When to Use |
|---|---|---|---|
| **Self-reported time savings (survey)** | Low | Low | All teams; gather monthly |
| **Before/after on the same team** | Medium | Medium | Standard recommendation |
| **Matched comparison with non-pilot team** | High | High | High-stakes ROI claims |
| **A/B within team (random task assignment)** | Highest | Very high | Research-grade only |

For most programs, do this:

1. **4-week baseline window** before pilot starts (in Phase 1)
2. **Track same metrics during pilot** with no other major changes (avoid hiring, reorg, methodology changes during pilot)
3. **Acknowledge confounders explicitly** in every report
4. **Triangulate** quantitative metrics with qualitative survey data

### 8.3 Metrics Dashboard With Attribution Notes

| Category | Metric | Realistic Target Range | Measurement | Attribution Caveats |
|---|---|---|---|---|
| **Velocity** | Story Points / Sprint | +10–25% over 2 quarters | Jira API; same team, same definition of done | Story point inflation is common; track also cycle time |
| | Cycle Time | -15–30% | (PR merged) - (work started) from Git/Jira | Dependent on review capacity, not just dev speed |
| | Deployment Frequency | +20–50% | CI/CD logs | Confounded by deployment policy changes |
| **Quality** | Defect Rate | -15–35% | Bugs filed / story points delivered | Confounded by reporting hygiene |
| | Defect Escape Rate | -20–40% | Prod bugs / total bugs found | Lagging indicator; takes 1-2 quarters to stabilize |
| | Test Coverage | +10–25% | Coverage tool reports | Coverage ≠ quality; combine with mutation testing |
| **Efficiency** | PR Review Time | -25–45% | GitHub/GitLab API | Confounded by reviewer availability |
| | Documentation Time | -30–50% | Self-reported | Hard to measure objectively |
| | Debug Time | -15–30% | Self-reported, optionally Jira time-tracking | Highly variable by issue complexity |
| **Experience** | Developer Satisfaction (AI-specific) | ≥ 7.0 / 10 | Quarterly survey | Subjective; track trend, not absolute |
| | AI Adoption Rate | ≥ 70% weekly active | Tool telemetry | Adoption ≠ effectiveness |
| | Tool Usefulness | ≥ 7.0 / 10 | Survey | Watch for novelty effect in first 2 months |

> **Why these ranges differ from v1.0:** The original targets (e.g., +20% velocity, -25% defect rate) were stated as point estimates. Real-world variance across teams and projects is substantial. Ranges with attribution notes are more honest and more defensible.

### 8.4 ROI With Honest Assumptions

The original guide showed a "545% ROI" with crisp numbers. This calculation has several issues: (1) self-reported hours saved are typically inflated by 30–50%, (2) "fully loaded cost per hour" is often used loosely, (3) tool cost is rarely the only cost — there's also training, governance, and review overhead.

**Honest ROI formula:**

```
Net Monthly Value = (Hours_Saved × Loaded_Hourly_Rate × Discount_Factor)
                   - Tool_Cost
                   - Training_Cost
                   - Governance_Overhead
                   - Review_Overhead

ROI = Net_Monthly_Value / (Tool_Cost + Training_Cost + Governance_Overhead) × 100%
```

Where:

- **Discount_Factor** = 0.5–0.7 to account for self-report inflation. Use 0.5 in year 1, 0.7 once you have validated data.
- **Loaded_Hourly_Rate** = salary + benefits + facilities ÷ working hours. Typically 1.3–1.5× nominal salary rate.
- **Training_Cost** = champion time + onboarding hours + ongoing education
- **Governance_Overhead** = security review, policy maintenance, audit
- **Review_Overhead** = additional time spent reviewing AI-generated code (real, often 5–10% of dev time)

**Worked example with honest numbers:**

```
Team: 10 developers
Self-reported hours saved: 8 hrs/dev/week (often inflated)
Discount factor (year 1): 0.5
Effective hours saved: 4 hrs/dev/week × 4.3 weeks = 17.2 hrs/month/dev
Loaded hourly rate: $90 (assuming $120K salary × 1.4 loading ÷ 1860 hrs)

Monthly Value = 10 × 17.2 × $90 = $15,480

Costs:
  Tool cost: $5,000/month
  Training (amortized): $1,500/month
  Governance overhead: $2,000/month
  Review overhead: 5% of dev time × 10 devs × 172 hrs × $90 ÷ 12 = ... ≈ $1,300/month

Net Monthly Value = $15,480 - $5,000 - $1,500 - $2,000 - $1,300 = $5,680

ROI = $5,680 / ($5,000 + $1,500 + $2,000) × 100% ≈ 67%

Realistic ROI range across pilot programs: 50%–200% in year 1.
Year 2+ ROI is typically higher as fixed costs are absorbed and discount
factor can rise toward 0.7 with validated time-savings data.
```

A 50–200% year-1 ROI is genuinely good. It's also defensible. A 545% ROI without methodology is not.

### 8.5 Survey Schedule

| Survey Type | Frequency | Duration | Purpose |
|---|---|---|---|
| Weekly Pulse | Weekly during pilot | 90 sec | Detect blockers fast |
| Monthly Adoption | Monthly | 8 min | Track usage patterns and friction |
| Quarterly Deep Dive | Quarterly | 20 min | Comprehensive review with attribution analysis |

> **Detailed framework:** `prompt-templates-library/08-metrics-framework/`

---

## 9. Prompt Templates Library

### 9.1 Library Structure (with Maturity Tracking)

Every template now carries metadata. The original library tracked only name and use case; maintenance becomes impossible at 70+ templates without more.

**Template metadata schema:**

```yaml
id: DEV-001
name: Code Generation
phase: development
maturity: validated  # draft | validated | battle-tested | deprecated
data_zone_required: green  # green | yellow-after-sanitization
owner: alice@company.com
last_reviewed: 2026-04-15
example_good_output: examples/dev-001-good.md
example_bad_output: examples/dev-001-bad.md
known_failure_modes:
  - "Generates plausible-but-wrong import paths for internal libraries"
  - "Misses our convention of always using async DB calls"
```

**Maturity definitions:**

- **draft** — Authored but not validated; use with caution
- **validated** — Tested by ≥ 2 developers with documented success
- **battle-tested** — In active use by ≥ 5 developers for ≥ 1 quarter
- **deprecated** — Replaced or no longer recommended; kept for reference

**Quarterly curation:**

- Promote `draft` → `validated` based on usage evidence
- Promote `validated` → `battle-tested` based on duration and breadth
- Demote stale `validated` templates not used in 90 days
- Archive `deprecated` templates after 1 year

### 9.2 Template Summary by Phase

The original library structure remains; the table is omitted here for brevity but lives in:

```
prompt-templates-library/
├── README.md
├── 01-requirements-analysis/  (8 templates)
├── 02-design-architecture/    (9 templates)
├── 03-development/            (14 templates)
├── 04-code-review/            (10 templates)
├── 05-testing/                (12 templates)
├── 06-documentation/          (10 templates)
├── 07-deployment-maintenance/ (7 templates)
└── 08-metrics-framework/
```

Each template directory now contains a `MATURITY.md` index and an `examples/` folder with paired good/bad outputs.

> **Detailed templates:** `prompt-templates-library/` directory

---

## 10. Role-Specific Playbooks

> *This section is new in v2.0. Treating "developers" as a uniform group misses the largest source of variation in AI value.*

### 10.1 Senior Architect / Tech Lead

**High-leverage uses:**
- ADR drafting (use AI to evaluate options against criteria you specify)
- API contract review (AI catches consistency issues quickly)
- Technical debt assessment (AI is good at pattern-matching code smells)
- Onboarding doc generation

**Low-value or risky uses:**
- Letting AI choose architectural direction (tradeoffs depend on context AI lacks)
- Generating systems designs from scratch for novel problems
- Cross-cutting refactor execution (better as orchestrator than implementer)

**Specific workflow:** Use AI as a "junior architect" — ask it to enumerate options, list tradeoffs, identify what could go wrong. Never delegate the *decision*.

### 10.2 Senior / Mid-Level Developer

**High-leverage uses:**
- Boilerplate generation (REST handlers, DAOs, test scaffolding)
- Test case enumeration (especially edge cases)
- SQL writing and optimization
- Code refactoring with strong tests as guardrails
- Reading unfamiliar code

**Low-value or risky uses:**
- Concurrency/async correctness (verify with stress tests)
- Performance optimization without benchmarking
- Code in domains AI hasn't seen (your specific business logic)

**Specific workflow:** Tight loop — small, well-scoped requests with the AI's output reviewed before the next request. Don't let AI accumulate uncommitted changes across many turns.

### 10.3 Junior Developer

**High-leverage uses:**
- Code explanation (understanding existing code)
- Concept learning (explain X to me; how does Y work)
- Test writing (with the senior reviewing)
- Documentation

**Low-value or risky uses (especially as anti-patterns):**
- Skipping debugging fundamentals (always try to debug yourself first; ask AI second)
- Accepting AI-generated code you don't understand
- Letting AI write code for tasks designed to teach you

**Specific guidance for managers:** Establish "AI-light" tasks designed for skill-building. Pair junior devs with mentors who can spot AI over-reliance. The goal is junior devs who are *more* skilled because of AI, not *dependent on* AI.

### 10.4 SRE / Platform Engineer

**High-leverage uses:**
- Log analysis and pattern detection
- IaC (Terraform, Pulumi) drafts with strict review
- Runbook generation from incident postmortems
- Kubernetes manifest scaffolding
- Shell script and automation drafts

**Low-value or risky uses:**
- Incident root-cause analysis (AI generates plausible RCAs that may be wrong)
- Production change generation without staged rollout
- Security policy generation without expert review

**Specific workflow:** AI-generated infrastructure code requires extra scrutiny because errors are blast-radius-high. Always plan/diff before apply. Never trust AI for "is this safe to deploy" judgments.

### 10.5 QA Engineer / SDET

**High-leverage uses:**
- Test case enumeration from requirements
- Edge case generation
- Test data fabrication
- Converting manual test plans to automated tests
- Accessibility test generation

**Low-value or risky uses:**
- Generating tests that look comprehensive but don't actually verify behavior (the most common QA anti-pattern with AI)
- Trusting AI's claim that "this covers all the cases"

**Specific workflow:** Always ask "what would make this test fail?" If AI can't articulate a clear failure mode, the test isn't verifying anything.

### 10.6 Data / ML Engineer

**High-leverage uses:**
- SQL generation and optimization (well-suited to AI strengths)
- Pipeline scaffolding (Airflow, dbt, Snowflake stored procedures)
- Schema design first drafts
- Documentation generation from code

**Low-value or risky uses:**
- Statistical reasoning (AI is unreliable at non-trivial statistics)
- Pipeline correctness for novel data shapes (validate end-to-end)
- ML model selection without empirical testing

**Specific workflow:** Always validate generated SQL with `EXPLAIN` plans on representative data. Always run pipelines on small samples before full runs.

### 10.7 Engineering Manager

**High-leverage uses for the EM role itself:**
- Drafting performance review notes from raw observations
- Writing project status updates
- Generating talking points for 1:1s
- Summarizing long documents and Slack threads

**For managing AI-using teams:**
- Watch for over-reliance patterns in juniors
- Track velocity *and* quality, not just velocity
- Listen for "AI-fatigue" sentiment in 1:1s — it's real
- Be the executive translator: communicate the productivity dip honestly

---

## 11. Implementation Checklist

### Phase 1: Foundation (Weeks 1-4)

**Week 1-2: Setup & Security**
- [ ] Get executive sponsorship with explicit acknowledgment of productivity dip
- [ ] Select AI tools (Claude, Copilot, etc.)
- [ ] Complete security review including model & vendor risk
- [ ] Finalize acceptable use policy with legal review
- [ ] Configure tool access & SSO
- [ ] Deploy pre-commit hooks
- [ ] Set up audit logging

**Week 3-4: Baseline & Training**
- [ ] Identify data sources (Jira, GitHub, CI/CD)
- [ ] Deploy metrics collection scripts
- [ ] Distribute baseline developer survey
- [ ] Begin 4-week baseline data collection
- [ ] Create initial prompt templates (with maturity = `draft`)
- [ ] Train AI champions
- [ ] Set up project context structure (CLAUDE.md, `.ai-context/`)
- [ ] Document model governance positions (`MODELS.md`)

### Phase 2: Pilot (Weeks 5-16) — *Extended*

- [ ] Select 1–2 pilot teams (moderate complexity, willing participants)
- [ ] Onboard pilot teams with role-specific playbook (Section 10)
- [ ] Deploy prompt templates library
- [ ] Track metrics weekly with attribution notes
- [ ] Conduct weekly retros for first 4 weeks, then bi-weekly
- [ ] **Acknowledge productivity dip** when it appears (weeks 6–8 typically)
- [ ] Refine prompts based on feedback; promote `draft` → `validated`
- [ ] Document anti-patterns observed
- [ ] Prepare Go/No-Go evidence package by week 14
- [ ] Go/No-Go decision at week 16 with documented criteria (Section 2)

### Phase 3: Expansion (Weeks 17-26)

- [ ] Publish honest pilot results (including what didn't work)
- [ ] Create training materials covering anti-patterns and failure modes
- [ ] Train additional teams in waves of 2–3
- [ ] Establish community of practice with rotating ownership
- [ ] Deploy role-specific playbooks
- [ ] Build CI/CD integrations (only after manual workflows are stable)
- [ ] Set up monitoring dashboards with attribution caveats visible
- [ ] Monthly reporting with honest methodology

### Phase 4: Optimization (Ongoing)

- [ ] Quarterly ROI analysis with discount factor and confounders
- [ ] Quarterly prompt library curation
- [ ] Quarterly model & vendor governance review
- [ ] Annual policy refresh
- [ ] Capture and share success stories *and* failure stories
- [ ] Update targets based on validated data
- [ ] Annual external review (recommended) of governance and metrics

---

## 12. Living Document Mechanics

> *This section is new in v2.0 and answers: how does this document avoid becoming v1.0-forever?*

### 12.1 Ownership

- **Document Owner:** Named role (e.g., "Director of Engineering Excellence") — not an individual, so the owner survives departures
- **Contributors:** Named individuals at any time, listed in the changelog
- **Approval for major revisions:** Owner + Security + Legal

### 12.2 Review Cadence

| Trigger | Action |
|---|---|
| Quarterly review | Owner reviews entire document; minor corrections committed; significant changes proposed for review |
| New regulation (EU AI Act, sectoral rules) | Targeted update to governance sections |
| Major model vendor change | Update Section 6 (Governance) |
| Significant security incident | Update Section 5 within 30 days |
| Annual full refresh | Owner + Security + Legal sign off on updated version |

### 12.3 Change Log Discipline

Every revision gets an entry. Maintain in [Appendix A](#appendix-a-changelog).

### 12.4 Communication

- Major revisions announced in #ai-tools-help with a "what changed and why"
- Champions briefed in advance of expansion-relevant changes
- Annual review presented to engineering leadership

---

## 13. Appendices

### Appendix A: Changelog

| Version | Date | Owner | Summary |
|---|---|---|---|
| 1.0 | [Original date] | [Original owner] | Initial framework |
| 2.0 | 2026-05-05 | TBD | Added realistic expectations & failure modes (§4); revised metrics with attribution methodology and honest ROI (§8); expanded governance covering model versioning, IP, vendor risk, OSS (§6); deepened context engineering with token budgets and real-world examples (§7); added role-specific playbooks (§10); extended pilot timeline with Go/No-Go gates (§2); added living-document mechanics (§12); added prompt template maturity tracking (§9). |

### Appendix B: Success Criteria (Revised With Honest Targets)

#### 3-Month Goals
- [ ] 60–70% pilot team adoption rate (was 80% in v1.0 — overoptimistic for 3 months)
- [ ] 10–15% velocity improvement *or* equivalent quality gain
- [ ] 15–25% defect rate reduction
- [ ] ≥ 7.0 developer satisfaction score
- [ ] Net positive ROI demonstrated using honest methodology

#### 6-Month Goals
- [ ] 70–85% adoption across pilot + first expansion wave
- [ ] 20–30% efficiency gains validated with attribution analysis
- [ ] Measurable quality improvements with stable trend
- [ ] Established best practices and anti-patterns library
- [ ] Self-sustaining community of practice with rotating leadership

#### 12-Month Goals
- [ ] AI integrated into standard workflows for ≥ 80% of teams that opted in
- [ ] Custom integrations deployed where they meet a clear need
- [ ] Year-1 ROI of 50–200% (honest range)
- [ ] Organization-wide knowledge base with maintained context docs
- [ ] Quarterly governance review process operating
- [ ] Documented learnings shared internally and (if possible) externally

### Appendix C: Document Reference Guide

Complete package contents (unchanged structure from v1.0; content updated):

```
ai-sdlc-framework/
│
├── GOVERNANCE & SECURITY
│   ├── ai-acceptable-use-policy.md
│   └── ai-security-guardrails-implementation.md
│
├── PROMPT TEMPLATES LIBRARY (with maturity metadata)
│   ├── README.md
│   ├── 01-requirements-analysis/    (8 templates)
│   ├── 02-design-architecture/      (9 templates)
│   ├── 03-development/              (14 templates)
│   ├── 04-code-review/              (10 templates)
│   ├── 05-testing/                  (12 templates)
│   ├── 06-documentation/            (10 templates)
│   └── 07-deployment-maintenance/   (7 templates)
│
└── METRICS FRAMEWORK
    └── 08-metrics-framework/
        ├── README.md
        ├── developer-surveys.md
        ├── roi-calculator-templates.md (with discount factors)
        └── attribution-methodology.md (NEW in v2.0)
```

### Appendix D: Support & Resources

**Internal Resources**
- AI Champions: [Maintained list with rotation schedule]
- Office Hours: [Day/Time]
- Slack Channel: #ai-tools-help
- Documentation: [Internal wiki link]

**External Resources**
- Anthropic Documentation: https://docs.anthropic.com
- Claude Prompt Engineering Guide: https://docs.anthropic.com/claude/docs/prompt-engineering
- GitHub Copilot Docs: https://docs.github.com/copilot

**Feedback & Improvements**
- Submit feedback via thumbs up/down in AI tools
- Share learnings in #ai-tools-help
- Contribute prompts to shared library (with maturity = `draft` initially)
- Report security issues to security@company.com

---

**Document Version:** 2.0
**Last Updated:** 2026-05-05
**Owner:** [Role, not person]
**Next Review:** 2026-08-05 (quarterly)
