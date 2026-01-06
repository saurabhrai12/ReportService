# AI Adoption Metrics Tracking Framework

## Overview

This framework establishes baseline metrics and tracking mechanisms to measure the impact of AI adoption across the SDLC. It provides tools to quantify productivity gains, quality improvements, and developer satisfaction.

---

## 1. Key Performance Indicators (KPIs)

### 1.1 Velocity Metrics

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **Story Points per Sprint** | Team velocity | Sum of completed story points | +15-25% |
| **Cycle Time** | Time from start to deployment | End date - Start date | -20-30% |
| **Lead Time** | Time from request to delivery | Deployment date - Request date | -25-35% |
| **Throughput** | Items completed per time period | Count of completed items / time | +20-30% |
| **Time to First Commit** | Time to start coding after assignment | First commit - Assignment time | -30-40% |

### 1.2 Quality Metrics

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **Defect Rate** | Bugs per unit of work | Bugs found / Story points | -25-40% |
| **Defect Escape Rate** | Bugs reaching production | Prod bugs / Total bugs | -30-50% |
| **Code Coverage** | Test coverage percentage | Covered lines / Total lines | +10-20% |
| **Technical Debt Ratio** | Debt vs new development | Debt remediation time / Dev time | -15-25% |
| **Code Review Defects** | Issues found in review | Issues / Lines changed | Variable |
| **Rework Rate** | Work requiring revision | Reworked items / Total items | -20-30% |

### 1.3 Efficiency Metrics

| Metric | Description | Calculation | Target Improvement |
|--------|-------------|-------------|-------------------|
| **PR Review Time** | Time to complete code review | Review complete - PR opened | -30-50% |
| **PR Iterations** | Review cycles before merge | Count of review rounds | -20-30% |
| **Time to Merge** | PR open to merge duration | Merge time - Open time | -25-40% |
| **Build Success Rate** | Successful CI builds | Successful builds / Total builds | +10-15% |
| **Deployment Frequency** | How often we deploy | Deployments per time period | +20-40% |
| **Documentation Time** | Time spent on docs | Hours on documentation | -40-60% |

### 1.4 Developer Experience Metrics

| Metric | Description | Collection Method | Target |
|--------|-------------|-------------------|--------|
| **Developer Satisfaction** | Overall satisfaction score | Survey (1-10 scale) | +1-2 points |
| **AI Tool Satisfaction** | Satisfaction with AI tools | Survey (1-10 scale) | ≥7 |
| **Context Switching** | Interruptions per day | Self-reported / tooling | -20-30% |
| **Flow State Time** | Uninterrupted coding time | Time tracking | +15-25% |
| **Onboarding Time** | Time for new dev productivity | Days to first PR | -30-50% |

---

## 2. Measurement Infrastructure

### 2.1 Data Sources

```
┌─────────────────────────────────────────────────────────────────┐
│                     METRICS DATA SOURCES                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │    Jira      │  │   GitHub/    │  │   CI/CD      │         │
│  │   - Stories  │  │   GitLab     │  │  - Builds    │         │
│  │   - Bugs     │  │   - PRs      │  │  - Deploys   │         │
│  │   - Sprints  │  │   - Commits  │  │  - Tests     │         │
│  │   - Time     │  │   - Reviews  │  │  - Coverage  │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                 │                  │
│         └────────────────┼─────────────────┘                  │
│                          │                                     │
│                          ▼                                     │
│              ┌───────────────────────┐                        │
│              │   Metrics Database    │                        │
│              │   (PostgreSQL/        │                        │
│              │    Snowflake)         │                        │
│              └───────────┬───────────┘                        │
│                          │                                     │
│         ┌────────────────┼────────────────┐                   │
│         │                │                │                    │
│         ▼                ▼                ▼                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐          │
│  │  Dashboard   │ │   Reports    │ │    Alerts    │          │
│  │  (Grafana/   │ │  (Weekly/    │ │  (Threshold  │          │
│  │   Tableau)   │ │   Monthly)   │ │   Based)     │          │
│  └──────────────┘ └──────────────┘ └──────────────┘          │
│                                                                │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Collection Architecture

```yaml
# metrics-collection-config.yaml
data_sources:
  jira:
    type: rest_api
    base_url: https://your-org.atlassian.net
    auth: api_token
    sync_frequency: hourly
    entities:
      - issues
      - sprints
      - worklogs
      - changelogs
    
  github:
    type: rest_api
    base_url: https://api.github.com
    auth: github_app
    sync_frequency: 15min
    entities:
      - pull_requests
      - reviews
      - commits
      - check_runs
    
  ci_cd:
    type: webhook
    platforms:
      - github_actions
      - jenkins
    events:
      - workflow_run
      - deployment
      - test_report

  surveys:
    type: scheduled
    platform: google_forms
    frequency: bi-weekly
    
metrics_store:
  type: snowflake
  database: engineering_metrics
  schema: ai_adoption
  
dashboards:
  platform: tableau
  refresh: hourly
```

---

## 3. Data Collection Scripts

### 3.1 Jira Metrics Collector

```python
#!/usr/bin/env python3
"""
jira_metrics_collector.py
Collects velocity and quality metrics from Jira.
"""

import os
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict, Optional
import requests
from requests.auth import HTTPBasicAuth
import json

@dataclass
class SprintMetrics:
    sprint_id: str
    sprint_name: str
    team: str
    start_date: datetime
    end_date: datetime
    committed_points: float
    completed_points: float
    stories_completed: int
    bugs_found: int
    bugs_fixed: int
    carryover_points: float
    
@dataclass
class IssueMetrics:
    issue_key: str
    issue_type: str
    story_points: Optional[float]
    created_date: datetime
    started_date: Optional[datetime]
    completed_date: Optional[datetime]
    cycle_time_days: Optional[float]
    lead_time_days: Optional[float]
    rework_count: int
    ai_assisted: bool  # Custom field

