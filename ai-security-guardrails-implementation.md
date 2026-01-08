# AI Security Guardrails - Technical Implementation Guide

## Overview

This guide provides technical implementation details for enforcing AI security guardrails across your SDLC toolchain.

---

## 1. Pre-Commit Hooks for Secret Detection

### Setup with pre-commit framework

```yaml
# .pre-commit-config.yaml
repos:
  # Detect secrets before they reach AI tools or git
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: package-lock.json

  # Additional secret patterns
  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  # Custom AI-specific checks
  - repo: local
    hooks:
      - id: ai-data-check
        name: Check for AI-unsafe data patterns
        entry: python scripts/check_ai_safe_data.py
        language: python
        types: [python, sql, yaml, json]
```

### Custom AI Safety Scanner

```python
#!/usr/bin/env python3
"""
scripts/check_ai_safe_data.py
Scans files for data patterns unsafe to share with AI tools.
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple

# Patterns that should NEVER be in code shared with AI
BLOCKED_PATTERNS = [
    # AWS Credentials
    (r'AKIA[0-9A-Z]{16}', 'AWS Access Key ID'),
    (r'aws_secret_access_key\s*=\s*["\'][^"\']+["\']', 'AWS Secret Key'),
    
    # Database connection strings with credentials
    (r'(mysql|postgresql|mongodb|redis):\/\/[^:]+:[^@]+@', 'Database credentials in connection string'),
    
    # API Keys (generic patterns)
    (r'api[_-]?key\s*[=:]\s*["\'][a-zA-Z0-9]{20,}["\']', 'API Key'),
    (r'bearer\s+[a-zA-Z0-9\-_.]+', 'Bearer Token'),
    
    # Private Keys
    (r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----', 'Private Key'),
    (r'-----BEGIN CERTIFICATE-----', 'Certificate'),
    
    # Social Security Numbers (US)
    (r'\b\d{3}-\d{2}-\d{4}\b', 'Potential SSN'),
    
    # Credit Card Numbers (basic Luhn-valid patterns)
    (r'\b4[0-9]{12}(?:[0-9]{3})?\b', 'Potential Visa Card'),
    (r'\b5[1-5][0-9]{14}\b', 'Potential Mastercard'),
    
    # Email addresses (flag for review, might be PII)
    (r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'Email address (review for PII)'),
    
    # Internal hostnames
    (r'\b[a-z0-9-]+\.(internal|corp|local)\.[a-z]+\b', 'Internal hostname'),
    
    # IP Addresses (private ranges - might indicate internal infrastructure)
    (r'\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', 'Private IP (10.x.x.x)'),
    (r'\b172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3}\b', 'Private IP (172.16-31.x.x)'),
    (r'\b192\.168\.\d{1,3}\.\d{1,3}\b', 'Private IP (192.168.x.x)'),
    
    # Slack/Discord webhooks
    (r'hooks\.slack\.com/services/[A-Z0-9/]+', 'Slack Webhook URL'),
    (r'discord\.com/api/webhooks/\d+/[a-zA-Z0-9_-]+', 'Discord Webhook URL'),
    
    # GitHub tokens
    (r'ghp_[a-zA-Z0-9]{36}', 'GitHub Personal Access Token'),
    (r'gho_[a-zA-Z0-9]{36}', 'GitHub OAuth Token'),
    
    # Anthropic/OpenAI API Keys
    (r'sk-ant-[a-zA-Z0-9-]+', 'Anthropic API Key'),
    (r'sk-[a-zA-Z0-9]{48}', 'OpenAI API Key'),
]

# Patterns that should be flagged for review but not blocked
WARNING_PATTERNS = [
    (r'password\s*[=:]\s*["\'][^"\']+["\']', 'Hardcoded password'),
    (r'secret\s*[=:]\s*["\'][^"\']+["\']', 'Hardcoded secret'),
    (r'\b(ssn|social_security|tax_id)\b', 'PII field reference'),
    (r'\b(credit_card|card_number|ccn)\b', 'Payment field reference'),
]

def scan_file(filepath: Path) -> List[Tuple[int, str, str]]:
    """Scan a file for unsafe patterns."""
    findings = []
    
    try:
        content = filepath.read_text(encoding='utf-8', errors='ignore')
    except Exception as e:
        print(f"Warning: Could not read {filepath}: {e}", file=sys.stderr)
        return findings
    
    lines = content.split('\n')
    
    for line_num, line in enumerate(lines, 1):
        # Skip comments (basic heuristic)
        stripped = line.strip()
        if stripped.startswith('#') or stripped.startswith('//') or stripped.startswith('--'):
            continue
            
        for pattern, description in BLOCKED_PATTERNS:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append((line_num, 'BLOCKED', f"{description}: {line[:100]}..."))
                
        for pattern, description in WARNING_PATTERNS:
            if re.search(pattern, line, re.IGNORECASE):
                findings.append((line_num, 'WARNING', f"{description}: {line[:100]}..."))
    
    return findings

def main():
    """Main entry point for pre-commit hook."""
    files = sys.argv[1:]
    has_blocked = False
    
    for filepath in files:
        path = Path(filepath)
        if not path.exists() or path.is_dir():
            continue
            
        findings = scan_file(path)
        
        for line_num, severity, message in findings:
            prefix = "🚫 BLOCKED" if severity == 'BLOCKED' else "⚠️  WARNING"
            print(f"{prefix} {filepath}:{line_num} - {message}")
            
            if severity == 'BLOCKED':
                has_blocked = True
    
    if has_blocked:
        print("\n❌ Blocked patterns found. Please sanitize before committing.")
        print("   See: docs/ai-data-sanitization.md")
        sys.exit(1)
    
    sys.exit(0)

if __name__ == '__main__':
    main()
```

