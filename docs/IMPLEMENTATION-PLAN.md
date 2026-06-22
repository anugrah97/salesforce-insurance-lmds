# Implementation Plan
**Project:** Insurance Lead Management & Distribution System  
**Platform:** Salesforce  
**Author:** Anugrah Pandya  
**Version:** 1.0  
**Last Updated:** June 2026  
**Repo:** [anugrah97/salesforce-insurance-lmds](https://github.com/anugrah97/salesforce-insurance-lmds)

---

## Approach

| Role | Responsibility |
|------|---------------|
| **Claude Opus** | Architecture decisions, data model design, complex logic planning |
| **Claude Sonnet** | Metadata XML generation, Apex code, LWC components, deployment |
| **Developer (Anugrah)** | Review, deploy via VS Code, UAT, feedback |

All metadata is managed via Salesforce DX (source format) and version-controlled in this repo.  
Deployment tool: VS Code Salesforce Extension Pack → `sf project deploy start`

---

## Phase 1 — Core Lead Management

**Goal:** A fully functional lead capture, deduplication, visibility, activity logging, document management, and AI rule-based scoring system.

**Estimated Duration:** 3–4 weeks

---

### Sprint 1.1 — Data Model & Object Setup

#### Task 1.1.1 — Lead Custom Fields
**File path:** `force-app/main/default/objects/Lead/fields/`

| Field Label | API Name | Type | Details |
|-------------|----------|------|---------|
| Full Name | Full_Name__c | Text(255) | ✅ Done |
| Channel | Channel__c | Picklist | Values: Agency, BANCA, Direct |
| Product | Product__c | Picklist | Values: Term Life, Health, Motor, Home, Travel |
| Branch | Branch__c | Text(100) | Branch name |
| Assigned FLS | Assigned_FLS__c | Lookup(User) | FLS owner |
| Source | Source__c | Picklist | Referral, Web, Walk-In, Campaign, API |
| Lead Score | Lead_Score__c | Number(3,0) | Populated by Apex |
| Propensity Score | Propensity_Score__c | Number(3,0) | Populated by Apex |
| Engagement Score | Engagement_Score__c | Number(3,0) | Populated by Apex |
| Score Tag | Score_Tag__c | Text(20) | Hot / At Risk / Normal |
| Last Score Updated | Last_Score_Updated__c | DateTime | Auto-stamp |
| Is Cross Sell | Is_Cross_Sell__c | Checkbox | Set by dedup logic |
| Activity Count | Activity_Count__c | Number(3,0) | Rollup or Apex-maintained |

#### Task 1.1.2 — Activity Custom Object
**File path:** `force-app/main/default/objects/Lead_Activity__c/`

| Field | API Name | Type |
|-------|----------|------|
| Lead | Lead__c | Master-Detail(Lead) |
| Activity Type | Activity_Type__c | Picklist: Phone Call, Face-to-Face Visit |
| Activity Date | Activity_Date__c | Date |
| Duration (mins) | Duration__c | Number(3,0) |
| Outcome | Outcome__c | Picklist: Interested, Not Interested, Follow Up, No Answer |
| Notes | Notes__c | Long Text Area(2000) |
| Logged By | Logged_By__c | Lookup(User) |

#### Task 1.1.3 — Branch Object
**File path:** `force-app/main/default/objects/Branch__c/`

| Field | API Name | Type |
|-------|----------|------|
| Branch Name | Name | Text |
| Channel | Channel__c | Picklist |
| City | City__c | Text(100) |
| Region | Region__c | Text(100) |
| Is Active | Is_Active__c | Checkbox |

#### Task 1.1.4 — Branch Trainer Mapping Object
**File path:** `force-app/main/default/objects/Branch_Trainer_Mapping__c/`

| Field | API Name | Type |
|-------|----------|------|
| Branch | Branch__c | Lookup(Branch__c) |
| Trainer | Trainer__c | Lookup(User) |
| Is Active | Is_Active__c | Checkbox |

---

### Sprint 1.2 — Security Model

#### Task 1.2.1 — Org-Wide Defaults
**File path:** `force-app/main/default/sharingRules/`

```
Lead OWD:         Private
Branch OWD:       Public Read Only
Activity OWD:     Controlled by Parent (Lead)
```

#### Task 1.2.2 — Role Hierarchy
**Setup path:** Setup → Roles

```
CEO / Admin
├── Agency Head
│   ├── Agency Manager 1
│   │   ├── Agency FLS 1
│   │   └── Agency FLS 2
│   └── Agency Manager 2
│       └── Agency FLS 3
├── BANCA Head
│   └── BANCA Manager 1
│       └── BANCA FLS 1
└── Direct Head
    └── Direct Manager 1
        └── Direct FLS 1
```

#### Task 1.2.3 — Profiles
Create profiles (clone from Standard User):
- `Profile_FLS` — Read/Create on Lead; no Delete
- `Profile_Manager` — Read/Create/Edit on Lead; no Delete
- `Profile_Trainer` — Read-Only on Lead
- `Profile_SalesCoordinator` — Read/Create/Edit/Import on Lead
- `Profile_Admin` — Full access (use System Admin)

#### Task 1.2.4 — Permission Sets
**File path:** `force-app/main/default/permissionsets/`

- `PS_AI_Insights` — Read on score fields; for FLS + Manager
- `PS_BulkImport` — Data Import Wizard access; for Co-ordinator
- `PS_AdminOverride` — Modify All Data; for Admin

#### Task 1.2.5 — Sharing Rules
**File path:** `force-app/main/default/sharingRules/Lead.sharingRules-meta.xml`

- **Rule 1 — Sales Co-ordinator:** Share all leads in Channel__c = [user's channel] with Co-ordinator role → Read/Write
- **Rule 2 — Trainer (Apex Sharing):** On Branch_Trainer_Mapping__c insert/update → Apex triggers sharing of Lead records for mapped FLS with Trainer user (Read Only)

---

### Sprint 1.3 — Deduplication Engine

#### Task 1.3.1 — Matching Rule
**File path:** `force-app/main/default/matchingRules/Lead.matchingRule-meta.xml`

```xml
Rule Name: Lead_Dedup_By_Mobile_Product
Object: Lead
Match on:
  - MobilePhone (Exact)
  - Product__c (Exact)
Match Blank Fields: false
```

#### Task 1.3.2 — Duplicate Rules
**File path:** `force-app/main/default/duplicateRules/Lead.duplicateRule-meta.xml`

```
Rule 1 — Block Same Product:
  Matching Rule: Lead_Dedup_By_Mobile_Product
  Action on Insert: Block
  Action on Edit: Allow + Alert
  Error Message: "A lead for this customer for {Product__c} already exists."

Rule 2 — Alert Cross Product:
  Matching Rule: Lead_Dedup_By_Mobile (email or mobile only)
  Action: Alert (not block)
  Alert Message: "This customer has an existing lead for another product."
```

#### Task 1.3.3 — Mobile Normalisation (Apex)
**File path:** `force-app/main/default/classes/LeadNormaliser.cls`

```apex
// Strips +91, spaces, and dashes from MobilePhone before insert/update
trigger LeadBeforeInsert on Lead (before insert, before update) {
    for (Lead l : Trigger.new) {
        if (l.MobilePhone != null) {
            l.MobilePhone = l.MobilePhone.replaceAll('[^0-9]', '');
            if (l.MobilePhone.startsWith('91') && l.MobilePhone.length() == 12) {
                l.MobilePhone = l.MobilePhone.substring(2);
            }
        }
    }
}
```

---

### Sprint 1.4 — AI Rule-Based Scoring

#### Task 1.4.1 — Scoring Apex Class
**File path:** `force-app/main/default/classes/LeadScoringEngine.cls`

**Lead Score Logic:**
```
Base = 0
+ Email present:           +10
+ Mobile present:          +10
+ Product filled:          +10
+ Source = Referral:       +20
+ Source = Web/API:        +10
+ Activity (Phone Call):   +15 per call (max 30)
+ Activity (F2F):          +20 per visit (max 40)
+ Response < 24h:          +5
Max score:                 100
```

**Propensity Score Logic:**
```
Channel base:
  Agency:  45
  BANCA:   60
  Direct:  35
Adjustments:
  + Activity Count > 2:   +10
  + Lead Score > 60:      +15
  + Source = Referral:    +10
  - Lead Age > 30 days:   -10
```

**Engagement Score Logic:**
```
0 activities:     0
1 activity:       25
2 activities:     50
3+ activities:    75
F2F in last 7d:  +25 (max 100)
```

#### Task 1.4.2 — Score Trigger
**File path:** `force-app/main/default/classes/LeadScoringTrigger.cls`

- Fires on Lead_Activity__c insert/update (after)
- Recalculates all 3 scores for the parent lead
- Updates Score_Tag__c: "Hot" if Propensity > 75, "At Risk" if Lead Score < 30 + no activity > 7 days

#### Task 1.4.3 — Scheduled Score Refresh
**File path:** `force-app/main/default/classes/LeadScoreScheduler.cls`

- Runs daily at midnight
- Flags "At Risk" leads (Score < 30, no activity 7+ days)
- Sends in-app notification to FLS + Manager for At Risk leads

#### Task 1.4.4 — AI Insights LWC Component
**File path:** `force-app/main/default/lwc/aiInsightsPanel/`

- Files: `aiInsightsPanel.html`, `aiInsightsPanel.js`, `aiInsightsPanel.css`, `aiInsightsPanel.js-meta.xml`
- Displays: Lead Score, Propensity Score, Engagement Score with colour badges
- Shows "Hot" or "At Risk" tag if applicable
- Placed in Lead Record Page right sidebar via App Builder

---

### Sprint 1.5 — Document Management

#### Task 1.5.1 — Files Configuration
- Enable Salesforce Files on Lead, Opportunity, Policy__c objects
- Add Files related list to Lead, Proposal, Policy page layouts
- Configure Content Type validation via Apex trigger on ContentDocument:
  - Allowed: PDF, JPG, PNG
  - Max size: 10 MB
  - Block: xlsx, doc, zip, exe

**File path:** `force-app/main/default/classes/FileValidationTrigger.cls`

---

### Sprint 1.6 — Page Layouts & App Builder

#### Task 1.6.1 — Lead Page Layout
- Add custom fields: Channel__c, Product__c, Branch__c, Assigned_FLS__c, Source__c, Full_Name__c
- Add Activities related list (Lead_Activity__c)
- Add Files related list
- AI Insights Panel: right sidebar via App Builder (LWC)

#### Task 1.6.2 — Lead List Views
- **FLS View:** My Leads — filter: Assigned_FLS__c = current user
- **Manager View:** Team Leads — filter: role hierarchy
- **Co-ordinator View:** All Channel Leads — filter: Channel__c = user's channel
- **Admin View:** All Leads

---

### Sprint 1.7 — Testing & Deployment (Phase 1)

| Task | Description |
|------|-------------|
| T1 | Deploy all metadata to Developer org via VS Code |
| T2 | Execute TC-001 through TC-088 (Phase 1 scope) |
| T3 | Create test users: 1 FLS, 1 Manager, 1 Trainer, 1 Co-ordinator per channel |
| T4 | Validate sharing rules with each test user |
| T5 | Validate deduplication (TC-016 through TC-019) |
| T6 | Validate AI scoring (TC-080 through TC-088) |
| T7 | Commit passing state to `release/phase-1` branch |

---

## Phase 2 — API Integration & Proposal Journey

**Estimated Duration:** 2–3 weeks

### Key Tasks

| Task | Details |
|------|---------|
| 2.1 — Connected App | Create Connected App for OAuth 2.0 client credentials |
| 2.2 — REST Endpoint | `LeadAPIController` Apex REST class: `POST /services/apexrest/v1/leads` |
| 2.3 — Dummy Web Form | HTML page in `/api-demo/index.html` — form submits to SF endpoint |
| 2.4 — Opportunity Object | Add custom fields: DDE_Form_Complete__c, BI_Selected__c, Payment_Status__c, Product__c |
| 2.5 — DDE Form LWC | `force-app/main/default/lwc/ddeForm/` — captures full customer details |
| 2.6 — BI Illustration | `force-app/main/default/lwc/biIllustration/` — static product sample display |
| 2.7 — Policy Object | Create Policy__c custom object with all fields |
| 2.8 — Customer ID Logic | Apex: on first Policy__c insert, generate and stamp Customer_ID__c on Contact |
| 2.9 — Document Upload | Extend file validation to Opportunity and Policy__c |

---

## Phase 3 — Customer 360, WhatsApp & Einstein AI

**Estimated Duration:** 3–4 weeks

### Key Tasks

| Task | Details |
|------|---------|
| 3.1 — WhatsApp Endpoint | Apex REST webhook: `POST /services/apexrest/v1/whatsapp` |
| 3.2 — Case Creation | Auto-create Case from webhook payload; link to Contact by mobile |
| 3.3 — Customer 360 Page | Lightning App Builder page on Contact; 6 LWC sections |
| 3.4 — 360 LWC Components | `lwc/customerLeads`, `lwc/customerProposals`, `lwc/customerPolicies`, `lwc/customerCases`, `lwc/customerActivities`, `lwc/aiScoreSummary` |
| 3.5 — Einstein Lead Scoring | Enable in Setup → Einstein → Lead Scoring (data threshold check first) |
| 3.6 — Einstein Opp Scoring | Enable on Opportunity object when 500+ Proposals exist |
| 3.7 — Score Automations | Flow: Hot/At Risk notifications; Case creation for Churn Risk > 70 |

---

## Phase 4 — Dashboards & Enhancements

**Estimated Duration:** 1–2 weeks

### Key Tasks

| Task | Details |
|------|---------|
| 4.1 — Manager Dashboard | Report: Lead funnel by FLS; Chart: conversion rates; Filter: date range |
| 4.2 — Lead Age Alert | Scheduled Flow: daily check for leads not contacted in X days → email |
| 4.3 — Re-assignment Flow | Screen Flow: Co-ordinator selects stale leads → assigns to new FLS → notification |
| 4.4 — Channel Reports | Report folder per channel; metrics: volume, conversion, avg age |

---

## Branch Strategy

```
main                  ← stable, deployed state
  └── release/phase-1 ← Phase 1 complete
  └── release/phase-2 ← Phase 2 complete
  └── release/phase-3 ← Phase 3 complete
  └── release/phase-4 ← Phase 4 complete
  └── feature/*       ← individual feature branches (merged to release/phase-N)
```

---

## Deployment Checklist (Each Phase)

- [ ] All metadata in `force-app/main/default/`
- [ ] `package.xml` updated with new components
- [ ] Apex classes have corresponding test classes (>75% coverage)
- [ ] No hardcoded IDs in Apex or metadata
- [ ] All custom labels in `force-app/main/default/labels/`
- [ ] Deploy to org: `sf project deploy start --target-org trailhead-dev`
- [ ] Run Apex tests: `sf apex run test --target-org trailhead-dev --result-format human`
- [ ] All Phase test cases pass (see TEST-CASES.md)
- [ ] Commit to `release/phase-N` branch
- [ ] Update RTM.md status column

---

*This plan is maintained alongside PRD.md and updated at each sprint.*