class JiraMetricsCollector:
    """Collects metrics from Jira."""
    
    def __init__(self, base_url: str, email: str, api_token: str):
        self.base_url = base_url.rstrip('/')
        self.auth = HTTPBasicAuth(email, api_token)
        self.headers = {"Accept": "application/json"}
        
    def _request(self, endpoint: str, params: dict = None) -> dict:
        """Make authenticated request to Jira API."""
        url = f"{self.base_url}/rest/api/3/{endpoint}"
        response = requests.get(url, headers=self.headers, auth=self.auth, params=params)
        response.raise_for_status()
        return response.json()
    
    def get_sprint_metrics(self, board_id: int, sprint_id: int) -> SprintMetrics:
        """Get metrics for a specific sprint."""
        # Get sprint details
        sprint = self._request(f"sprint/{sprint_id}")
        
        # Get issues in sprint
        jql = f"sprint = {sprint_id}"
        issues = self._get_all_issues(jql)
        
        # Calculate metrics
        completed_points = sum(
            i.get('fields', {}).get('customfield_10016', 0) or 0  # Story points field
            for i in issues
            if i['fields']['status']['statusCategory']['name'] == 'Done'
        )
        
        committed_points = sum(
            i.get('fields', {}).get('customfield_10016', 0) or 0
            for i in issues
        )
        
        bugs_found = len([
            i for i in issues 
            if i['fields']['issuetype']['name'] == 'Bug'
        ])
        
        return SprintMetrics(
            sprint_id=str(sprint_id),
            sprint_name=sprint['name'],
            team=sprint.get('originBoardId', 'Unknown'),
            start_date=datetime.fromisoformat(sprint['startDate'].replace('Z', '+00:00')),
            end_date=datetime.fromisoformat(sprint['endDate'].replace('Z', '+00:00')),
            committed_points=committed_points,
            completed_points=completed_points,
            stories_completed=len([i for i in issues if i['fields']['status']['statusCategory']['name'] == 'Done']),
            bugs_found=bugs_found,
            bugs_fixed=len([i for i in issues if i['fields']['issuetype']['name'] == 'Bug' and i['fields']['status']['statusCategory']['name'] == 'Done']),
            carryover_points=committed_points - completed_points
        )
    
    def get_cycle_time_metrics(self, project_key: str, days: int = 30) -> List[IssueMetrics]:
        """Get cycle time metrics for recent issues."""
        start_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        jql = f"project = {project_key} AND resolved >= {start_date} AND type in (Story, Task, Bug)"
        
        issues = self._get_all_issues(jql, expand='changelog')
        metrics = []
        
        for issue in issues:
            # Calculate cycle time from changelog
            started = None
            completed = None
            rework_count = 0
            
            for history in issue.get('changelog', {}).get('histories', []):
                for item in history.get('items', []):
                    if item['field'] == 'status':
                        if item['toString'] == 'In Progress' and not started:
                            started = datetime.fromisoformat(history['created'].replace('Z', '+00:00'))
                        if item['toString'] == 'Done':
                            completed = datetime.fromisoformat(history['created'].replace('Z', '+00:00'))
                        # Count rework (moved back from Done)
                        if item['fromString'] == 'Done':
                            rework_count += 1
            
            created = datetime.fromisoformat(issue['fields']['created'].replace('Z', '+00:00'))
            
            cycle_time = None
            if started and completed:
                cycle_time = (completed - started).total_seconds() / 86400  # Days
                
            lead_time = None
            if completed:
                lead_time = (completed - created).total_seconds() / 86400
            
            # Check for AI-assisted label or custom field
            labels = issue['fields'].get('labels', [])
            ai_assisted = 'ai-assisted' in labels or 'ai-generated' in labels
            
            metrics.append(IssueMetrics(
                issue_key=issue['key'],
                issue_type=issue['fields']['issuetype']['name'],
                story_points=issue['fields'].get('customfield_10016'),
                created_date=created,
                started_date=started,
                completed_date=completed,
                cycle_time_days=cycle_time,
                lead_time_days=lead_time,
                rework_count=rework_count,
                ai_assisted=ai_assisted
            ))
        
        return metrics
    
    def get_defect_metrics(self, project_key: str, days: int = 30) -> Dict:
        """Get defect metrics."""
        start_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        
        # Bugs created
        bugs_created = self._get_all_issues(
            f"project = {project_key} AND type = Bug AND created >= {start_date}"
        )
        
        # Bugs resolved
        bugs_resolved = self._get_all_issues(
            f"project = {project_key} AND type = Bug AND resolved >= {start_date}"
        )
        
        # Production bugs (assuming label or component)
        prod_bugs = self._get_all_issues(
            f"project = {project_key} AND type = Bug AND labels = production AND created >= {start_date}"
        )
        
        # Story points completed for rate calculation
        stories = self._get_all_issues(
            f"project = {project_key} AND type = Story AND resolved >= {start_date}"
        )
        total_points = sum(
            s['fields'].get('customfield_10016', 0) or 0 
            for s in stories
        )
        
        return {
            'bugs_created': len(bugs_created),
            'bugs_resolved': len(bugs_resolved),
            'production_bugs': len(prod_bugs),
            'story_points_completed': total_points,
            'defect_rate': len(bugs_created) / total_points if total_points > 0 else 0,
            'defect_escape_rate': len(prod_bugs) / len(bugs_created) if bugs_created else 0,
            'period_days': days
        }
    
    def _get_all_issues(self, jql: str, expand: str = None) -> List[dict]:
        """Get all issues matching JQL with pagination."""
        issues = []
        start_at = 0
        max_results = 100
        
        while True:
            params = {
                'jql': jql,
                'startAt': start_at,
                'maxResults': max_results
            }
            if expand:
                params['expand'] = expand
                
            result = self._request('search', params)
            issues.extend(result['issues'])
            
            if start_at + max_results >= result['total']:
                break
            start_at += max_results
        
        return issues


