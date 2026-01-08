# Before/After Comparison & ROI Calculator

## 1. Metrics Comparison Report Template

```markdown
# AI Adoption Impact Report
**Report Date**: [Date]
**Baseline Period**: [Start] to [End]
**Current Period**: [Start] to [End]
**Team**: [Team Name]
**Team Size**: [Number]

---

## Executive Summary

| Category | Baseline | Current | Change | Target | Status |
|----------|----------|---------|--------|--------|--------|
| Velocity (SP/Sprint) | | | % | +20% | ⬜ |
| Defect Rate (bugs/SP) | | | % | -25% | ⬜ |
| PR Review Time (hrs) | | | % | -30% | ⬜ |
| Test Coverage (%) | | | pts | +15% | ⬜ |
| Dev Satisfaction (1-10) | | | pts | +1.5 | ⬜ |
| AI Adoption Rate (%) | 0% | | - | 80% | ⬜ |

**Overall Assessment**: [On Track / Needs Attention / Exceeding Expectations]

---

## Detailed Metrics Comparison

### Velocity Metrics

| Metric | Baseline | Current | Change | Trend |
|--------|----------|---------|--------|-------|
| Story Points/Sprint | | | | |
| Cycle Time (days) | | | | |
| Lead Time (days) | | | | |
| Deployment Frequency | | | | |
| Commits/Developer/Week | | | | |

**Velocity Trend Chart**
```
Sprint:     S1    S2    S3    S4    S5    S6    S7    S8
Baseline:   ████  ████  ████  ████  
Current:                            ████  █████ █████ ██████
```

### Quality Metrics

| Metric | Baseline | Current | Change | Trend |
|--------|----------|---------|--------|-------|
| Defect Rate | | | | |
| Defect Escape Rate | | | | |
| Test Coverage | | | | |
| Code Review Issues/PR | | | | |
| MTTR (hours) | | | | |

### Efficiency Metrics

| Metric | Baseline | Current | Change | Trend |
|--------|----------|---------|--------|-------|
| PR Review Time | | | | |
| Time to First Review | | | | |
| Documentation Time/Doc | | | | |
| Test Writing Time | | | | |
| Debug Time/Bug | | | | |

### Developer Experience

| Metric | Baseline | Current | Change |
|--------|----------|---------|--------|
| Overall Satisfaction | | | |
| Productivity Rating | | | |
| Tool Usefulness | | | |
| NPS Score | | | |

---

## Time Savings Analysis

### Per Developer (Weekly)

| Activity | Before (hrs) | After (hrs) | Saved (hrs) | % Reduction |
|----------|-------------|-------------|-------------|-------------|
| Code Writing | | | | |
| Debugging | | | | |
| Documentation | | | | |
| Test Writing | | | | |
| Code Review | | | | |
| Research/Learning | | | | |
| **Total** | | | | |

### Team Total (Monthly)

| Metric | Calculation | Value |
|--------|-------------|-------|
| Hours saved/dev/week | | |
| Hours saved/dev/month | × 4 | |
| Team hours saved/month | × team size | |
| Annual hours saved | × 12 | |

---

## Quality Impact Analysis

### Defect Comparison

| Period | Bugs Created | Bugs in Prod | Escape Rate | Severity Distribution |
|--------|-------------|--------------|-------------|----------------------|
| Baseline | | | | Crit:__ High:__ Med:__ Low:__ |
| Current | | | | Crit:__ High:__ Med:__ Low:__ |

### Code Quality Indicators

| Indicator | Baseline | Current | Change |
|-----------|----------|---------|--------|
| Test Coverage | | | |
| Code Duplication % | | | |
| Technical Debt (hrs) | | | |
| Security Issues | | | |

---

## ROI Calculation

### Costs

| Item | Monthly Cost | Annual Cost |
|------|-------------|-------------|
| AI Tool Licenses | $ | $ |
| Training Time | $ | $ |
| Infrastructure | $ | $ |
| **Total Costs** | $ | $ |

### Benefits

| Item | Monthly Value | Annual Value | Calculation |
|------|--------------|--------------|-------------|
| Developer Time Saved | $ | $ | hours × rate |
| Faster Time to Market | $ | $ | estimated |
| Reduced Bug Fixes | $ | $ | bugs × cost/bug |
| Reduced Tech Debt | $ | $ | hours × rate |
| **Total Benefits** | $ | $ | |

### ROI Summary

| Metric | Value |
|--------|-------|
| Total Annual Cost | $ |
| Total Annual Benefit | $ |
| Net Annual Benefit | $ |
| **ROI** | % |
| Payback Period | months |

---

## Qualitative Insights

### What's Working Well
1. 
2. 
3. 

### Areas for Improvement
1. 
2. 
3. 

### Team Feedback Highlights
> "[Positive quote]" - Developer

> "[Constructive quote]" - Developer

---

## Recommendations

### Continue
- 

### Start
- 

### Stop
- 

---

## Next Steps

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| | | | |
| | | | |
| | | | |

---

**Report Prepared By**: [Name]
**Next Report Date**: [Date]
```