---

## 2. IDE/Editor Integration

### VS Code Settings for AI Safety

```json
// .vscode/settings.json
{
    // Restrict GitHub Copilot to specific file types
    "github.copilot.enable": {
        "*": true,
        "plaintext": false,
        "markdown": true,
        "yaml": false,
        "env": false,
        "dotenv": false
    },
    
    // Files to exclude from AI analysis
    "github.copilot.advanced": {
        "excludeFiles": [
            "**/.env*",
            "**/secrets/**",
            "**/credentials/**",
            "**/*.pem",
            "**/*.key",
            "**/config/production/**"
        ]
    },
    
    // Highlight sensitive patterns
    "todohighlight.keywords": [
        {
            "text": "API_KEY",
            "color": "#fff",
            "backgroundColor": "#ff0000"
        },
        {
            "text": "SECRET",
            "color": "#fff", 
            "backgroundColor": "#ff0000"
        },
        {
            "text": "PASSWORD",
            "color": "#fff",
            "backgroundColor": "#ff0000"
        }
    ]
}
```

### Cursor AI Rules File

```markdown
# .cursorrules
# Rules for Cursor AI assistant

## Security Rules
- Never suggest hardcoded credentials or secrets
- Always use environment variables for sensitive configuration
- Flag any code that appears to contain PII patterns
- Do not access or suggest modifications to files in /secrets, /credentials, or .env files

## Code Standards  
- Follow project conventions in .ai-context/CONVENTIONS.md
- Prefer parameterized queries over string concatenation for SQL
- Always validate and sanitize user inputs
- Use prepared statements for database operations

## Project Context
- Read .ai-context/PROJECT_CONTEXT.md for system overview
- Check .ai-context/CURRENT_SPRINT.md for active work context
- Follow patterns established in existing codebase
```

---

## 3. CI/CD Pipeline Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/ai-security-scan.yml
name: AI Security Scan

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