# Usage example
if __name__ == '__main__':
    collector = JiraMetricsCollector(
        base_url=os.environ['JIRA_BASE_URL'],
        email=os.environ['JIRA_EMAIL'],
        api_token=os.environ['JIRA_API_TOKEN']
    )
    
    # Get sprint metrics
    sprint_metrics = collector.get_sprint_metrics(board_id=1, sprint_id=100)
    print(f"Sprint Velocity: {sprint_metrics.completed_points} points")
    
    # Get cycle time
    cycle_metrics = collector.get_cycle_time_metrics('PROJ', days=30)
    avg_cycle = sum(m.cycle_time_days for m in cycle_metrics if m.cycle_time_days) / len(cycle_metrics)
    print(f"Average Cycle Time: {avg_cycle:.1f} days")
    
    # Get defect metrics
    defects = collector.get_defect_metrics('PROJ', days=30)
    print(f"Defect Rate: {defects['defect_rate']:.2f} bugs/point")
```

### 3.2 GitHub Metrics Collector

```python
#!/usr/bin/env python3
"""
github_metrics_collector.py
Collects PR review and code metrics from GitHub.
"""

import os
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Dict, Optional
import requests

@dataclass
class PRMetrics:
    pr_number: int
    title: str
    author: str
    created_at: datetime
    merged_at: Optional[datetime]
    closed_at: Optional[datetime]
    first_review_at: Optional[datetime]
    time_to_first_review_hours: Optional[float]
    time_to_merge_hours: Optional[float]
    review_iterations: int
    additions: int
    deletions: int
    changed_files: int
    comments_count: int
    ai_assisted: bool  # Based on labels or commit messages

@dataclass
class ReviewMetrics:
    total_prs: int
    merged_prs: int
    avg_time_to_first_review_hours: float
    avg_time_to_merge_hours: float
    avg_review_iterations: float
    avg_pr_size_lines: float
    ai_assisted_prs: int
    period_days: int

class GitHubMetricsCollector:
    """Collects metrics from GitHub."""
    
    def __init__(self, token: str, owner: str, repo: str):
        self.token = token
        self.owner = owner
        self.repo = repo
        self.base_url = "https://api.github.com"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github.v3+json"
        }
    
    def _request(self, endpoint: str, params: dict = None) -> dict:
        """Make authenticated request to GitHub API."""
        url = f"{self.base_url}/{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()
    
    def _request_paginated(self, endpoint: str, params: dict = None) -> List[dict]:
        """Get all pages of results."""
        params = params or {}
        params['per_page'] = 100
        params['page'] = 1
        
        all_items = []
        while True:
            items = self._request(endpoint, params)
            if not items:
                break
            all_items.extend(items)
            if len(items) < 100:
                break
            params['page'] += 1
        
        return all_items
    
    def get_pr_metrics(self, days: int = 30) -> List[PRMetrics]:
        """Get metrics for PRs in the specified period."""
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        # Get merged PRs
        prs = self._request_paginated(
            f"repos/{self.owner}/{self.repo}/pulls",
            params={'state': 'closed', 'sort': 'updated', 'direction': 'desc'}
        )
        
        metrics = []
        for pr in prs:
            created_at = datetime.fromisoformat(pr['created_at'].replace('Z', '+00:00'))
            
            # Filter by date range
            if created_at < datetime.fromisoformat(since + '+00:00'):
                continue
            
            merged_at = None
            if pr.get('merged_at'):
                merged_at = datetime.fromisoformat(pr['merged_at'].replace('Z', '+00:00'))
            
            closed_at = None
            if pr.get('closed_at'):
                closed_at = datetime.fromisoformat(pr['closed_at'].replace('Z', '+00:00'))
            
            # Get reviews for this PR
            reviews = self._request(
                f"repos/{self.owner}/{self.repo}/pulls/{pr['number']}/reviews"
            )
            
            first_review_at = None
            review_iterations = 0
            if reviews:
                first_review_at = datetime.fromisoformat(
                    reviews[0]['submitted_at'].replace('Z', '+00:00')
                )
                # Count review iterations (CHANGES_REQUESTED followed by more reviews)
                changes_requested = False
                for review in reviews:
                    if review['state'] == 'CHANGES_REQUESTED':
                        changes_requested = True
                    elif review['state'] == 'APPROVED' and changes_requested:
                        review_iterations += 1
                        changes_requested = False
            
            # Calculate times
            time_to_first_review = None
            if first_review_at:
                time_to_first_review = (first_review_at - created_at).total_seconds() / 3600
            
            time_to_merge = None
            if merged_at:
                time_to_merge = (merged_at - created_at).total_seconds() / 3600
            
            # Check if AI-assisted
            labels = [l['name'].lower() for l in pr.get('labels', [])]
            ai_assisted = any(
                term in labels 
                for term in ['ai-assisted', 'ai-generated', 'copilot', 'claude']
            )
            
            # Also check PR title/body for AI indicators
            title_body = (pr.get('title', '') + ' ' + (pr.get('body') or '')).lower()
            if any(term in title_body for term in ['ai-generated', 'copilot', 'claude', 'chatgpt']):
                ai_assisted = True
            
            metrics.append(PRMetrics(
                pr_number=pr['number'],
                title=pr['title'],
                author=pr['user']['login'],
                created_at=created_at,
                merged_at=merged_at,
                closed_at=closed_at,
                first_review_at=first_review_at,
                time_to_first_review_hours=time_to_first_review,
                time_to_merge_hours=time_to_merge,
                review_iterations=review_iterations,
                additions=pr.get('additions', 0),
                deletions=pr.get('deletions', 0),
                changed_files=pr.get('changed_files', 0),
                comments_count=pr.get('comments', 0) + pr.get('review_comments', 0),
                ai_assisted=ai_assisted
            ))
        
        return metrics
    
    def get_review_summary(self, days: int = 30) -> ReviewMetrics:
        """Get summary review metrics."""
        pr_metrics = self.get_pr_metrics(days)
        
        merged_prs = [p for p in pr_metrics if p.merged_at]
        
        avg_first_review = 0
        prs_with_review = [p for p in pr_metrics if p.time_to_first_review_hours]
        if prs_with_review:
            avg_first_review = sum(p.time_to_first_review_hours for p in prs_with_review) / len(prs_with_review)
        
        avg_merge_time = 0
        if merged_prs:
            avg_merge_time = sum(p.time_to_merge_hours for p in merged_prs) / len(merged_prs)
        
        avg_iterations = 0
        if pr_metrics:
            avg_iterations = sum(p.review_iterations for p in pr_metrics) / len(pr_metrics)
        
        avg_size = 0
        if pr_metrics:
            avg_size = sum(p.additions + p.deletions for p in pr_metrics) / len(pr_metrics)
        
        return ReviewMetrics(
            total_prs=len(pr_metrics),
            merged_prs=len(merged_prs),
            avg_time_to_first_review_hours=avg_first_review,
            avg_time_to_merge_hours=avg_merge_time,
            avg_review_iterations=avg_iterations,
            avg_pr_size_lines=avg_size,
            ai_assisted_prs=len([p for p in pr_metrics if p.ai_assisted]),
            period_days=days
        )
    
    def get_commit_metrics(self, days: int = 30) -> Dict:
        """Get commit activity metrics."""
        since = (datetime.now() - timedelta(days=days)).isoformat()
        
        commits = self._request_paginated(
            f"repos/{self.owner}/{self.repo}/commits",
            params={'since': since}
        )
        
        # Count commits by author
        by_author = {}
        ai_commits = 0
        for commit in commits:
            author = commit.get('author', {}).get('login', 'unknown')
            by_author[author] = by_author.get(author, 0) + 1
            
            # Check for AI indicators in commit message
            message = commit.get('commit', {}).get('message', '').lower()
            if any(term in message for term in ['ai-generated', 'copilot', 'claude']):
                ai_commits += 1
        
        return {
            'total_commits': len(commits),
            'commits_by_author': by_author,
            'ai_assisted_commits': ai_commits,
            'period_days': days
        }
    
    def get_build_metrics(self, days: int = 30) -> Dict:
        """Get CI/CD build metrics from GitHub Actions."""
        # Get workflow runs
        runs = self._request(
            f"repos/{self.owner}/{self.repo}/actions/runs",
            params={'per_page': 100}
        ).get('workflow_runs', [])
        
        since = datetime.now() - timedelta(days=days)
        recent_runs = [
            r for r in runs 
            if datetime.fromisoformat(r['created_at'].replace('Z', '+00:00')) > since
        ]
        
        successful = len([r for r in recent_runs if r['conclusion'] == 'success'])
        failed = len([r for r in recent_runs if r['conclusion'] == 'failure'])
        
        # Calculate average duration
        durations = []
        for run in recent_runs:
            if run.get('updated_at') and run.get('created_at'):
                start = datetime.fromisoformat(run['created_at'].replace('Z', '+00:00'))
                end = datetime.fromisoformat(run['updated_at'].replace('Z', '+00:00'))
                durations.append((end - start).total_seconds() / 60)  # Minutes
        
        return {
            'total_runs': len(recent_runs),
            'successful_runs': successful,
            'failed_runs': failed,
            'success_rate': successful / len(recent_runs) if recent_runs else 0,
            'avg_duration_minutes': sum(durations) / len(durations) if durations else 0,
            'period_days': days
        }