---

## 2. ROI Calculator Spreadsheet Structure

```markdown
# AI Adoption ROI Calculator

## Sheet 1: Input Parameters

### Team Information
| Parameter | Value | Notes |
|-----------|-------|-------|
| Team Size | | Number of developers |
| Avg Hourly Rate | $ | Fully loaded cost |
| Working Hours/Month | | Typically 160-176 |
| Baseline Period (months) | | Minimum 1 |
| Measurement Period (months) | | |

### AI Tool Costs
| Item | Monthly Cost | Notes |
|------|-------------|-------|
| Claude Enterprise | $ | Per seat × seats |
| GitHub Copilot | $ | Per seat × seats |
| Other Tools | $ | |
| Infrastructure | $ | |
| Training (one-time) | $ | Amortized |
| **Total Monthly** | $ | =SUM |

### Time Allocation (Baseline - hrs/week/dev)
| Activity | Hours | % of Time |
|----------|-------|-----------|
| Writing Code | | |
| Debugging | | |
| Code Review | | |
| Documentation | | |
| Testing | | |
| Meetings | | |
| Other | | |
| **Total** | 40 | 100% |

### Time Savings Estimates (%)
| Activity | Estimated Reduction | Confidence |
|----------|-------------------|------------|
| Writing Code | % | High/Med/Low |
| Debugging | % | |
| Code Review | % | |
| Documentation | % | |
| Testing | % | |

---

## Sheet 2: Calculations

### Time Savings

```
Hours Saved per Developer per Week:
= (Code Hours × Code Reduction %) 
+ (Debug Hours × Debug Reduction %)
+ (Review Hours × Review Reduction %)
+ (Doc Hours × Doc Reduction %)
+ (Test Hours × Test Reduction %)

Monthly Hours Saved per Dev = Weekly Hours × 4.33
Team Monthly Hours Saved = Per Dev × Team Size
Annual Hours Saved = Monthly × 12
```

### Dollar Value of Time Saved

```
Monthly Value = Team Monthly Hours × Hourly Rate
Annual Value = Annual Hours × Hourly Rate
```

### Quality Improvements

```
Bug Reduction Value:
= (Baseline Bugs - Current Bugs) × Avg Cost per Bug

Cost per Bug = Hours to Fix × Hourly Rate
Typical: 4-16 hours depending on severity
```

### Productivity Gains

```
Velocity Improvement Value:
= Additional Story Points × Value per Story Point

