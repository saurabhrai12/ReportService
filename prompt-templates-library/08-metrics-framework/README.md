# AI Adoption Metrics Tracking Framework

## Overview

This framework provides a comprehensive approach to measuring the impact of AI tools on software development lifecycle. It establishes baseline metrics, tracks improvements, and provides data-driven insights for continuous optimization.

---

## 1. Metrics Categories

### 1.1 Velocity Metrics
Measure development speed and throughput.

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **Story Points per Sprint** | Work completed per sprint | Sum of completed story points | +15-25% |
| **Cycle Time** | Time from work started to deployed | End date - Start date | -20-30% |
| **Lead Time** | Time from request to delivery | Delivery date - Request date | -15-25% |
| **Deployment Frequency** | How often code is deployed | Deployments per week/month | +25-50% |
| **Code Throughput** | Lines of code / commits per developer | LOC or commits / developer / week | +20-30% |

### 1.2 Quality Metrics
Measure code and product quality.

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **Defect Rate** | Bugs per unit of work | Bugs / Story Points delivered | -25-40% |
| **Defect Escape Rate** | Bugs found in production vs total | Prod bugs / Total bugs | -30-50% |
| **Code Review Defects** | Issues found in code review | Review comments (bugs) / PR | -20-30% |
| **Test Coverage** | Code covered by tests | Covered lines / Total lines | +15-25% |
| **Technical Debt Ratio** | Debt remediation time vs dev time | Debt hours / Total dev hours | -20-30% |
| **Mean Time to Recovery (MTTR)** | Time to recover from failures | Avg recovery time | -25-40% |

### 1.3 Efficiency Metrics
Measure time savings and productivity.

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **Code Review Time** | Time to complete PR review | Review end - Review start | -30-50% |
| **PR Merge Time** | Time from PR open to merge | Merge time - Open time | -25-40% |
| **Documentation Time** | Time spent writing docs | Hours per doc artifact | -40-60% |
| **Test Writing Time** | Time to write test cases | Hours per test suite | -30-50% |
| **Debug Time** | Time spent debugging issues | Hours per bug fixed | -20-35% |
| **Onboarding Time** | Time for new dev to be productive | Days to first meaningful PR | -25-40% |

### 1.4 Developer Experience Metrics
Measure team satisfaction and adoption.

| Metric | Description | Measurement Method | Target |
|--------|-------------|-------------------|--------|
| **Developer Satisfaction** | Overall happiness with AI tools | Survey (1-10 scale) | ≥7.5 |
| **AI Tool Adoption Rate** | % of team actively using AI | Usage logs / Team size | ≥80% |
| **Tool Usefulness Rating** | Perceived value of AI assistance | Survey (1-10 scale) | ≥7.0 |
| **Context Switch Reduction** | Fewer interruptions for help | Survey / Observation | -30% |
| **Learning Curve** | Time to proficiency with AI tools | Days to regular usage | <5 days |

---

## 2. Data Collection Methods

### 2.1 Data Sources Mapping

| Metric | Primary Source | Secondary Source | Collection Method |
|--------|---------------|------------------|-------------------|
| Story Points | Jira/Azure DevOps | Sprint Reports | API/Export |
| Cycle Time | Jira/Azure DevOps | Git commits | API |
| Deployment Frequency | CI/CD (Jenkins/GitHub Actions) | Release notes | API/Logs |
| Defect Rate | Jira (Bug issues) | Support tickets | API/Export |
| Code Review Time | GitHub/GitLab | PR analytics | API |
| Test Coverage | SonarQube/CodeCov | CI reports | API |
| Developer Satisfaction | Surveys | 1:1 feedback | Forms |
| AI Usage | Usage logs | IDE plugins | Custom tracking |

### 2.2 Collection Frequency

| Metric Type | Collection Frequency | Reporting Frequency |
|-------------|---------------------|---------------------|
| Velocity | Per sprint | Sprint/Monthly |
| Quality | Continuous | Weekly/Monthly |
| Efficiency | Continuous | Weekly/Monthly |
| Developer Experience | Weekly pulse, Monthly full | Monthly/Quarterly |
| AI Usage | Continuous | Weekly/Monthly |

---

## 3. Baseline Measurement

### 3.1 Pre-AI Baseline Checklist