# Usage example
if __name__ == '__main__':
    collector = GitHubMetricsCollector(
        token=os.environ['GITHUB_TOKEN'],
        owner='your-org',
        repo='your-repo'
    )
    
    # Get review metrics
    review_metrics = collector.get_review_summary(days=30)
    print(f"Average PR Review Time: {review_metrics.avg_time_to_first_review_hours:.1f} hours")
    print(f"Average Time to Merge: {review_metrics.avg_time_to_merge_hours:.1f} hours")
    print(f"AI-Assisted PRs: {review_metrics.ai_assisted_prs}")
    
    # Get build metrics
    build_metrics = collector.get_build_metrics(days=30)
    print(f"Build Success Rate: {build_metrics['success_rate']:.1%}")
```

### 3.3 Combined Metrics Aggregator

```python
#!/usr/bin/env python3
"""
metrics_aggregator.py
Aggregates metrics from multiple sources and stores in database.
"""

import os
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from typing import Dict, List, Optional
import json

# Import collectors (from previous files)
# from jira_metrics_collector import JiraMetricsCollector
# from github_metrics_collector import GitHubMetricsCollector

@dataclass
class AggregatedMetrics:
    """Combined metrics for a time period."""
    period_start: datetime
    period_end: datetime
    team: str
    
    # Velocity
    story_points_completed: float
    stories_completed: int
    avg_cycle_time_days: float
    avg_lead_time_days: float
    
    # Quality
    bugs_created: int
    bugs_resolved: int
    defect_rate: float
    defect_escape_rate: float
    rework_rate: float
    
    # Efficiency
    prs_merged: int
    avg_pr_review_time_hours: float
    avg_pr_merge_time_hours: float
    avg_review_iterations: float
    build_success_rate: float
    
    # AI Adoption
    ai_assisted_prs: int
    ai_assisted_issues: int
    ai_adoption_rate: float
    
    # Metadata
    collected_at: datetime