Estimate Value per SP based on:
- Revenue impact
- Cost avoidance
- Strategic value
```

---

## Sheet 3: ROI Summary

### Investment

| Category | Year 1 | Year 2 | Year 3 |
|----------|--------|--------|--------|
| Tool Licenses | $ | $ | $ |
| Training | $ | $ | $ |
| Implementation | $ | - | - |
| **Total Investment** | $ | $ | $ |

### Returns

| Category | Year 1 | Year 2 | Year 3 |
|----------|--------|--------|--------|
| Time Savings | $ | $ | $ |
| Quality Improvements | $ | $ | $ |
| Productivity Gains | $ | $ | $ |
| **Total Returns** | $ | $ | $ |

### Metrics

| Metric | Value | Formula |
|--------|-------|---------|
| Net Benefit (Y1) | $ | Returns - Investment |
| ROI (Y1) | % | (Net Benefit / Investment) × 100 |
| Payback Period | months | Investment / Monthly Benefit |
| 3-Year NPV | $ | DCF calculation |
| 3-Year ROI | % | Total Net / Total Investment |

---

## Sheet 4: Sensitivity Analysis

### Time Savings Scenarios

| Scenario | Reduction | Annual Value | ROI |
|----------|-----------|--------------|-----|
| Conservative | 15% | $ | % |
| Expected | 25% | $ | % |
| Optimistic | 40% | $ | % |

### Break-Even Analysis

| Variable | Break-Even Point |
|----------|-----------------|
| Min Time Savings | % reduction needed |
| Min Adoption Rate | % of team |
| Max Tool Cost | $ per month |

---

## Sheet 5: Tracking Dashboard

### Monthly Tracking

| Month | Hrs Saved | $ Value | Costs | Net | Cumulative |
|-------|----------|---------|-------|-----|------------|
| M1 | | | | | |
| M2 | | | | | |
| M3 | | | | | |
| ... | | | | | |
| M12 | | | | | |
| **Total** | | | | | |

### Forecast vs Actual

| Metric | Forecast | Actual | Variance |
|--------|----------|--------|----------|
| Time Saved | | | |
| Cost Savings | | | |
| Quality Improvement | | | |
| Adoption Rate | | | |
```

---

## 3. Quick ROI Estimation Formula

For rapid estimation:

```
Monthly ROI = ((Team Size × Hours Saved/Dev × Hourly Rate) - Tool Cost) / Tool Cost × 100

Example:
- Team: 10 developers
- Hours saved: 10 hrs/dev/week = 43 hrs/month
- Hourly rate: $75
- Tool cost: $5,000/month

Monthly Value = 10 × 43 × $75 = $32,250
Monthly Cost = $5,000
Net Monthly Benefit = $27,250
Monthly ROI = ($27,250 / $5,000) × 100 = 545%
Annual ROI = (($27,250 × 12) / ($5,000 × 12)) × 100 = 545%
Payback Period = $5,000 / $27,250 = 0.18 months ≈ 5 days
```

---

## 4. Benchmark Comparisons

### Industry Benchmarks (from various studies)

| Metric | Industry Average | Top Performers | Your Team |
|--------|-----------------|----------------|-----------|
| Developer productivity gain | 25-30% | 40-55% | |
| Time saved on code writing | 30-40% | 50%+ | |
| Time saved on debugging | 20-30% | 40%+ | |
| Test coverage improvement | 15-20% | 30%+ | |
| Code review time reduction | 30-40% | 50%+ | |
| Defect rate reduction | 20-30% | 40%+ | |

### Adoption Benchmarks

| Milestone | Timeline | Your Progress |
|-----------|----------|---------------|
| Initial training complete | Week 2 | |
| 50% daily usage | Month 1 | |
| 80% daily usage | Month 2 | |
| Measurable productivity gain | Month 3 | |
| Full ROI realization | Month 6 | |

---

## 5. Presentation Template

### Executive Summary Slide

```
┌────────────────────────────────────────────────────────────┐
│         AI ADOPTION ROI SUMMARY                            │
│         [Team/Organization] | [Date]                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│   INVESTMENT          RETURNS           NET IMPACT         │
│   ┌──────────┐       ┌──────────┐      ┌──────────┐       │
│   │ $60,000  │   →   │ $387,000 │  =   │ $327,000 │       │
│   │ /year    │       │ /year    │      │ /year    │       │
│   └──────────┘       └──────────┘      └──────────┘       │
│                                                            │
│   ┌─────────────────────────────────────────────────────┐ │
│   │ ROI: 545%  │  Payback: 5 days  │  Hours Saved: 5,160│ │
│   └─────────────────────────────────────────────────────┘ │
│                                                            │
│   KEY WINS:                                                │
│   • 35% faster code delivery                              │
│   • 40% reduction in bugs                                 │
│   • 85% team adoption                                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```