- [ ] Define measurement period (minimum 4 weeks)
- [ ] Identify all data sources
- [ ] Configure API access to tools (Jira, GitHub, etc.)
- [ ] Deploy data collection scripts
- [ ] Distribute baseline developer survey
- [ ] Document current processes and workflows
- [ ] Establish data quality checks

### 3.2 Baseline Data Template

```markdown
# Baseline Metrics - [Team Name]
# Period: [Start] to [End]

## Velocity
- Avg Story Points/Sprint: ___
- Avg Cycle Time: ___ days
- Deployment Frequency: ___/week

## Quality  
- Defect Rate: ___/story point
- Escape Rate: ___%
- Test Coverage: ___%

## Efficiency
- Avg PR Review Time: ___ hours
- Avg PR Merge Time: ___ hours
- Avg Debug Time: ___ hours/bug

## Developer Experience
- Productivity Satisfaction: ___/10
- Code Review Satisfaction: ___/10
- Documentation Satisfaction: ___/10
```

---

## 4. Tracking Dashboard

### 4.1 Executive Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AI ADOPTION IMPACT DASHBOARD                         │
│                    Period: [Date Range]                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  VELOCITY                    QUALITY                   EFFICIENCY       │
│  ┌─────────────┐            ┌─────────────┐          ┌─────────────┐   │
│  │ Story Pts   │            │ Defect Rate │          │ Review Time │   │
│  │   +23%  ↑   │            │   -35%  ↓   │          │   -42%  ↓   │   │
│  │ 45 → 55/spr │            │ 2.1 → 1.4/sp│          │ 4.2 → 2.4 hr│   │
│  └─────────────┘            └─────────────┘          └─────────────┘   │
│                                                                         │
│  ADOPTION                    SATISFACTION             ROI               │
│  ┌─────────────┐            ┌─────────────┐          ┌─────────────┐   │
│  │ Tool Usage  │            │ Dev NPS     │          │ Time Saved  │   │
│  │    85%      │            │  8.2/10     │          │  125 hrs/mo │   │
│  │ 17/20 devs  │            │ (+1.8 pts)  │          │  ($15,625)  │   │
│  └─────────────┘            └─────────────┘          └─────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Key Metrics Definitions

| Metric | Formula | Good | Warning | Critical |
|--------|---------|------|---------|----------|
| Velocity Change | (Current - Baseline) / Baseline | >15% | 5-15% | <5% |
| Defect Reduction | (Baseline - Current) / Baseline | >25% | 10-25% | <10% |
| Review Time Reduction | (Baseline - Current) / Baseline | >30% | 15-30% | <15% |
| Adoption Rate | Active Users / Total Team | >80% | 50-80% | <50% |
| Developer NPS | Promoters% - Detractors% | >30 | 0-30 | <0 |

---

## 5. Data Collection Scripts

### 5.1 Jira Metrics Collector (Python)

