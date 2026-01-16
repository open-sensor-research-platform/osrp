# OSRP MVP Development Plan

## Overview

This document tracks the MVP (Minimum Viable Product) development plan for OSRP using GitHub's native project management tools.

**Important**: We use GitHub Issues, Milestones, Labels, and Projects - NOT markdown TODO files.

---

## GitHub Resources

- **Repository**: https://github.com/open-sensor-research-platform/osrp
- **Issues**: https://github.com/open-sensor-research-platform/osrp/issues
- **Milestones**: https://github.com/open-sensor-research-platform/osrp/milestones
- **Projects**: https://github.com/orgs/open-sensor-research-platform/projects

---

## Milestones Created

### v0.2.0: AWS Foundation
**Due**: February 15, 2026
**Goal**: Deploy core AWS infrastructure with authentication and basic data storage

**Issues (9)**:
- #1 Design and create DynamoDB table schema
- #2 Create S3 bucket with lifecycle policies
- #3 Set up Cognito user pool for authentication
- #4 Implement Lambda function for authentication
- #5 Implement Lambda function for data upload
- #6 Configure API Gateway REST API
- #7 Complete CloudFormation template for full stack
- #8 Test AWS deployment end-to-end
- #9 Write AWS deployment documentation

### v0.3.0: Android MVP
**Due**: March 15, 2026
**Goal**: Basic Android app with one sensor collecting data to AWS

**Issues (7)**:
- #10 Set up Android project structure with MVVM
- #11 Implement Cognito authentication in Android app
- #12 Create Room database for local data storage
- #13 Implement accelerometer sensor module
- #14 Implement data upload service with retry logic
- #15 Create basic UI for status dashboard
- #16 Test Android MVP end-to-end on Fire Tablet

### v0.4.0: iOS MVP
**Due**: April 15, 2026
**Goal**: Basic iOS app with HealthKit data collecting to AWS

**Issues (6)**:
- #17 Set up iOS project structure with SwiftUI
- #18 Implement Cognito authentication in iOS app
- #19 Implement HealthKit integration for steps data
- #20 Implement data upload service in iOS
- #21 Create basic UI for iOS status dashboard
- #22 Test iOS MVP end-to-end on iPhone

### v0.5.0: Data Access Working
**Due**: May 15, 2026
**Goal**: OSRPData returns real data from deployed system

**Issues (5)**:
- #23 Test OSRPData with real AWS data
- #24 Fix bugs in OSRPData data retrieval
- #25 Update Marimo notebook to work with real data
- #26 Verify end-to-end data flow from app to analysis
- #27 Write comprehensive data access documentation

### v1.0.0: Production Ready
**Due**: June 30, 2026
**Goal**: Complete system ready for research studies

**Issues**: To be created after MVP complete

---

## Labels Created

### Type Labels
- `type: feature` (blue) - New functionality
- `type: bug` (red) - Something broken
- `type: enhancement` (light blue) - Improve existing feature
- `type: docs` (blue) - Documentation updates
- `type: infrastructure` (dark blue) - AWS/backend work
- `type: refactor` (yellow) - Code improvement

### Platform Labels
- `platform: android` (green) - Android app work
- `platform: ios` (light green) - iOS app work
- `platform: aws` (dark green) - AWS infrastructure
- `platform: python` (medium green) - Python package work
- `platform: web` (very light green) - Landing page/docs site

### Priority Labels
- `priority: critical` (red) - Must have for MVP
- `priority: high` (orange) - Important but not blocking
- `priority: medium` (yellow) - Nice to have
- `priority: low` (very light yellow) - Future consideration

### Status Labels
- `status: blocked` (purple) - Can't proceed
- `status: needs-review` (light purple) - Ready for code review
- `status: needs-testing` (very light purple) - Needs QA
- `status: needs-discussion` (lightest purple) - Requires team input

### Size Labels
- `size: xs` (very light gray) - < 1 hour
- `size: s` (light gray) - 1-4 hours
- `size: m` (medium gray) - 1-2 days
- `size: l` (dark gray) - 3-5 days
- `size: xl` (very dark gray) - 1+ weeks

