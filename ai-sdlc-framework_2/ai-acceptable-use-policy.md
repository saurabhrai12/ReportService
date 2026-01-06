# AI Tools Acceptable Use Policy

**Document Version**: 1.0  
**Effective Date**: [DATE]  
**Last Reviewed**: [DATE]  
**Policy Owner**: [Engineering Leadership / Security Team]  
**Applies To**: All employees, contractors, and vendors with access to company systems

---

## 1. Purpose

This policy establishes guidelines for the responsible use of Artificial Intelligence (AI) tools, including Large Language Models (LLMs), code assistants, and AI-powered development tools within our Software Development Lifecycle (SDLC). The goal is to enable productivity gains while protecting company assets, customer data, and intellectual property.

---

## 2. Scope

This policy covers:
- Cloud-based AI assistants (Claude, ChatGPT, Gemini, etc.)
- Code completion tools (GitHub Copilot, Cursor, Claude Code, etc.)
- AI features embedded in IDEs and development tools
- Custom AI applications built on LLM APIs
- Any tool that transmits code, data, or prompts to external AI services

---

## 3. Approved Tools

### 3.1 Authorized AI Tools

| Tool | Use Case | Approval Level | Data Classification Allowed |
|------|----------|----------------|----------------------------|
| [Claude Enterprise] | General development, analysis | All developers | Green, Yellow (sanitized) |
| [GitHub Copilot Business] | Code completion | All developers | Green, Yellow (sanitized) |
| [Internal AI Platform] | Sensitive workloads | Approved projects | Green, Yellow, limited Red |

### 3.2 Prohibited Tools
- Personal/free-tier accounts of any AI service for work purposes
- AI tools without enterprise agreements or acceptable data handling terms
- Browser extensions that transmit code to unknown third parties
- Any AI tool not on the approved list without Security team approval

### 3.3 Tool Approval Process
To request approval for a new AI tool:
1. Submit request to Security team with vendor, use case, and data flow diagram
2. Security reviews data handling, retention policies, and compliance certifications
3. Legal reviews terms of service and licensing
4. Decision communicated within 10 business days

---

## 4. Data Handling Requirements

### 4.1 Prohibited Data (Never Input to AI Tools)

The following must NEVER be entered into any AI tool:

**Credentials & Secrets**
- Passwords, API keys, tokens, certificates
- Database connection strings
- AWS/Azure/GCP credentials
- SSH keys, encryption keys

**Personal Identifiable Information (PII)**
- Social Security Numbers, National ID numbers
- Credit card or bank account numbers
- Health records (PHI/HIPAA data)
- Biometric data
- Home addresses, personal phone numbers
- Any data subject to GDPR, CCPA, or similar regulations

**Restricted Business Data**
- Customer production data
- Non-public financial information
- M&A or strategic planning documents
- Security vulnerability details
- Penetration test results
- Legal hold or litigation materials

### 4.2 Data That Requires Sanitization

Before inputting to AI tools, the following must be sanitized:

| Data Type | Sanitization Required |
|-----------|----------------------|
| Database schemas | Remove/mask sensitive column names, use generic table names |
| Log files | Remove IPs, user IDs, session tokens, timestamps |
| Configuration files | Replace all secrets with `<PLACEHOLDER>` values |
| Error messages | Remove internal hostnames, file paths, user information |
| Code with business logic | Evaluate if competitively sensitive; generalize if needed |

**Sanitization Example**:

```
# BEFORE (NOT ALLOWED)
connection_string = "postgresql://admin:P@ssw0rd123@prod-db.company.internal:5432/customers"

# AFTER (ALLOWED)
connection_string = "postgresql://<USER>:<PASSWORD>@<HOST>:<PORT>/<DATABASE>"
```

### 4.3 Permitted Data

The following may be used with AI tools:
- Publicly available documentation and code
- Open-source libraries and frameworks
- Generic algorithms and design patterns
- Synthetic or properly anonymized test data
- Internal documentation not marked confidential
- Code that contains no secrets or sensitive business logic

---

## 5. Use Case Guidelines

### 5.1 Permitted Use Cases