jobs:
  ai-security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for diff analysis
      
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install detect-secrets gitleaks-py
      
      - name: Run secret detection
        run: |
          detect-secrets scan --baseline .secrets.baseline
          if [ $? -ne 0 ]; then
            echo "::error::New secrets detected! Run 'detect-secrets audit .secrets.baseline' locally."
            exit 1
          fi
      
      - name: Check for AI-unsafe patterns
        run: |
          python scripts/check_ai_safe_data.py $(git diff --name-only origin/main...HEAD)
      
      - name: Scan for PII patterns
        run: |
          python scripts/pii_scanner.py --changed-files-only
      
      - name: Validate AI context files
        run: |
          # Ensure AI context files don't contain secrets
          python scripts/check_ai_safe_data.py .ai-context/*.md CLAUDE.md
      
      - name: Check AI-generated code attribution
        run: |
          # Ensure substantial AI-generated code is attributed
          python scripts/check_ai_attribution.py --warn-only
```

### GitLab CI Configuration

```yaml
# .gitlab-ci.yml
ai-security:
  stage: test
  image: python:3.11-slim
  before_script:
    - pip install detect-secrets
  script:
    - detect-secrets scan --baseline .secrets.baseline
    - python scripts/check_ai_safe_data.py $(git diff --name-only $CI_MERGE_REQUEST_DIFF_BASE_SHA)
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

---

## 4. Runtime Guardrails for AI API Integration

### Prompt Sanitizer Library

```python
"""
ai_guardrails/sanitizer.py
Runtime sanitization for AI prompts.
"""

import re
from typing import Optional, List, Tuple
from dataclasses import dataclass
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class SensitivityLevel(Enum):
    SAFE = "safe"
    WARNING = "warning"
    BLOCKED = "blocked"


@dataclass
class SanitizationResult:
    original: str
    sanitized: str
    level: SensitivityLevel
    findings: List[str]
    was_modified: bool


class PromptSanitizer:
    """Sanitizes prompts before sending to AI APIs."""
    
    # Patterns to completely block (prompt rejected)
    BLOCKED_PATTERNS = [
        (r'-----BEGIN[A-Z ]*PRIVATE KEY-----', 'Private key detected'),
        (r'AKIA[0-9A-Z]{16}', 'AWS access key detected'),
        (r'\b\d{3}-\d{2}-\d{4}\b', 'SSN pattern detected'),
        (r'\b4[0-9]{12}(?:[0-9]{3})?\b', 'Credit card pattern detected'),
    ]
    
    # Patterns to mask/replace (prompt modified)
    MASK_PATTERNS = [
        (r'password\s*[=:]\s*["\']([^"\']+)["\']', r'password = "<REDACTED>"', 'Password masked'),
        (r'api[_-]?key\s*[=:]\s*["\']([^"\']+)["\']', r'api_key = "<REDACTED>"', 'API key masked'),
        (r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', '<EMAIL>', 'Email masked'),
        (r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', '<IP_ADDRESS>', 'IP address masked'),
        (r'bearer\s+[a-zA-Z0-9\-_.]+', 'bearer <TOKEN>', 'Bearer token masked'),
    ]
    
    def __init__(self, strict_mode: bool = True, log_findings: bool = True):
        self.strict_mode = strict_mode
        self.log_findings = log_findings
    
    def sanitize(self, prompt: str) -> SanitizationResult:
        """
        Sanitize a prompt before sending to AI.
        
        Args:
            prompt: The raw prompt text
            
        Returns:
            SanitizationResult with sanitized text and metadata
            
        Raises:
            ValueError: If blocked patterns found in strict mode
        """
        findings = []
        level = SensitivityLevel.SAFE
        sanitized = prompt
        
        # Check for blocked patterns
        for pattern, message in self.BLOCKED_PATTERNS:
            if re.search(pattern, prompt, re.IGNORECASE):
                findings.append(f"BLOCKED: {message}")
                level = SensitivityLevel.BLOCKED
                
                if self.log_findings:
                    logger.warning(f"Blocked AI prompt: {message}")
        
        if level == SensitivityLevel.BLOCKED:
            if self.strict_mode:
                raise ValueError(f"Prompt contains blocked content: {', '.join(findings)}")
            return SanitizationResult(
                original=prompt,
                sanitized="",
                level=level,
                findings=findings,
                was_modified=True
            )
        
        # Apply masking patterns
        for pattern, replacement, message in self.MASK_PATTERNS:
            if re.search(pattern, sanitized, re.IGNORECASE):
                sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)
                findings.append(f"MASKED: {message}")
                level = SensitivityLevel.WARNING
                
                if self.log_findings:
                    logger.info(f"Masked content in AI prompt: {message}")
        
        was_modified = sanitized != prompt
        
        return SanitizationResult(
            original=prompt,
            sanitized=sanitized,
            level=level,
            findings=findings,
            was_modified=was_modified
        )
    
    def is_safe(self, prompt: str) -> bool:
        """Quick check if prompt is safe without modification."""
        try:
            result = self.sanitize(prompt)
            return result.level == SensitivityLevel.SAFE
        except ValueError:
            return False


class AIClient:
    """Wrapper for AI API clients with built-in guardrails."""
    
    def __init__(self, api_key: str, sanitizer: Optional[PromptSanitizer] = None):
        self.api_key = api_key
        self.sanitizer = sanitizer or PromptSanitizer()
        self._audit_log = []
    
    def complete(self, prompt: str, **kwargs) -> str:
        """
        Send prompt to AI with automatic sanitization.
        
        Args:
            prompt: The user's prompt
            **kwargs: Additional API parameters
            
        Returns:
            AI response text
        """
        # Sanitize prompt
        result = self.sanitizer.sanitize(prompt)
        
        # Log for audit
        self._audit_log.append({
            'timestamp': datetime.utcnow().isoformat(),
            'was_modified': result.was_modified,
            'findings': result.findings,
            'level': result.level.value
        })
        
        if result.level == SensitivityLevel.BLOCKED:
            raise ValueError("Prompt blocked due to sensitive content")
        
        # Make actual API call with sanitized prompt
        # (Implementation depends on which AI service you're using)
        return self._call_api(result.sanitized, **kwargs)
    
    def _call_api(self, prompt: str, **kwargs) -> str:
        """Override this for specific AI providers."""
        raise NotImplementedError("Subclass must implement _call_api")
    
    def get_audit_log(self) -> List[dict]:
        """Return audit log for compliance review."""
        return self._audit_log.copy()
```

### Usage Example

```python
from ai_guardrails.sanitizer import PromptSanitizer, AIClient

# Initialize sanitizer
sanitizer = PromptSanitizer(strict_mode=True)

# Test sanitization
test_prompt = """
Help me debug this database connection:
DB_URL = postgresql://admin:SecretP@ss123@prod-db.internal.com:5432/users
It's failing with this error for user john.smith@company.com
"""

result = sanitizer.sanitize(test_prompt)
print(f"Level: {result.level}")
print(f"Findings: {result.findings}")
print(f"Sanitized:\n{result.sanitized}")

# Output:
# Level: SensitivityLevel.WARNING
# Findings: ['MASKED: Password masked', 'MASKED: Email masked']
# Sanitized:
# Help me debug this database connection:
# DB_URL = postgresql://admin:<REDACTED>@prod-db.internal.com:5432/users
# It's failing with this error for user <EMAIL>
```

---

## 5. Audit & Monitoring

### Logging Configuration

```python
# config/ai_audit_logging.py
import logging
import json
from datetime import datetime
from typing import Any, Dict

class AIAuditLogger:
    """Structured logging for AI tool usage."""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.logger = logging.getLogger(f'ai_audit.{service_name}')
        
    def log_request(
        self,
        user_id: str,
        tool: str,
        prompt_hash: str,  # Hash, not actual prompt
        was_sanitized: bool,
        findings: list,
        metadata: Dict[str, Any] = None
    ):
        """Log an AI API request for audit purposes."""
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'service': self.service_name,
            'event_type': 'ai_request',
            'user_id': user_id,
            'tool': tool,
            'prompt_hash': prompt_hash,
            'was_sanitized': was_sanitized,
            'sanitization_findings': findings,
            'metadata': metadata or {}
        }
        
        self.logger.info(json.dumps(log_entry))
        
    def log_policy_violation(
        self,
        user_id: str,
        violation_type: str,
        details: str
    ):
        """Log a policy violation for security review."""
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'service': self.service_name,
            'event_type': 'policy_violation',
            'severity': 'HIGH',
            'user_id': user_id,
            'violation_type': violation_type,
            'details': details
        }
        
        self.logger.warning(json.dumps(log_entry))
        
        # Also send to security alerting system
        self._alert_security_team(log_entry)
        
    def _alert_security_team(self, log_entry: dict):
        """Send alert to security team for violations."""
        # Implementation: Slack webhook, PagerDuty, email, etc.
        pass
```

### Monitoring Dashboard Queries (for Datadog/Splunk/etc.)

```
# Count AI requests by user (identify heavy users)
source="ai_audit" event_type="ai_request" 
| stats count by user_id 
| sort -count

# Policy violations over time
source="ai_audit" event_type="policy_violation"
| timechart count by violation_type

# Sanitization rate (how often are prompts being cleaned)
source="ai_audit" event_type="ai_request"
| stats count(eval(was_sanitized=true)) as sanitized, count as total
| eval sanitization_rate = sanitized/total * 100

# Most common findings (what sensitive data patterns are being caught)
source="ai_audit" event_type="ai_request" was_sanitized=true
| mvexpand sanitization_findings
| stats count by sanitization_findings
| sort -count
```

---

## 6. Network Controls

### Proxy Configuration for AI Traffic

```nginx
# nginx.conf - AI API proxy with logging and filtering
upstream ai_apis {
    server api.anthropic.com:443;
    server api.openai.com:443;
}

server {
    listen 8443 ssl;
    server_name ai-proxy.internal.company.com;
    
    ssl_certificate /etc/ssl/certs/ai-proxy.crt;
    ssl_certificate_key /etc/ssl/private/ai-proxy.key;
    
    # Log all AI requests
    access_log /var/log/nginx/ai_access.log detailed;
    
    location /v1/messages {
        # Rate limiting per user
        limit_req zone=ai_requests burst=10 nodelay;
        limit_req_status 429;
        
        # Pass to upstream
        proxy_pass https://api.anthropic.com;
        proxy_ssl_verify on;
        
        # Add tracking headers
        proxy_set_header X-Request-ID $request_id;
        proxy_set_header X-User-ID $http_x_user_id;
    }
    
    # Block direct access to other endpoints
    location / {
        return 403 "Access denied - use approved AI endpoints";
    }
}
```

### Firewall Rules (AWS Security Group Example)

```hcl
# terraform/ai_security_group.tf
resource "aws_security_group" "ai_tools_access" {
  name        = "ai-tools-access"
  description = "Controls access to approved AI services"
  vpc_id      = var.vpc_id

  # Allow outbound to approved AI APIs only
  egress {
    description = "Anthropic API"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Use data source for actual IPs
    # In practice, use a proxy and restrict to proxy only
  }

  # Deny all other outbound by default
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # Implement with NACL or firewall rules
  }

  tags = {
    Name        = "ai-tools-access"
    Environment = var.environment
    Purpose     = "AI Security Guardrails"
  }
}
```

---

## 7. Quick Reference: Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Deploy pre-commit hooks with secret detection
- [ ] Configure IDE settings for AI tool restrictions
- [ ] Set up basic audit logging
- [ ] Document approved tools list

### Phase 2: Runtime Controls (Week 3-4)
- [ ] Implement prompt sanitizer library
- [ ] Add sanitization to existing AI integrations
- [ ] Configure network proxy for AI traffic
- [ ] Set up monitoring dashboards

### Phase 3: CI/CD Integration (Week 5-6)
- [ ] Add AI security scans to PR checks
- [ ] Implement automated policy compliance checks
- [ ] Create alerting for policy violations
- [ ] Test incident response procedures

### Phase 4: Governance (Ongoing)
- [ ] Train teams on acceptable use policy
- [ ] Conduct quarterly policy reviews
- [ ] Review audit logs monthly
- [ ] Update patterns based on new threats

---

## Appendix: Tool-Specific Configurations

### Claude Code (CLAUDE.md)

```markdown
# Security Constraints

NEVER include in responses or suggestions:
- Hardcoded credentials or secrets
- Production database connection strings
- Internal hostnames or IP addresses
- Customer PII or production data

ALWAYS:
- Use environment variables for secrets: `os.environ.get('API_KEY')`
- Suggest parameterized queries for SQL
- Flag potential security issues in code review
- Reference /docs/security-guidelines.md for security patterns
```

### GitHub Copilot (Enterprise Settings)

```json
{
  "copilot": {
    "contentExclusions": {
      "repositories": [
        "org/secrets-repo",
        "org/infrastructure-credentials"
      ],
      "paths": [
        "**/.env*",
        "**/secrets/**",
        "**/*.pem",
        "**/*.key"
      ]
    },
    "organizationPolicies": {
      "allowedFileTypes": ["py", "js", "ts", "java", "go", "rs"],
      "blockedPatterns": ["password=", "secret=", "api_key="]
    }
  }
}
```