---

## MVP Scope

### What's Included in MVP

**AWS Infrastructure**:
- ✅ DynamoDB tables for basic data storage
- ✅ S3 bucket for file storage
- ✅ Cognito authentication
- ✅ Lambda functions (auth + data upload)
- ✅ API Gateway
- ✅ CloudFormation template

**Android MVP**:
- ✅ Basic app structure (MVVM)
- ✅ Authentication with Cognito
- ✅ One sensor: Accelerometer
- ✅ Local database (Room)
- ✅ Background data upload
- ✅ Simple status UI

**iOS MVP**:
- ✅ Basic app structure (SwiftUI)
- ✅ Authentication with Cognito
- ✅ HealthKit integration (steps only)
- ✅ Data upload to AWS
- ✅ Simple status UI

**Data Access**:
- ✅ OSRPData can retrieve real data
- ✅ One Marimo notebook works
- ✅ End-to-end data flow verified

### What's NOT in MVP (v1.0.0+)

**Android**:
- ❌ Screenshots (add later)
- ❌ App usage tracking
- ❌ Multiple sensors
- ❌ Google Fit integration
- ❌ Bluetooth wearables
- ❌ EMA/surveys

**iOS**:
- ❌ Multiple HealthKit data types
- ❌ Motion sensors
- ❌ Location tracking
- ❌ Advanced background processing

**Analysis**:
- ❌ Multiple notebooks
- ❌ Advanced ML pipelines
- ❌ Feature engineering tools
- ❌ Visualization dashboard

---

## Development Workflow

### Starting Work on an Issue

```bash
# 1. Assign issue to yourself
gh issue edit 13 --add-assignee scttfrdmn

# 2. Create feature branch
git checkout -b feature/13-accelerometer-module

# 3. Update issue status
gh issue edit 13 --add-label "status: in-progress"

# 4. Work on feature
# ... code ...

# 5. Commit with issue reference
git commit -m "Implement accelerometer module

Relates to #13"

# 6. Create PR
gh pr create \
  --title "Implement accelerometer sensor module" \
  --body "Fixes #13" \
  --label "platform: android"

# 7. Merge PR (closes issue automatically)
gh pr merge --squash --delete-branch
```

### Viewing Progress

```bash
# Issues by milestone
gh issue list --milestone "v0.2.0: AWS Foundation"

# Issues by label
gh issue list --label "platform: android"

# Critical issues
gh issue list --label "priority: critical"

# Your assigned issues
gh issue list --assignee @me

# Milestone progress
gh issue list --milestone "v0.3.0: Android MVP" --json number,title,state
```

### Creating New Issues

```bash
gh issue create \
  --title "Issue title" \
  --body "Detailed description with acceptance criteria" \
  --label "type: feature,platform: android,priority: high,size: m" \
  --milestone "v0.3.0: Android MVP" \
  --assignee scttfrdmn
```

---

## MVP Timeline

### Phase 1: AWS Foundation (4-6 weeks)
**Milestone**: v0.2.0
**Target**: February 15, 2026

**Goals**:
- [ ] Complete CloudFormation template
- [ ] Deploy to AWS dev environment
- [ ] Test all endpoints
- [ ] Documentation complete

**Deliverable**: Working AWS infrastructure

### Phase 2: Android MVP (4-6 weeks)
**Milestone**: v0.3.0
**Target**: March 15, 2026

**Goals**:
- [ ] Android app compiles and runs
- [ ] Authentication works
- [ ] Accelerometer data collects
- [ ] Data uploads to AWS
- [ ] Tested on Fire Tablet

**Deliverable**: Android app collecting sensor data

### Phase 3: iOS MVP (3-4 weeks)
**Milestone**: v0.4.0
**Target**: April 15, 2026

**Goals**:
- [ ] iOS app compiles and runs
- [ ] Authentication works
- [ ] HealthKit steps data collects
- [ ] Data uploads to AWS
- [ ] Tested on iPhone