class MetricsAggregator:
    """Aggregates metrics from multiple sources."""
    
    def __init__(self, jira_collector, github_collector, db_connection=None):
        self.jira = jira_collector
        self.github = github_collector
        self.db = db_connection
    
    def collect_period_metrics(
        self, 
        team: str, 
        project_key: str,
        days: int = 14
    ) -> AggregatedMetrics:
        """Collect all metrics for a time period."""
        
        period_end = datetime.now()
        period_start = period_end - timedelta(days=days)
        
        # Jira metrics
        cycle_metrics = self.jira.get_cycle_time_metrics(project_key, days)
        defect_metrics = self.jira.get_defect_metrics(project_key, days)
        
        # Calculate averages
        cycle_times = [m.cycle_time_days for m in cycle_metrics if m.cycle_time_days]
        lead_times = [m.lead_time_days for m in cycle_metrics if m.lead_time_days]
        rework_items = [m for m in cycle_metrics if m.rework_count > 0]
        ai_issues = [m for m in cycle_metrics if m.ai_assisted]
        
        # GitHub metrics
        review_metrics = self.github.get_review_summary(days)
        build_metrics = self.github.get_build_metrics(days)
        
        # Calculate AI adoption rate
        total_items = len(cycle_metrics) + review_metrics.total_prs
        ai_items = len(ai_issues) + review_metrics.ai_assisted_prs
        ai_adoption_rate = ai_items / total_items if total_items > 0 else 0
        
        return AggregatedMetrics(
            period_start=period_start,
            period_end=period_end,
            team=team,
            
            # Velocity
            story_points_completed=defect_metrics['story_points_completed'],
            stories_completed=len([m for m in cycle_metrics if m.issue_type == 'Story']),
            avg_cycle_time_days=sum(cycle_times) / len(cycle_times) if cycle_times else 0,
            avg_lead_time_days=sum(lead_times) / len(lead_times) if lead_times else 0,
            
            # Quality
            bugs_created=defect_metrics['bugs_created'],
            bugs_resolved=defect_metrics['bugs_resolved'],
            defect_rate=defect_metrics['defect_rate'],
            defect_escape_rate=defect_metrics['defect_escape_rate'],
            rework_rate=len(rework_items) / len(cycle_metrics) if cycle_metrics else 0,
            
            # Efficiency
            prs_merged=review_metrics.merged_prs,
            avg_pr_review_time_hours=review_metrics.avg_time_to_first_review_hours,
            avg_pr_merge_time_hours=review_metrics.avg_time_to_merge_hours,
            avg_review_iterations=review_metrics.avg_review_iterations,
            build_success_rate=build_metrics['success_rate'],
            
            # AI Adoption
            ai_assisted_prs=review_metrics.ai_assisted_prs,
            ai_assisted_issues=len(ai_issues),
            ai_adoption_rate=ai_adoption_rate,
            
            collected_at=datetime.now()
        )
    
    def store_metrics(self, metrics: AggregatedMetrics):
        """Store metrics in database."""
        if not self.db:
            print("No database connection, printing metrics:")
            print(json.dumps(asdict(metrics), default=str, indent=2))
            return
        
        # Store in database (implementation depends on your DB)
        # Example for Snowflake:
        """
        INSERT INTO engineering_metrics.ai_adoption.team_metrics (
            period_start, period_end, team,
            story_points_completed, stories_completed,
            avg_cycle_time_days, avg_lead_time_days,
            bugs_created, bugs_resolved, defect_rate, defect_escape_rate, rework_rate,
            prs_merged, avg_pr_review_time_hours, avg_pr_merge_time_hours,
            avg_review_iterations, build_success_rate,
            ai_assisted_prs, ai_assisted_issues, ai_adoption_rate,
            collected_at
        ) VALUES (...)
        """
        pass
    
    def compare_periods(
        self, 
        team: str,
        project_key: str,
        baseline_start: datetime,
        baseline_end: datetime,
        comparison_start: datetime,
        comparison_end: datetime
    ) -> Dict:
        """Compare metrics between two periods (e.g., before/after AI adoption)."""
        
        baseline_days = (baseline_end - baseline_start).days
        comparison_days = (comparison_end - comparison_start).days
        
        # This would typically query stored historical data
        # For simplicity, showing the comparison structure
        
        return {
            'baseline_period': {
                'start': baseline_start,
                'end': baseline_end,
                'days': baseline_days
            },
            'comparison_period': {
                'start': comparison_start,
                'end': comparison_end,
                'days': comparison_days
            },
            'improvements': {
                'velocity_change_pct': None,  # Calculate from stored data
                'cycle_time_change_pct': None,
                'defect_rate_change_pct': None,
                'review_time_change_pct': None,
                'build_success_change_pct': None
            }
        }


def main():
    """Main entry point for metrics collection."""
    from jira_metrics_collector import JiraMetricsCollector
    from github_metrics_collector import GitHubMetricsCollector
    
    # Initialize collectors
    jira = JiraMetricsCollector(
        base_url=os.environ['JIRA_BASE_URL'],
        email=os.environ['JIRA_EMAIL'],
        api_token=os.environ['JIRA_API_TOKEN']
    )
    
    github = GitHubMetricsCollector(
        token=os.environ['GITHUB_TOKEN'],
        owner=os.environ['GITHUB_ORG'],
        repo=os.environ['GITHUB_REPO']
    )
    
    # Aggregate metrics
    aggregator = MetricsAggregator(jira, github)
    
    metrics = aggregator.collect_period_metrics(
        team='Platform Team',
        project_key='PLAT',
        days=14
    )
    
    aggregator.store_metrics(metrics)
    
    print("Metrics collection complete!")
    print(f"AI Adoption Rate: {metrics.ai_adoption_rate:.1%}")


if __name__ == '__main__':
    main()
```

---

## 4. Developer Survey Templates

### 4.1 Bi-Weekly Developer Experience Survey

```markdown
# Developer Experience Survey - AI Tools
**Frequency**: Bi-weekly
**Duration**: 3-5 minutes

## Section 1: Overall Satisfaction

1. **Overall, how satisfied are you with the AI tools available for development?**
   - Scale: 1 (Very Dissatisfied) - 10 (Very Satisfied)

2. **How would you rate your productivity this sprint compared to before AI tools?**
   - Much lower / Slightly lower / About the same / Slightly higher / Much higher