```python
#!/usr/bin/env python3
"""Collect velocity and quality metrics from Jira."""

import os
import requests
from datetime import datetime, timedelta
from dataclasses import dataclass

@dataclass
class SprintMetrics:
    sprint_name: str
    story_points_completed: float
    stories_completed: int
    bugs_created: int
    avg_cycle_time_days: float

class JiraCollector:
    def __init__(self, base_url: str, email: str, token: str):
        self.base_url = base_url
        self.auth = (email, token)
        self.headers = {"Accept": "application/json"}
    
    def get_sprint_velocity(self, board_id: int, num_sprints: int = 4):
        """Get velocity for recent sprints."""
        sprints = self._get_closed_sprints(board_id, num_sprints)
        
        velocities = []
        for sprint in sprints:
            issues = self._get_sprint_issues(sprint['id'])
            points = sum(self._get_story_points(i) for i in issues 
                        if i['fields']['status']['name'] == 'Done')
            velocities.append({
                'sprint': sprint['name'],
                'points': points
            })
        
        return velocities
    
    def get_defect_rate(self, project: str, days: int = 30):
        """Calculate defect rate for period."""
        since = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        
        # Get completed work
        jql = f'project={project} AND issuetype in (Story, Task) AND status=Done AND resolved >= {since}'
        completed = self._search(jql)
        total_points = sum(self._get_story_points(i) for i in completed)
        
        # Get bugs
        jql = f'project={project} AND issuetype=Bug AND created >= {since}'
        bugs = self._search(jql)
        
        return {
            'bugs': len(bugs),
            'story_points': total_points,
            'defect_rate': len(bugs) / total_points if total_points else 0
        }
    
    def _get_closed_sprints(self, board_id, limit):
        url = f"{self.base_url}/rest/agile/1.0/board/{board_id}/sprint"
        resp = requests.get(url, auth=self.auth, headers=self.headers,
                           params={'state': 'closed', 'maxResults': limit})
        return resp.json().get('values', [])
    
    def _get_sprint_issues(self, sprint_id):
        url = f"{self.base_url}/rest/agile/1.0/sprint/{sprint_id}/issue"
        resp = requests.get(url, auth=self.auth, headers=self.headers)
        return resp.json().get('issues', [])
    
    def _search(self, jql):
        url = f"{self.base_url}/rest/api/3/search"
        resp = requests.get(url, auth=self.auth, headers=self.headers,
                           params={'jql': jql, 'maxResults': 1000})
        return resp.json().get('issues', [])
    
    def _get_story_points(self, issue):
        return issue['fields'].get('customfield_10016') or 0


# Usage
if __name__ == '__main__':
    collector = JiraCollector(
        os.environ['JIRA_URL'],
        os.environ['JIRA_EMAIL'],
        os.environ['JIRA_TOKEN']
    )
    
    velocity = collector.get_sprint_velocity(board_id=1)
    print(f"Velocity: {velocity}")
    
    defects = collector.get_defect_rate('PROJ')
    print(f"Defect Rate: {defects['defect_rate']:.2f}")
```

### 5.2 GitHub PR Metrics Collector (Python)

```python
#!/usr/bin/env python3
"""Collect PR and code review metrics from GitHub."""

import os
import requests
from datetime import datetime, timedelta
from statistics import mean

class GitHubCollector:
    def __init__(self, token: str, owner: str, repo: str):
        self.headers = {"Authorization": f"Bearer {token}"}
        self.base_url = f"https://api.github.com/repos/{owner}/{repo}"
    
    def get_pr_metrics(self, days: int = 30):
        """Get PR metrics for period."""
        since = datetime.now() - timedelta(days=days)
        prs = self._get_merged_prs(since)
        
        review_times = []
        merge_times = []
        sizes = []
        
        for pr in prs:
            created = datetime.fromisoformat(pr['created_at'].replace('Z', '+00:00'))
            merged = datetime.fromisoformat(pr['merged_at'].replace('Z', '+00:00'))
            
            # Time to merge (hours)
            merge_time = (merged - created).total_seconds() / 3600
            merge_times.append(merge_time)
            
            # Get first review time
            reviews = self._get_reviews(pr['number'])
            if reviews:
                first_review = min(
                    datetime.fromisoformat(r['submitted_at'].replace('Z', '+00:00'))
                    for r in reviews if r.get('submitted_at')
                )
                review_time = (first_review - created).total_seconds() / 3600
                review_times.append(review_time)
            
            # PR size
            sizes.append(pr['additions'] + pr['deletions'])
        
        return {
            'total_prs': len(prs),
            'avg_merge_time_hours': mean(merge_times) if merge_times else 0,
            'avg_review_time_hours': mean(review_times) if review_times else 0,
            'avg_pr_size': mean(sizes) if sizes else 0
        }
    
    def _get_merged_prs(self, since):
        prs = []
        page = 1
        while True:
            resp = requests.get(
                f"{self.base_url}/pulls",
                headers=self.headers,
                params={'state': 'closed', 'per_page': 100, 'page': page}
            )
            batch = resp.json()
            if not batch:
                break
            
            for pr in batch:
                if pr['merged_at']:
                    merged = datetime.fromisoformat(pr['merged_at'].replace('Z', '+00:00'))
                    if merged >= since.replace(tzinfo=merged.tzinfo):
                        prs.append(pr)
            page += 1
        return prs
    
    def _get_reviews(self, pr_number):
        resp = requests.get(
            f"{self.base_url}/pulls/{pr_number}/reviews",
            headers=self.headers
        )
        return resp.json()


# Usage
if __name__ == '__main__':
    collector = GitHubCollector(
        os.environ['GITHUB_TOKEN'],
        'your-org',
        'your-repo'
    )
    
    metrics = collector.get_pr_metrics(days=30)
    print(f"PRs merged: {metrics['total_prs']}")
    print(f"Avg merge time: {metrics['avg_merge_time_hours']:.1f} hours")
    print(f"Avg review time: {metrics['avg_review_time_hours']:.1f} hours")
```