**Code Development**
- Writing boilerplate code and utilities
- Generating unit tests and test data
- Code refactoring and optimization suggestions
- Learning new frameworks or languages
- Debugging assistance (with sanitized code)
- Documentation generation

**Analysis & Planning**
- Technical design discussions (without sensitive details)
- Reviewing architectural patterns
- Explaining complex technical concepts
- Generating meeting notes and summaries (non-confidential)

**Documentation**
- Creating technical documentation
- Writing user guides and runbooks
- Generating API documentation from code

### 5.2 Restricted Use Cases (Requires Approval)

The following require manager and Security team approval:
- Processing any customer-related data, even if anonymized
- Automated pipelines that send data to AI services
- Training or fine-tuning models on company data
- AI tools with access to production systems
- Use cases involving regulated data (financial, health)

### 5.3 Prohibited Use Cases

- Inputting any Red Zone data (see Section 4.1)
- Using AI to generate security exploits or malicious code
- Bypassing security controls or access restrictions
- Making automated decisions about individuals without human review
- Using AI outputs without review for legal, compliance, or financial matters
- Representing AI-generated content as original work without disclosure

---

## 6. Code Review & Quality Standards

### 6.1 AI-Generated Code Requirements

All AI-generated code must:

1. **Go through standard code review** - Same process as human-written code
2. **Be understood by the committer** - You must be able to explain what it does
3. **Be tested** - Unit tests required; AI-generated tests also need review
4. **Be attributed** - Use commit tags or comments for substantial AI-generated blocks

### 6.2 Review Checklist for AI-Generated Code

Reviewers should verify:
- [ ] No hardcoded secrets or sensitive data
- [ ] No license violations (check for copyleft snippets)
- [ ] Logic is correct and handles edge cases
- [ ] Security best practices followed (input validation, etc.)
- [ ] Consistent with project coding standards
- [ ] Dependencies are approved and up-to-date
- [ ] Adequate test coverage

### 6.3 Attribution Standards

For substantial AI-generated code blocks (>20 lines), add attribution:

```python
# AI-GENERATED: Initial implementation generated with Claude
# Reviewed and modified by: [Your Name], [Date]
# Modifications: Added error handling, fixed edge case for empty input
```

---

## 7. Intellectual Property & Licensing

### 7.1 Ownership
- Code generated by AI tools using company resources is company property
- Employees retain no special rights to AI-assisted work beyond standard employment terms

### 7.2 Third-Party IP Concerns
- AI tools may suggest code similar to open-source projects
- Review suggested code for potential license obligations
- When in doubt, rewrite in your own style or consult Legal
- Do not use AI to circumvent software licensing

### 7.3 Confidentiality
- AI prompts and outputs may be logged by service providers
- Treat interactions with AI tools as potentially non-confidential
- Never rely on AI tools to keep secrets

---

## 8. Incident Reporting

### 8.1 What to Report

Report immediately to Security team if:
- You accidentally input prohibited data to an AI tool
- You discover someone else has violated this policy
- You receive AI output that contains others' credentials or PII
- You suspect an AI tool has been compromised
- You identify a new risk not covered by this policy

### 8.2 How to Report
- Email: security@company.com
- Slack: #security-incidents
- Emergency: [Phone number]

### 8.3 Non-Retaliation
Good-faith reports of policy violations, including self-reports, will not result in punitive action. The goal is to identify and mitigate risks, not to punish honest mistakes.

---

## 9. Compliance & Enforcement

### 9.1 Monitoring
The company reserves the right to:
- Monitor AI tool usage through enterprise admin consoles
- Audit prompts and interactions for compliance
- Review code commits for policy adherence
- Implement technical controls to enforce this policy

### 9.2 Violations
Violations of this policy may result in:
- Revocation of AI tool access
- Mandatory retraining
- Disciplinary action up to and including termination
- Legal action in cases of willful misconduct

### 9.3 Exceptions
Exceptions to this policy require written approval from:
- Security team lead (for technical controls)
- Legal (for data handling exceptions)
- VP of Engineering (for process exceptions)

---

## 10. Training & Awareness

### 10.1 Required Training
All users of AI tools must complete:
- Initial AI security awareness training (before access granted)
- Annual refresher training
- Role-specific training for advanced use cases