**Deliverable**: iOS app collecting HealthKit data

### Phase 4: Data Access (2-3 weeks)
**Milestone**: v0.5.0
**Target**: May 15, 2026

**Goals**:
- [ ] OSRPData retrieves real data
- [ ] Notebooks work with real data
- [ ] End-to-end flow verified
- [ ] Documentation complete

**Deliverable**: Complete data pipeline working

---

## Critical Path

```
AWS Foundation (v0.2.0)
    ↓
Android MVP (v0.3.0) ← Can start when AWS partially done
    ↓                   iOS MVP (v0.4.0) ← Can be parallel
    ↓                       ↓
    └─────────┬─────────────┘
              ↓
    Data Access (v0.5.0)
              ↓
    Production Ready (v1.0.0)
```

**Priority Order**:
1. AWS Foundation (blocks everything)
2. Android MVP (higher priority than iOS)
3. iOS MVP (can be parallel with Android)
4. Data Access (requires Android/iOS data)

---

## Next Steps

1. **Create GitHub Project Board**
   - Go to: https://github.com/orgs/open-sensor-research-platform/projects
   - Create "OSRP MVP Development" board
   - Add columns: Backlog, Ready, In Progress, In Review, Done
   - Add all issues to project

2. **Start with AWS Foundation**
   - Begin with issue #1 (DynamoDB schema)
   - Work through issues #1-#9 in order
   - Complete v0.2.0 milestone

3. **Set up Development Environment**
   - Install Android Studio
   - Configure Fire Tablet for development
   - Set up AWS credentials
   - Install Xcode (for iOS later)

4. **Weekly Progress Updates**
   - Review open issues
   - Update issue status
   - Close completed issues
   - Create new issues as needed

---

## Success Criteria

### v0.2.0: AWS Foundation Success
- [ ] CloudFormation stack deploys without errors
- [ ] Can authenticate via Cognito
- [ ] Can write data to DynamoDB
- [ ] Can upload files to S3
- [ ] API Gateway responds correctly
- [ ] Costs are within budget (~$50/month dev)

### v0.3.0: Android MVP Success
- [ ] Android app runs on Fire Tablet
- [ ] Can login with test credentials
- [ ] Accelerometer data collects
- [ ] Data uploads to AWS successfully
- [ ] Can see data in DynamoDB
- [ ] Battery drain acceptable (<20% per day)

### v0.4.0: iOS MVP Success
- [ ] iOS app runs on iPhone
- [ ] Can login with test credentials
- [ ] HealthKit permission granted
- [ ] Steps data collects
- [ ] Data uploads to AWS successfully
- [ ] Can see data in DynamoDB

### v0.5.0: Data Access Success
- [ ] `from osrp import OSRPData` works
- [ ] Can retrieve Android accelerometer data
- [ ] Can retrieve iOS HealthKit data
- [ ] Marimo notebook displays real data
- [ ] No errors or crashes
- [ ] Documentation accurate

---

## Resources

### GitHub CLI Commands
```bash
# List milestones
gh api repos/open-sensor-research-platform/osrp/milestones | jq '.[] | {number, title, due_on, open_issues, closed_issues}'

# Milestone progress
gh issue list --milestone "v0.2.0: AWS Foundation" --state all

# Create issue from template
gh issue create --web

# Update issue
gh issue edit 13 --add-label "status: blocked"

# Close issue
gh issue close 13 --comment "Completed in PR #45"
```

### Documentation
- **GitHub Issues**: https://docs.github.com/en/issues
- **GitHub Projects**: https://docs.github.com/en/issues/planning-and-tracking-with-projects
- **GitHub CLI**: https://cli.github.com/manual/
- **CLAUDE.md**: See "Project Management with GitHub" section

---

**Last Updated**: January 16, 2026
**Status**: MVP planning complete, ready to start development
**Next Milestone**: v0.2.0: AWS Foundation (Due: February 15, 2026)