### 5.3 AI Usage Tracker (Python)

```python
#!/usr/bin/env python3
"""Track AI tool usage for adoption metrics."""

import sqlite3
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict

@dataclass
class AIEvent:
    user_id: str
    tool: str  # claude, copilot, cursor
    category: str  # code_gen, debug, docs, test
    duration_sec: float = None
    feedback: str = None  # helpful, not_helpful

class AIUsageTracker:
    def __init__(self, db_path: str = "ai_usage.db"):
        self.conn = sqlite3.connect(db_path)
        self._init_db()
    
    def _init_db(self):
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS usage (
                id INTEGER PRIMARY KEY,
                timestamp TEXT,
                user_id TEXT,
                tool TEXT,
                category TEXT,
                duration_sec REAL,
                feedback TEXT
            )
        ''')
        self.conn.commit()
    
    def log(self, event: AIEvent):
        self.conn.execute('''
            INSERT INTO usage (timestamp, user_id, tool, category, duration_sec, feedback)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (datetime.now().isoformat(), event.user_id, event.tool, 
              event.category, event.duration_sec, event.feedback))
        self.conn.commit()
    
    def get_metrics(self, days: int = 30, team_size: int = None):
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        cur = self.conn.execute(
            'SELECT COUNT(*), COUNT(DISTINCT user_id) FROM usage WHERE timestamp >= ?',
            (since,)
        )
        total, unique_users = cur.fetchone()
        
        cur = self.conn.execute(
            'SELECT tool, COUNT(*) FROM usage WHERE timestamp >= ? GROUP BY tool',
            (since,)
        )
        by_tool = dict(cur.fetchall())
        
        cur = self.conn.execute(
            'SELECT category, COUNT(*) FROM usage WHERE timestamp >= ? GROUP BY category',
            (since,)
        )
        by_category = dict(cur.fetchall())
        
        adoption_rate = unique_users / team_size if team_size else None
        
        return {
            'total_interactions': total,
            'unique_users': unique_users,
            'adoption_rate': adoption_rate,
            'by_tool': by_tool,
            'by_category': by_category,
            'avg_daily': total / days
        }


# Usage
if __name__ == '__main__':
    tracker = AIUsageTracker()
    
    # Log some events
    tracker.log(AIEvent('dev1', 'claude', 'code_gen', 45, 'helpful'))
    tracker.log(AIEvent('dev2', 'copilot', 'code_gen', 10))
    
    # Get metrics
    metrics = tracker.get_metrics(days=30, team_size=10)
    print(f"Adoption rate: {metrics['adoption_rate']:.0%}")
    print(f"Daily usage: {metrics['avg_daily']:.1f}")
```

---

## 6. Reporting Cadence

### Weekly Report
- AI adoption rate trend
- Key blockers/issues
- Quick wins to highlight

### Monthly Report  
- Full metrics comparison (velocity, quality, efficiency)
- Developer survey results
- ROI update
- Action items

### Quarterly Report
- Comprehensive before/after analysis
- ROI calculation
- Strategic recommendations
- Next quarter goals

---

## 7. Implementation Checklist

### Phase 1: Setup (Week 1-2)
- [ ] Identify all data sources
- [ ] Set up API access (Jira, GitHub, CI/CD)
- [ ] Deploy collection scripts
- [ ] Create dashboards
- [ ] Distribute baseline survey

### Phase 2: Baseline (Week 3-6)
- [ ] Collect 4 weeks of baseline data
- [ ] Analyze baseline survey results
- [ ] Document current processes
- [ ] Set improvement targets

### Phase 3: Tracking (Ongoing)
- [ ] Weekly pulse surveys
- [ ] Monthly full surveys
- [ ] Automated metrics collection
- [ ] Monthly reporting

### Phase 4: Optimization (Quarterly)
- [ ] ROI analysis
- [ ] Strategy adjustments
- [ ] Target updates
- [ ] Success sharing

---

## Related Documents
- [Developer Surveys](developer-surveys.md)
- [ROI Calculator Templates](roi-calculator-templates.md)
- [Before/After Comparison Template](before-after-comparison-template.md)