## Section 2: Tool Usage

3. **Which AI tools did you use this sprint?** (Select all that apply)
   - [ ] Claude (web/API)
   - [ ] GitHub Copilot
   - [ ] Claude Code
   - [ ] ChatGPT
   - [ ] Cursor
   - [ ] Other: _______
   - [ ] None

4. **For what tasks did you use AI tools?** (Select all that apply)
   - [ ] Writing new code
   - [ ] Debugging
   - [ ] Code review assistance
   - [ ] Test generation
   - [ ] Documentation
   - [ ] Understanding unfamiliar code
   - [ ] SQL queries
   - [ ] DevOps/Infrastructure
   - [ ] Other: _______

5. **Approximately what percentage of your coding time involved AI assistance?**
   - 0% / 1-25% / 26-50% / 51-75% / 76-100%

## Section 3: Impact Assessment

6. **How much time do you estimate AI tools saved you this sprint?**
   - None / <1 hour / 1-2 hours / 3-5 hours / 5-10 hours / >10 hours

7. **Rate the quality of AI-generated code suggestions:**
   - Scale: 1 (Poor) - 10 (Excellent)

8. **How often did AI suggestions require significant modification?**
   - Never / Rarely / Sometimes / Often / Always

## Section 4: Challenges

9. **What challenges have you faced with AI tools?** (Select all that apply)
   - [ ] Incorrect suggestions
   - [ ] Security concerns
   - [ ] Tool availability/access
   - [ ] Integration with workflow
   - [ ] Learning curve
   - [ ] Inconsistent results
   - [ ] Context limitations
   - [ ] None
   - [ ] Other: _______

10. **What would improve your experience with AI tools?**
    - Open text

## Section 5: Specific Feedback

11. **Describe a situation where AI tools significantly helped you:**
    - Open text

12. **Describe a situation where AI tools fell short:**
    - Open text

13. **Any additional feedback or suggestions?**
    - Open text
```

### 4.2 Monthly AI Adoption Assessment

```markdown
# Monthly AI Adoption Assessment
**For**: Team Leads / Engineering Managers
**Frequency**: Monthly

## Team Information
- Team Name: _______
- Reporting Period: _______
- Team Size: _______

## Adoption Metrics

1. **What percentage of your team is actively using AI tools?**
   - 0-25% / 26-50% / 51-75% / 76-100%

2. **Which SDLC phases benefit most from AI tools?** (Rank 1-5)
   - [ ] Requirements/Design
   - [ ] Development
   - [ ] Code Review
   - [ ] Testing
   - [ ] Documentation
   - [ ] Deployment/Ops

3. **Estimate the overall productivity improvement attributed to AI tools:**
   - Negative impact / No change / 1-10% / 11-25% / 26-50% / >50%

## Quality Assessment

4. **Has code quality changed since AI adoption?**
   - Decreased significantly / Decreased slightly / No change / Improved slightly / Improved significantly

5. **Has defect rate changed since AI adoption?**
   - Increased significantly / Increased slightly / No change / Decreased slightly / Decreased significantly

6. **Have you observed any negative impacts from AI tool usage?**
   - [ ] Reduced code understanding
   - [ ] Increased technical debt
   - [ ] Security vulnerabilities
   - [ ] Over-reliance on AI
   - [ ] None observed
   - [ ] Other: _______

## Process Integration

7. **How well are AI tools integrated into your team's workflow?**
   - Scale: 1 (Not at all) - 10 (Fully integrated)

8. **What barriers prevent better AI tool adoption?** (Select all that apply)
   - [ ] Lack of training
   - [ ] Tool limitations
   - [ ] Security policies
   - [ ] Resistance to change
   - [ ] Cost concerns
   - [ ] Unclear guidelines
   - [ ] None
   - [ ] Other: _______

## Resource Needs

9. **What support does your team need to improve AI tool usage?**
   - [ ] More training
   - [ ] Better documentation
   - [ ] Additional tools
   - [ ] Prompt templates
   - [ ] Best practices sharing
   - [ ] Other: _______

10. **What AI capabilities would provide the most value for your team?**
    - Open text

## Comments
11. **Additional observations or recommendations:**
    - Open text
```

---

## 5. Dashboard Templates

### 5.1 Executive Dashboard (Tableau/Power BI)

```sql
-- Executive Dashboard Queries

-- 1. Velocity Trend
SELECT 
    DATE_TRUNC('week', period_end) as week,
    team,
    AVG(story_points_completed) as avg_velocity,
    AVG(avg_cycle_time_days) as avg_cycle_time