### 10.2 Resources
- AI Tools Wiki: [Internal link]
- Prompt Library: [Internal link]
- Security FAQ: [Internal link]
- Office Hours: Thursdays 2-3 PM

---

## 11. Policy Review

This policy will be reviewed:
- Quarterly by Security and Engineering leadership
- Immediately following any significant incident
- When new AI tools or capabilities are introduced

---

## 12. Definitions

| Term | Definition |
|------|------------|
| AI Tool | Any software that uses machine learning or large language models to generate, analyze, or transform content |
| PII | Personally Identifiable Information - data that can identify an individual |
| PHI | Protected Health Information - health data protected under HIPAA |
| Sanitization | Process of removing or masking sensitive data before sharing |
| Red Zone Data | Highly sensitive data that must never be shared with AI tools |

---

## 13. Acknowledgment

By using AI tools for company work, you acknowledge that you have read, understood, and agree to comply with this policy.

---

## Appendix A: Quick Reference Card

### Before Using AI Tools - Ask Yourself:

```
┌─────────────────────────────────────────────────────────────┐
│  🔴 STOP - Does my prompt contain:                          │
│     • Passwords, API keys, tokens?                         │
│     • Customer PII or production data?                     │
│     • Confidential business information?                   │
│                                                            │
│  If YES → Do NOT proceed. Remove sensitive data first.     │
├─────────────────────────────────────────────────────────────┤
│  🟡 CAUTION - Have I:                                       │
│     • Sanitized database schemas and configs?              │
│     • Removed identifying information from logs?           │
│     • Masked internal hostnames and paths?                 │
│                                                            │
│  If NO → Sanitize data before proceeding.                  │
├─────────────────────────────────────────────────────────────┤
│  🟢 PROCEED - My prompt contains only:                      │
│     • Public information                                   │
│     • Generic code patterns                                │
│     • Properly sanitized data                              │
│                                                            │
│  → Safe to use approved AI tools                           │
└─────────────────────────────────────────────────────────────┘
```

### Emergency Contacts
- Security Team: security@company.com
- Data Privacy: privacy@company.com
- IT Help Desk: helpdesk@company.com

---

## Appendix B: Sanitization Templates

### Database Connection Strings
```
# Original (NEVER SHARE)
DB_URL=postgresql://svc_account:Pr0dP@ss!@prod-db-01.internal.company.com:5432/customers

# Sanitized (SAFE)
DB_URL=postgresql://<SERVICE_ACCOUNT>:<PASSWORD>@<HOSTNAME>:<PORT>/<DATABASE>
```

### AWS Configuration
```
# Original (NEVER SHARE)
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# Sanitized (SAFE)
aws_access_key_id = <AWS_ACCESS_KEY>
aws_secret_access_key = <AWS_SECRET_KEY>
```

### Log Files
```
# Original (NEVER SHARE)
2024-01-15 10:23:45 INFO User john.smith@company.com (ID: 12345) logged in from 192.168.1.100

# Sanitized (SAFE)
<TIMESTAMP> INFO User <EMAIL> (ID: <USER_ID>) logged in from <IP_ADDRESS>
```

### Error Messages
```
# Original (NEVER SHARE)
ConnectionError: Failed to connect to payment-gateway.internal.company.com:443 
using cert /etc/ssl/certs/payment-prod.pem

# Sanitized (SAFE)
ConnectionError: Failed to connect to <INTERNAL_SERVICE>:<PORT> 
using cert <CERTIFICATE_PATH>
```

---

## Appendix C: Approved Prompt Patterns

### Code Review Request
```
Review this [language] code for:
- Potential bugs or logic errors
- Security vulnerabilities
- Performance issues
- Adherence to best practices

[Paste sanitized code]
```

### Test Generation
```
Generate unit tests for the following function. 
Include edge cases for: [list edge cases]
Use [testing framework] syntax.

[Paste sanitized function]
```

### Documentation
```
Generate documentation for this [API/function/class] including:
- Purpose and description
- Parameters and return values
- Usage examples
- Error handling

[Paste sanitized code]
```

---

*Document Control: This document is controlled. Printed copies are for reference only.*
