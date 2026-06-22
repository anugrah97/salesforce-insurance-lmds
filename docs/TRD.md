# Technical Requirements Document (TRD)
**Project:** Insurance Lead Management & Distribution System  
**Platform:** Salesforce (API v67.0)  
**Author:** Anugrah Pandya  
**Version:** 1.0  
**Last Updated:** June 2026  
**Repo:** [anugrah97/salesforce-insurance-lmds](https://github.com/anugrah97/salesforce-insurance-lmds)

---

## Table of Contents
1. [System Overview](#1-system-overview)
2. [Data Model](#2-data-model)
3. [Security Architecture](#3-security-architecture)
4. [API Specifications](#4-api-specifications)
5. [Integration Architecture](#5-integration-architecture)
6. [AI Scoring Technical Spec](#6-ai-scoring-technical-spec)
7. [Automation & Flow Design](#7-automation--flow-design)
8. [LWC Component Architecture](#8-lwc-component-architecture)
9. [Performance & Scalability](#9-performance--scalability)
10. [Error Handling & Logging](#10-error-handling--logging)
11. [Deployment Architecture](#11-deployment-architecture)
12. [Tech Stack Summary](#12-tech-stack-summary)

---

## 1. System Overview

The Insurance Lead Management & Distribution System is built entirely on the **Salesforce Platform** using Salesforce DX (source-driven development). It uses standard Salesforce objects (Lead, Opportunity, Contact, Case) extended with custom objects and fields, combined with Apex classes, Lightning Web Components, Flows, and Einstein AI features.

### Core Principles
- **Config over code:** Salesforce declarative tools (Flows, Sharing Rules, Duplicate Rules) used wherever possible
- **Apex only when needed:** Complex deduplication logic, scoring, sharing, and API endpoints
- **Source-driven:** All configuration stored as metadata XML in this repo, not clicked in Setup
- **API-first:** Lead ingestion via REST API, WhatsApp via webhook — no UI dependency for integrations

---

## 2. Data Model

### 2.1 Object Relationship Diagram

```
Contact (Customer)
  ├── Lead__c (multiple, one per product interest)
  │     ├── Lead_Activity__c (multiple — calls, F2F visits)
  │     └── ContentDocumentLink (files — KYC, docs)
  ├── Opportunity (Proposal — one per Lead conversion)
  │     └── ContentDocumentLink (files — signed proposals)
  ├── Policy__c (one per purchased product)
  │     └── ContentDocumentLink (files — policy docs)
  └── Case (WhatsApp queries)

Branch__c
  └── Branch_Trainer_Mapping__c → User (Trainer)

User
  ├── Profile (FLS / Manager / Trainer / Co-ordinator / Admin)
  └── Branch__c (lookup — their assigned branch)
```

---

### 2.2 Standard Objects Used

| Object | Purpose | Key Custom Fields Added |
|--------|---------|------------------------|
| Lead | Primary lead record | Channel__c, Product__c, Branch__c, Assigned_FLS__c, Source__c, Full_Name__c, Lead_Score__c, Propensity_Score__c, Engagement_Score__c, Score_Tag__c, Is_Cross_Sell__c, Activity_Count__c |
| Opportunity | Proposal record | DDE_Form_Complete__c, BI_Selected__c, Payment_Status__c, Product__c, Channel__c |
| Contact | Customer master | Customer_ID__c, Channel__c, First_Policy_Date__c |
| Case | WhatsApp queries | Origin = WhatsApp, Customer_Mobile__c, Linked via Contact |
| User | FLS / Manager / Trainer / Co-ord | Channel__c, Branch__c (custom fields on User object) |

---

### 2.3 Custom Objects

#### Lead_Activity__c
| Field | API Name | Type | Required |
|-------|----------|------|----------|
| Lead | Lead__c | Master-Detail(Lead) | Yes |
| Activity Type | Activity_Type__c | Picklist | Yes |
| Activity Date | Activity_Date__c | Date | Yes |
| Duration (mins) | Duration__c | Number(3,0) | No |
| Outcome | Outcome__c | Picklist | Yes |
| Notes | Notes__c | Long Text Area(2000) | No |
| Logged By | Logged_By__c | Lookup(User) | Yes |

**OWD:** Controlled by Parent  
**Sharing:** Inherits from Lead

---

#### Policy__c
| Field | API Name | Type | Required |
|-------|----------|------|----------|
| Policy Number | Name | Auto Number | Auto |
| Contact | Contact__c | Master-Detail(Contact) | Yes |
| Proposal | Opportunity__c | Lookup(Opportunity) | Yes |
| Product | Product__c | Picklist | Yes |
| Channel | Channel__c | Picklist | Yes |
| Premium | Premium__c | Currency(10,2) | Yes |
| Start Date | Start_Date__c | Date | Yes |
| End Date | End_Date__c | Date | No |
| Status | Status__c | Picklist: Active, Lapsed, Cancelled | Yes |
| Customer ID | Customer_ID__c | Text(20) | Auto-set |
| Assigned FLS | Assigned_FLS__c | Lookup(User) | Yes |

**OWD:** Private  
**Auto Number Format:** POL-{0000000}

---

#### Branch__c
| Field | API Name | Type | Required |
|-------|----------|------|----------|
| Branch Name | Name | Text(100) | Yes |
| Channel | Channel__c | Picklist | Yes |
| City | City__c | Text(100) | Yes |
| Region | Region__c | Text(100) | No |
| Is Active | Is_Active__c | Checkbox | Yes |

---

#### Branch_Trainer_Mapping__c
| Field | API Name | Type | Required |
|-------|----------|------|----------|
| Branch | Branch__c | Lookup(Branch__c) | Yes |
| Trainer | Trainer__c | Lookup(User) | Yes |
| Is Active | Is_Active__c | Checkbox | Yes |

**Unique constraint:** Branch__c + Trainer__c combination must be unique

---

### 2.4 Picklist Values

**Channel__c** (used across Lead, Opportunity, Policy__c, User, Branch__c)
- Agency
- BANCA
- Direct

**Product__c**
- Term Life
- Health Insurance
- Motor Insurance
- Home Insurance
- Travel Insurance

**Source__c** (Lead)
- Referral
- Web
- Walk-In
- Campaign
- API
- WhatsApp
- Import

**Activity_Type__c**
- Phone Call
- Face-to-Face Visit

**Outcome__c**
- Interested
- Not Interested
- Follow Up Required
- No Answer
- Left Voicemail

**Score_Tag__c**
- Hot
- At Risk
- Normal

---

## 3. Security Architecture

### 3.1 Object-Wide Defaults (OWD)

| Object | OWD | Rationale |
|--------|-----|-----------|
| Lead | Private | All sharing via rules/hierarchy only |
| Lead_Activity__c | Controlled by Parent | Inherits Lead visibility |
| Opportunity | Private | Proposal data sensitive |
| Policy__c | Private | Policy data sensitive |
| Branch__c | Public Read Only | Reference data; all can see |
| Branch_Trainer_Mapping__c | Public Read Only | Admins create; all read |
| Case | Private | Customer query data sensitive |
| Contact | Private | Customer master data |

---

### 3.2 Role Hierarchy

```
System Administrator
└── Executive / Admin
    ├── Agency Head
    │   ├── Agency Manager
    │   │   └── Agency FLS
    │   └── Agency Sales Co-ordinator (flat — not in FLS hierarchy)
    ├── BANCA Head
    │   ├── BANCA Manager
    │   │   └── BANCA FLS
    │   └── BANCA Sales Co-ordinator
    └── Direct Head
        ├── Direct Manager
        │   └── Direct FLS
        └── Direct Sales Co-ordinator
```

> **Note:** Trainers are NOT in the FLS reporting hierarchy. They are assigned at the Branch level via `Branch_Trainer_Mapping__c`. Trainer sharing is handled by Apex Managed Sharing (not role hierarchy).

---

### 3.3 Sharing Rules

#### Rule 1 — Sales Co-ordinator Channel Share
- **Type:** Criteria-based
- **Object:** Lead
- **Criteria:** `Channel__c = [user's channel]`
- **Share with:** Sales Co-ordinator role (same channel)
- **Access:** Read/Write

#### Rule 2 — Trainer Branch Share (Apex Managed Sharing)
- **Trigger:** `Branch_Trainer_Mapping__c` insert/update/delete
- **Logic:**
  1. Find all FLS Users where `Branch__c` = mapped Branch
  2. Find all Lead records where `Assigned_FLS__c` IN [FLS User IDs]
  3. Insert `LeadShare` records: `UserOrGroupId` = Trainer, `AccessLevel` = Read
  4. On mapping deactivation/delete, remove corresponding `LeadShare` records
- **File:** `force-app/main/default/classes/TrainerSharingService.cls`

---

### 3.4 Profile Permissions Summary

| Object | FLS | Manager | Trainer | Co-ord | Admin |
|--------|-----|---------|---------|--------|-------|
| Lead — Create | ✅ | ✅ | ❌ | ✅ | ✅ |
| Lead — Read | ✅ | ✅ | ✅ | ✅ | ✅ |
| Lead — Edit | ✅ | ✅ | ❌ | ✅ | ✅ |
| Lead — Delete | ❌ | ❌ | ❌ | ❌ | ✅ |
| Lead — Import | ❌ | ❌ | ❌ | ✅ | ✅ |
| Lead_Activity__c — Create | ✅ | ✅ | ✅ | ✅ | ✅ |
| Policy__c — Read | ✅ | ✅ | ✅ | ✅ | ✅ |
| Policy__c — Create/Edit | ❌ | ❌ | ❌ | ✅ | ✅ |

---

## 4. API Specifications

### 4.1 Lead Ingestion API

**Endpoint:** `POST /services/apexrest/v1/leads`  
**Auth:** OAuth 2.0 Client Credentials (Connected App)  
**Content-Type:** `application/json`

#### Request Body
```json
{
  "firstName": "Priya",
  "lastName": "Mehta",
  "mobile": "9123456789",
  "email": "priya@example.com",
  "product": "Term Life",
  "source": "API",
  "channel": "Direct",
  "branch": "Mumbai"
}
```

#### Success Response (HTTP 200)
```json
{
  "success": true,
  "leadId": "00Q8g000001AbCdEAC",
  "message": "Lead created successfully"
}
```

#### Duplicate Response (HTTP 200)
```json
{
  "success": false,
  "error": "DUPLICATE_LEAD",
  "message": "A lead for Term Life already exists for this customer",
  "existingLeadId": "00Q8g000001XyZaEAC"
}
```

#### Validation Error (HTTP 400)
```json
{
  "success": false,
  "error": "VALIDATION_ERROR",
  "message": "mobile is required"
}
```

#### Apex Class
**File:** `force-app/main/default/classes/LeadAPIController.cls`

```apex
@RestResource(urlMapping='/v1/leads')
global class LeadAPIController {
    @HttpPost
    global static Map<String, Object> createLead() {
        // 1. Parse request body
        // 2. Validate required fields
        // 3. Normalise mobile
        // 4. Run deduplication check
        // 5. If duplicate → return error with existing ID
        // 6. Else create Lead and return success
    }
}
```

---

### 4.2 WhatsApp Webhook

**Endpoint:** `POST /services/apexrest/v1/whatsapp`  
**Auth:** Shared secret header (`X-WhatsApp-Secret`)

#### Payload (from WhatsApp Open API)
```json
{
  "from": "919876543210",
  "timestamp": "2026-06-22T10:30:00Z",
  "message": {
    "id": "wamid.XXXX",
    "type": "text",
    "text": { "body": "I need help with my policy renewal" }
  }
}
```

#### Processing Logic
1. Validate `X-WhatsApp-Secret` header
2. Normalise mobile: strip `91` prefix → 10-digit format
3. Lookup Contact by `MobilePhone = normalised_mobile`
4. Create Case:
   - `Subject` = first 50 chars of message body
   - `Origin` = "WhatsApp"
   - `Status` = "Open"
   - `ContactId` = matched Contact (if found)
   - `Customer_Mobile__c` = raw mobile from payload
5. Return `{ "success": true }`

**File:** `force-app/main/default/classes/WhatsAppWebhookController.cls`

---

## 5. Integration Architecture

### 5.1 Dummy Web Form (API Demo)

**Location in repo:** `/api-demo/index.html`

A single-page HTML form that:
- Collects: First Name, Last Name, Mobile, Email, Product, Source, Channel
- On submit: POSTs JSON to Salesforce REST endpoint using fetch API
- Displays success/error response inline
- Includes Salesforce OAuth token retrieval (client credentials flow, token stored in-memory)

This file is deployed as a static web page (can be hosted on GitHub Pages from the repo itself).

---

### 5.2 WhatsApp Integration (Dummy)

For development/testing, WhatsApp messages are simulated by:
1. A Postman collection in `/api-demo/postman/WhatsApp-Simulator.postman_collection.json`
2. Or a simple HTML form in `/api-demo/whatsapp-simulator.html`

Production WhatsApp setup (Meta Business API / WATI / Twilio) is a Phase 3 decision pending OQ3 resolution.

---

### 5.3 Integration Data Flow

```
External Source          Salesforce Platform
─────────────────        ──────────────────────────────────────
Dummy Web Form    ──→    LeadAPIController (REST)
                              ↓
                         LeadNormaliser (Trigger — before insert)
                              ↓
                         Duplicate Rules Check
                              ↓
                         Lead Created
                              ↓
                         LeadScoringEngine (Trigger — after insert)
                              ↓
                         Lead Score / Propensity Score set

WhatsApp Provider ──→    WhatsAppWebhookController (REST)
                              ↓
                         Contact Lookup by Mobile
                              ↓
                         Case Created
                              ↓
                         Customer 360 updated
```

---

## 6. AI Scoring Technical Spec

### 6.1 Scoring Engine Architecture

```
Lead record insert/update
        ↓
LeadScoringTrigger (Apex Trigger — after insert/update)
        ↓
LeadScoringEngine.calculate(leadIds) [queueable]
        ↓
    ┌───────────────────────────────────────┐
    │  calculateLeadScore(lead)             │
    │  calculatePropensityScore(lead)       │
    │  calculateEngagementScore(lead)       │
    └───────────────────────────────────────┘
        ↓
Update Lead fields:
  Lead_Score__c
  Propensity_Score__c
  Engagement_Score__c
  Score_Tag__c
  Last_Score_Updated__c
        ↓
ScoreAutomationService.evaluate(lead) [if tag changed]
        ↓
  Notify FLS + Manager if "Hot" or "At Risk"
```

### 6.2 Class Structure

| Class | Responsibility |
|-------|---------------|
| `LeadScoringTrigger` | After insert/update on Lead + Lead_Activity__c; enqueues scoring |
| `LeadScoringEngine` | Queueable Apex; calculates all 3 scores; updates Lead |
| `LeadScoreCalculator` | Pure function class; takes Lead + Activities; returns scores |
| `ScoreAutomationService` | Sends notifications; applies tags; creates Cases for churn |
| `LeadScoreScheduler` | Schedulable Apex; runs daily; re-evaluates aging/at-risk leads |

### 6.3 Governor Limit Handling

- Scoring runs as **Queueable** (not synchronous) to avoid DML limits in triggers
- Batch size: max 200 leads per Queueable execution
- For bulk imports: `LeadScoringBatch` (Database.Batchable) with batch size 50

### 6.4 Einstein AI Transition (Phase 3)

When transitioning from rule-based to Einstein ML:
1. Einstein Lead Scoring is enabled in Setup — it adds its own `Lead.Einstein_Score` field
2. Custom `Lead_Score__c` is maintained as rule-based fallback
3. AI Insights LWC updated to show both: "Our Score" (rule-based) and "Einstein Score" (ML)
4. Threshold: Einstein enabled only when ≥ 500 converted leads exist per channel

---

## 7. Automation & Flow Design

### 7.1 Flows

| Flow Name | Type | Trigger | Purpose |
|-----------|------|---------|---------|
| `Lead_Status_Validation` | Record-Triggered | Lead before save | Block invalid status transitions |
| `Lead_Assignment_Notify` | Record-Triggered | Lead after update (Assigned_FLS__c changed) | Email FLS on assignment |
| `Lead_Age_Alert` | Scheduled | Daily 9 AM | Flag leads with no activity > 7 days |
| `Proposal_To_Policy` | Record-Triggered | Opportunity after update (Payment_Status__c = Paid) | Create Policy__c record |
| `Customer_ID_Generator` | Record-Triggered | Policy__c after insert | Generate Customer_ID__c on first policy |
| `Churn_Risk_Case_Creator` | Record-Triggered | Contact after update (Churn_Risk_Score__c > 70) | Create retention Case |
| `WhatsApp_Case_SLA_Alert` | Scheduled | Hourly | Flag Cases open > 24 hours |

### 7.2 Flow File Paths
`force-app/main/default/flows/`

---

## 8. LWC Component Architecture

### 8.1 Component List

| Component | Location | Purpose |
|-----------|----------|---------|
| `aiInsightsPanel` | Lead page layout (right sidebar) | Displays Lead Score, Propensity, Engagement with badges |
| `ddeForm` | Opportunity (Proposal) page | Full customer data capture form |
| `biIllustration` | Opportunity page | Static BI illustration per product |
| `customerLeads` | Customer 360 page | All leads for a contact |
| `customerProposals` | Customer 360 page | All proposals for a contact |
| `customerPolicies` | Customer 360 page | All policies for a contact |
| `customerCases` | Customer 360 page | All WhatsApp cases for a contact |
| `customerActivities` | Customer 360 page | Activity timeline across all leads |
| `aiScoreSummary` | Customer 360 page | High-level AI score card |
| `leadImporter` | Leads tab | Bulk CSV import UI |

### 8.2 Component Communication

```
Customer 360 Parent Page
        │
        ├── aiScoreSummary (reads Contact's latest Lead scores via @wire)
        ├── customerLeads (queries Lead WHERE ContactId = recordId)
        ├── customerProposals (queries Opportunity WHERE ContactId = recordId)
        ├── customerPolicies (queries Policy__c WHERE Contact__c = recordId)
        ├── customerCases (queries Case WHERE ContactId = recordId AND Origin = 'WhatsApp')
        └── customerActivities (queries Lead_Activity__c via Lead JOIN)
```

All components use `@wire(getRecord)` or `@wire(apex)` with Apex `@AuraEnabled(cacheable=true)` methods. No direct SOQL in JS.

---

## 9. Performance & Scalability

### 9.1 SOQL Optimisation Rules
- No SOQL inside loops (enforced via Apex code review checklist)
- All queries use selective filters (indexed fields: `Channel__c`, `Assigned_FLS__c`, `MobilePhone`, `Status`)
- LWC components use `cacheable=true` on read-only Apex methods
- Customer 360 components lazy-load (only query when section is expanded)

### 9.2 Bulk Operation Handling
- Lead import: `Database.insert(leads, false)` — partial success allowed, error log returned
- Scoring: Queueable/Batchable — never synchronous on trigger
- Sharing recalculation: Async via `System.enqueueJob` after Branch_Trainer_Mapping__c changes

### 9.3 Expected Data Volume

| Object | Year 1 Estimate | Year 3 Estimate |
|--------|----------------|----------------|
| Lead | 50,000 | 500,000 |
| Lead_Activity__c | 150,000 | 1,500,000 |
| Opportunity | 10,000 | 100,000 |
| Policy__c | 5,000 | 50,000 |
| Case | 2,000 | 20,000 |
| Contact | 40,000 | 400,000 |

No custom indexing required at Year 1 volumes. Revisit at Year 3.

---

## 10. Error Handling & Logging

### 10.1 Apex Error Logging
All Apex classes log exceptions to a custom object `Error_Log__c`:

| Field | Value |
|-------|-------|
| Class | Apex class name |
| Method | Method where error occurred |
| Error Message | Exception.getMessage() |
| Stack Trace | Exception.getStackTraceString() |
| Record ID | Related record if applicable |
| Timestamp | Auto |

### 10.2 API Error Responses
All REST endpoints return structured JSON errors (see Section 4). HTTP 500 responses are caught and returned as: `{ "success": false, "error": "INTERNAL_ERROR", "message": "..." }`.

### 10.3 Flow Error Handling
All Record-Triggered Flows have a Fault path → create `Error_Log__c` record.

---

## 11. Deployment Architecture

### 11.1 Environments

| Environment | Purpose | Auth Alias |
|-------------|---------|-----------|
| Developer Edition (Trailhead) | Primary development org | `trailhead-dev` |
| Scratch Org (future) | Feature-branch testing | `scratch-[feature]` |
| Production (future) | Live org | `prod` |

### 11.2 Deployment Commands

```bash
# Full project deploy
sf project deploy start --target-org trailhead-dev

# Deploy specific component
sf project deploy start --metadata CustomField:Lead.Full_Name__c --target-org trailhead-dev

# Run all Apex tests
sf apex run test --target-org trailhead-dev --result-format human --code-coverage

# Retrieve latest org state
sf project retrieve start --target-org trailhead-dev
```

### 11.3 package.xml Strategy
- `manifest/package.xml` — full project manifest (all components)
- `manifest/package-phase1.xml` — Phase 1 only (for targeted deploys)
- `manifest/package-phase2.xml` — Phase 2 delta only

---

## 12. Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| Platform | Salesforce (Summer '25, API v67.0) |
| Data | Standard Objects (Lead, Opp, Contact, Case) + Custom Objects |
| Business Logic | Apex (Triggers, Queueable, Batch, Scheduled, REST) |
| UI | Lightning Web Components (LWC) + Lightning App Builder |
| Security | Profiles, Permission Sets, OWD, Role Hierarchy, Sharing Rules, Apex Sharing |
| Deduplication | Matching Rules + Duplicate Rules + Apex normalisation |
| AI (Phase 1) | Rule-based Apex scoring engine |
| AI (Phase 3) | Einstein Lead Scoring + Einstein Opportunity Scoring |
| AI (Phase 4) | Salesforce Data Cloud + Einstein Studio (custom models) |
| Integration | Apex REST API, OAuth 2.0 Connected App |
| WhatsApp | Open API webhook → Apex REST receiver |
| Dev Tooling | VS Code + Salesforce Extension Pack, Salesforce CLI (sf v2) |
| Version Control | Git + GitHub (this repo) |
| Planning Agent | Claude Opus |
| Implementation Agent | Claude Sonnet |

---

*This TRD is a living document. Updated at the start of each phase to reflect implementation decisions.*