FROM team_metrics
WHERE period_end >= DATEADD(month, -3, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1;

-- 2. Quality Metrics
SELECT 
    DATE_TRUNC('week', period_end) as week,
    team,
    AVG(defect_rate) as defect_rate,
    AVG(defect_escape_rate) as escape_rate,
    AVG(build_success_rate) as build_success
FROM team_metrics
WHERE period_end >= DATEADD(month, -3, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1;

-- 3. AI Adoption Trend
SELECT 
    DATE_TRUNC('week', period_end) as week,
    team,
    AVG(ai_adoption_rate) as adoption_rate,
    SUM(ai_assisted_prs) as ai_prs,
    SUM(ai_assisted_issues) as ai_issues
FROM team_metrics
WHERE period_end >= DATEADD(month, -3, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1;

-- 4. Efficiency Metrics
SELECT 
    DATE_TRUNC('week', period_end) as week,
    team,
    AVG(avg_pr_review_time_hours) as review_time,
    AVG(avg_pr_merge_time_hours) as merge_time,
    AVG(avg_review_iterations) as iterations
FROM team_metrics
WHERE period_end >= DATEADD(month, -3, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1;

-- 5. Before/After AI Comparison
WITH baseline AS (
    SELECT 
        team,
        AVG(story_points_completed) as velocity,
        AVG(avg_cycle_time_days) as cycle_time,
        AVG(defect_rate) as defect_rate,
        AVG(avg_pr_review_time_hours) as review_time
    FROM team_metrics
    WHERE period_end BETWEEN '2024-01-01' AND '2024-03-31'  -- Pre-AI period
    GROUP BY team
),
current AS (
    SELECT 
        team,
        AVG(story_points_completed) as velocity,
        AVG(avg_cycle_time_days) as cycle_time,
        AVG(defect_rate) as defect_rate,
        AVG(avg_pr_review_time_hours) as review_time
    FROM team_metrics
    WHERE period_end >= DATEADD(month, -1, CURRENT_DATE())  -- Current period
    GROUP BY team
)
SELECT 
    b.team,
    ROUND((c.velocity - b.velocity) / NULLIF(b.velocity, 0) * 100, 1) as velocity_change_pct,
    ROUND((c.cycle_time - b.cycle_time) / NULLIF(b.cycle_time, 0) * 100, 1) as cycle_time_change_pct,
    ROUND((c.defect_rate - b.defect_rate) / NULLIF(b.defect_rate, 0) * 100, 1) as defect_rate_change_pct,
    ROUND((c.review_time - b.review_time) / NULLIF(b.review_time, 0) * 100, 1) as review_time_change_pct
FROM baseline b
JOIN current c ON b.team = c.team;
```

### 5.2 Dashboard Layout Specification

```yaml
# dashboard_spec.yaml
dashboard:
  name: "AI Adoption Metrics Dashboard"
  refresh: hourly
  
  pages:
    - name: "Executive Summary"
      layout:
        - widget: kpi_cards
          row: 1
          metrics:
            - name: "Velocity Change"
              value: "${velocity_change_pct}%"
              comparison: "vs baseline"
              color_threshold: 
                green: ">10%"
                yellow: "0-10%"
                red: "<0%"
            - name: "Cycle Time Change"
              value: "${cycle_time_change_pct}%"
              color_threshold:
                green: "<-15%"
                yellow: "-15% to 0%"
                red: ">0%"
            - name: "Defect Rate Change"
              value: "${defect_rate_change_pct}%"
              color_threshold:
                green: "<-20%"
                yellow: "-20% to 0%"
                red: ">0%"
            - name: "AI Adoption Rate"
              value: "${ai_adoption_rate}%"
              color_threshold:
                green: ">50%"
                yellow: "25-50%"
                red: "<25%"
        
        - widget: line_chart
          row: 2
          title: "Velocity Trend by Team"
          x_axis: week
          y_axis: avg_velocity
          series: team
          
        - widget: line_chart
          row: 2
          title: "AI Adoption Rate Trend"
          x_axis: week
          y_axis: adoption_rate
          series: team
          
    - name: "Quality Metrics"
      layout:
        - widget: line_chart
          row: 1
          title: "Defect Rate Trend"
          x_axis: week
          y_axis: defect_rate
          series: team
          
        - widget: line_chart
          row: 1
          title: "Build Success Rate"
          x_axis: week
          y_axis: build_success
          series: team
          target_line: 0.95
          
        - widget: bar_chart
          row: 2
          title: "Defects by Category"
          x_axis: category
          y_axis: count
          
    - name: "Efficiency Metrics"
      layout:
        - widget: line_chart
          row: 1
          title: "PR Review Time Trend"
          x_axis: week
          y_axis: review_time
          series: team
          
        - widget: line_chart
          row: 1
          title: "Time to Merge Trend"
          x_axis: week
          y_axis: merge_time
          series: team
          
        - widget: heatmap
          row: 2
          title: "Review Activity by Day/Hour"
          x_axis: hour
          y_axis: day_of_week
          value: review_count
          
    - name: "Team Details"
      layout:
        - widget: filter
          type: dropdown
          field: team
          
        - widget: metrics_table
          row: 1
          columns:
            - metric
            - baseline
            - current
            - change_pct
            - status
            
        - widget: scatter_plot
          row: 2
          title: "AI Usage vs Productivity"
          x_axis: ai_adoption_rate
          y_axis: velocity_change_pct
          size: team_size
          color: team
```

---

## 6. Baseline Establishment Process

### 6.1 Baseline Collection Checklist

```markdown
# Baseline Metrics Collection Checklist

## Pre-Collection (Week -2 to -1)

### Data Source Validation
- [ ] Jira API access verified
- [ ] GitHub API access verified
- [ ] CI/CD metrics accessible
- [ ] Custom fields identified (story points, AI-assisted labels)
- [ ] Historical data availability confirmed (minimum 3 months)

### Tool Configuration
- [ ] Metrics collection scripts deployed
- [ ] Database/storage provisioned
- [ ] API credentials secured
- [ ] Scheduled jobs configured
- [ ] Alerting for collection failures

### Team Preparation
- [ ] Teams informed of metrics collection
- [ ] Labeling conventions communicated (ai-assisted tags)
- [ ] Survey distribution planned
- [ ] Baseline period defined

## Baseline Collection (Weeks 1-4)

### Week 1
- [ ] Run initial historical data collection (past 3 months)
- [ ] Validate data quality
- [ ] Identify anomalies or gaps
- [ ] Distribute first developer survey

### Week 2
- [ ] Continue daily/weekly metric collection
- [ ] Review and clean collected data
- [ ] Calculate initial baseline averages
- [ ] Collect qualitative feedback

### Week 3
- [ ] Finalize baseline period data
- [ ] Calculate statistical baselines (mean, median, std dev)
- [ ] Distribute second survey
- [ ] Document any data quality issues

### Week 4
- [ ] Generate baseline report
- [ ] Review with stakeholders
- [ ] Set improvement targets
- [ ] Archive baseline for comparison

## Baseline Documentation

### Metrics Captured
| Metric | Baseline Value | Std Dev | Data Quality |
|--------|---------------|---------|--------------|
| Story Points/Sprint | | | |
| Cycle Time (days) | | | |
| Lead Time (days) | | | |
| Defect Rate | | | |
| PR Review Time (hrs) | | | |
| Time to Merge (hrs) | | | |
| Build Success Rate | | | |

### Notes
- Data gaps: _______
- Anomalies excluded: _______
- Assumptions: _______
```

### 6.2 Target Setting Framework

```markdown
# AI Adoption Target Setting

## Target Categories

### Conservative Targets (Low Risk)
- Based on: Industry averages, pilot results
- Timeline: 6 months
- Confidence: 80%+

| Metric | Current | Target | Change |
|--------|---------|--------|--------|
| Velocity | X points | X+15% | +15% |
| Cycle Time | X days | X-15% | -15% |
| Defect Rate | X bugs/point | X-20% | -20% |
| PR Review Time | X hours | X-25% | -25% |

### Stretch Targets (Aspirational)
- Based on: Best-in-class benchmarks
- Timeline: 12 months
- Confidence: 50%

| Metric | Current | Target | Change |
|--------|---------|--------|--------|
| Velocity | X points | X+30% | +30% |
| Cycle Time | X days | X-30% | -30% |
| Defect Rate | X bugs/point | X-40% | -40% |
| PR Review Time | X hours | X-50% | -50% |

## Target Validation

### Sanity Checks
- [ ] Targets are measurable
- [ ] Historical data supports feasibility
- [ ] Team capacity considered
- [ ] External dependencies identified
- [ ] Targets aligned with business goals

### Risk Factors
- Tool adoption challenges
- Learning curve impact
- Measurement accuracy
- External factors (reorgs, projects)

### Review Schedule
- Monthly: Progress review
- Quarterly: Target adjustment
- Semi-annual: Strategy review
```

---

## 7. Reporting Templates

### 7.1 Weekly AI Adoption Report

```markdown
# Weekly AI Adoption Report
**Week of**: [DATE]
**Prepared by**: [NAME]

## Executive Summary
[2-3 sentences on overall progress]

## Key Metrics This Week

| Metric | This Week | Last Week | Trend | Target |
|--------|-----------|-----------|-------|--------|
| AI Adoption Rate | X% | Y% | ↑/↓ | Z% |
| Velocity | X pts | Y pts | ↑/↓ | Z pts |
| Cycle Time | X days | Y days | ↑/↓ | Z days |
| PR Review Time | X hrs | Y hrs | ↑/↓ | Z hrs |
| Build Success | X% | Y% | ↑/↓ | Z% |

## Highlights
- 🎉 [Positive development]
- 🎉 [Positive development]

## Concerns
- ⚠️ [Issue or risk]
- ⚠️ [Issue or risk]

## AI Tool Usage
- Total AI-assisted PRs: X
- Top use cases: [List]
- New prompt templates added: X

## Team Feedback Themes
- [Theme 1]
- [Theme 2]

## Actions for Next Week
- [ ] Action item 1
- [ ] Action item 2

## Appendix: Detailed Metrics
[Charts/tables]
```

### 7.2 Monthly Executive Report

```markdown
# Monthly AI Adoption Executive Report
**Month**: [MONTH YEAR]
**Prepared for**: Engineering Leadership

## Executive Summary
[Paragraph summarizing month's progress, key wins, challenges]

## ROI Summary

### Time Savings
| Activity | Hours Saved/Month | Value @ $X/hr |
|----------|------------------|---------------|
| Code Writing | X | $Y |
| Code Review | X | $Y |
| Documentation | X | $Y |
| Debugging | X | $Y |
| **Total** | **X** | **$Y** |

### Quality Improvements
| Metric | Baseline | Current | Improvement | Business Impact |
|--------|----------|---------|-------------|-----------------|
| Defect Rate | X | Y | Z% | Fewer prod incidents |
| Rework | X | Y | Z% | Faster delivery |

## Progress vs Targets

```
Velocity:     ████████░░ 80% to target
Cycle Time:   ██████████ 100% achieved ✓
Defect Rate:  ██████░░░░ 60% to target
Review Time:  █████████░ 90% to target
```

## Adoption by Team

| Team | Adoption Rate | Velocity Δ | Quality Δ | Notes |
|------|--------------|------------|-----------|-------|
| Team A | X% | +Y% | +Z% | |
| Team B | X% | +Y% | +Z% | |

## Key Accomplishments
1. [Accomplishment]
2. [Accomplishment]
3. [Accomplishment]

## Challenges & Mitigations
| Challenge | Impact | Mitigation | Status |
|-----------|--------|------------|--------|
| [Challenge] | [Impact] | [Action] | [Status] |

## Recommendations
1. [Recommendation]
2. [Recommendation]

## Next Month Focus
- [Priority 1]
- [Priority 2]
- [Priority 3]

## Appendix
- Detailed metrics tables
- Survey results summary
- Team-level breakdowns
```

---

## 8. Implementation Checklist

### Phase 1: Setup (Weeks 1-2)
- [ ] Deploy metrics collection scripts
- [ ] Configure database/data warehouse tables
- [ ] Set up API connections (Jira, GitHub)
- [ ] Create initial dashboard
- [ ] Test data collection pipeline

### Phase 2: Baseline (Weeks 3-6)
- [ ] Collect 4 weeks of baseline data
- [ ] Distribute developer surveys
- [ ] Calculate baseline metrics
- [ ] Set improvement targets
- [ ] Document baseline report

### Phase 3: Monitoring (Ongoing)
- [ ] Daily automated data collection
- [ ] Weekly metrics review
- [ ] Bi-weekly developer surveys
- [ ] Monthly executive reporting
- [ ] Quarterly target review

### Phase 4: Optimization (Quarterly)
- [ ] Analyze metric trends
- [ ] Identify improvement opportunities
- [ ] Adjust targets as needed
- [ ] Update collection as tools evolve
- [ ] Share learnings across teams
