# AI Prompt Templates Library

A curated collection of prompt templates for AI-assisted software development across the SDLC.

## Organization

```
prompt-templates-library/
├── README.md                    # This file
├── 01-requirements-analysis/    # Requirements gathering & analysis
├── 02-design-architecture/      # System design & architecture
├── 03-development/              # Code generation & development
├── 04-code-review/              # Code review & quality
├── 05-testing/                  # Test generation & QA
├── 06-documentation/            # Documentation generation
├── 07-deployment/               # CI/CD & deployment
├── 08-maintenance/              # Operations & maintenance
├── 09-data-engineering/         # Data pipelines & warehousing
└── meta/                        # Prompt engineering guidelines
```

## Usage Guidelines

### Template Variables
Templates use `{VARIABLE_NAME}` syntax for placeholders:
- `{CONTEXT}` - Project/domain context
- `{CODE}` - Code snippet to analyze
- `{REQUIREMENTS}` - Business requirements
- `{TECH_STACK}` - Technology stack details

### Best Practices
1. **Always provide context** - Include relevant project information
2. **Be specific** - Vague prompts yield vague results
3. **Iterate** - Start broad, then narrow down
4. **Sanitize first** - Remove secrets/PII before using templates
5. **Review output** - AI suggestions need human validation

### Quality Ratings
Each template includes effectiveness ratings:
- ⭐⭐⭐⭐⭐ Highly effective, minimal iteration needed
- ⭐⭐⭐⭐ Effective, occasional refinement needed
- ⭐⭐⭐ Moderately effective, expect iteration
- ⭐⭐ Situational, requires careful context
- ⭐ Experimental, results vary

## Contributing
1. Test template with at least 3 different scenarios
2. Document expected output quality
3. Include example input/output
4. Submit PR with template and metadata

## Version History
- v1.0.0 - Initial library release
- Updated: [DATE]
