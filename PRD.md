# PRD: Insurance Lead Management & Distribution System
**Platform:** Salesforce  
**Author:** Anugrah Pandya  
**Version:** 1.1 (Planning Phase)  
**Status:** Draft  
**Last Updated:** June 2026  

---

## Table of Contents
1. [Problem Statement](#1-problem-statement)
2. [Goals](#2-goals)
3. [Non-Goals](#3-non-goals)
4. [User Roles & Permissions](#4-user-roles--permissions)
5. [System Architecture Overview](#5-system-architecture-overview)
6. [User Stories](#6-user-stories)
7. [Functional Requirements](#7-functional-requirements)
8. [Deduplication Logic](#8-deduplication-logic)
9. [Lead Lifecycle](#9-lead-lifecycle)
10. [Channel Structure](#10-channel-structure)
11. [AI Scoring & Intelligence](#11-ai-scoring--intelligence)
12. [WhatsApp Integration](#12-whatsapp-integration)
13. [Customer 360](#13-customer-360)
14. [Success Metrics](#14-success-metrics)
15. [Open Questions](#15-open-questions)
16. [Phasing & Timeline](#16-phasing--timeline)
17. [Technical Notes](#17-technical-notes)

---

## 1. Problem Statement

Insurance distribution businesses operate across multiple sales channels (Agency, BANCA, Direct) with teams of varying seniority — each requiring different visibility into lead data. Currently, leads arriving from diverse sources (manual entry, bulk import, API) are not unified, resulting in duplicate outreach, missed follow-ups, and no end-to-end customer view.

There is no single system that governs the journey from a raw lead → active engagement → proposal → policy issuance, nor one that ties all of a customer's touchpoints into a unified 360° view. This creates friction for Sales teams, blind spots for managers, and a poor onboarding experience for customers.

The cost of not solving this is lost revenue through lead leakage, inconsistent customer experience, and inability to measure channel performance accurately.

---

## 2. Goals

| # | Goal | Type | Target |
|---|------|------|--------|
| G1 | Centralise lead capture from all sources (manual, import, API) into a single system | Business | 100% of leads in one platform |
| G2 | Enforce channel-based data visibility so each user sees only what they should | Compliance | Zero cross-channel data leakage |
| G3 | Reduce duplicate lead outreach by enforcing deduplication per product | Operational | < 2% duplicate contact rate |
| G4 | Track the full journey from lead → proposal → policy with clear status at each stage | Business | 100% traceability end-to-end |
| G5 | Generate a unique Customer ID on first policy and surface a 360° customer view | Customer | Customer 360 live for all policy holders |
| G6 | Enable digital engagement via WhatsApp and surface customer cases on the 360 page | CX | WhatsApp case creation in < 5 min |

---

## 3. Non-Goals

| # | Out of Scope | Rationale |
|---|---|---|
| NG1 | Actual premium calculation engine | Requires actuarial models; separate system integration |
| NG2 | Claims management module | Distinct workflow owned by operations; future phase |
| NG3 | Real WhatsApp Business API account setup | Dummy/sandbox integration for v1; production setup is an ops task |
| NG4 | Third-party credit/KYC checks | Regulatory dependency; to be handled outside Salesforce |
| NG5 | Mobile native app | Web-based Salesforce Lightning only in v1 |

---

## 4. User Roles & Permissions

### Role Matrix

| Role | Scope | Channel Access | Lead Visibility |
|------|-------|---------------|-----------------|
| **FLS** (Field Sales) | Own leads only | Single channel | Self |
| **Manager** | Own + direct FLS leads | Single channel | Self + reporting FLS |
| **Trainer** | FLS assigned to their branch | Single channel | Branch-assigned FLS (no hierarchy dependency) |
| **Sales Co-ordinator** | All users in their channel | Single channel | All FLS + Managers in channel |
| **Admin** | All channels, all users | All channels | Full access |

### Visibility Rules Detail

- **FLS → Manager**: Standard Salesforce Role Hierarchy (Manager above FLS in hierarchy).
- **Trainer → FLS**: NOT role hierarchy. Trainer is mapped to a Branch. Any FLS tagged to the same Branch is visible to the Trainer regardless of reporting line.
  - Example: FLS 1 & FLS 2 → Manager 1 → Delhi Branch. Trainer 1 → Delhi Branch. Trainer 1 sees FLS 1 & FLS 2's leads without being in their reporting chain.
- **Sales Co-ordinator**: Sees full channel view via a custom sharing rule (not hierarchy).
- **Admin**: System-wide view via profile-level bypass.

### Channels
- Agency
- BANCA
- Direct

Each channel has its own set of FLS, Managers, Trainers, and Sales Co-ordinators. Users do not cross channels.

---

## 5. System Architecture Overview

```
Lead Sources
├── Manual Entry (Salesforce UI)
├── Bulk Import (CSV / Excel via Data Import Wizard or custom UI)
└── API Integration (Dummy Web Form → REST API → Salesforce Lead Object)

                    ↓

        [Lead Object — with Deduplication]
                    ↓
        [Activity Management]
        (Face-to-Face / Phone Call / WhatsApp)
                    ↓
        [Proposal / Opportunity Object]
        (DDE Form + BI Illustrations)
                    ↓
        [Payment Gateway Trigger]
                    ↓
        [Policy Object]
        (First Policy → Customer ID generated)
                    ↓
        [Customer 360 View]
        (All Leads + Proposals + Policies + Cases)

Side Channels:
└── WhatsApp (Open API) → Cases → Customer 360
```

---

## 6. User Stories

### FLS (Field Sales)

- As an FLS, I want to create a new lead manually so that I can start tracking a prospect I met in the field.
- As an FLS, I want to log a phone call or face-to-face visit against a lead so that my manager can see the activity history.
- As an FLS, I want to only see my own leads so that my view is uncluttered and focused.
- As an FLS, I want to convert an interested lead into a proposal so that I can initiate the onboarding journey.

### Manager

- As a Manager, I want to see all leads created by my FLS as well as my own so that I can coach and track team performance.
- As a Manager, I want to filter leads by status and activity date so that I can identify at-risk or stale leads.
- As a Manager, I want to see the lead-to-proposal and proposal-to-policy conversion rates for my team.

### Trainer

- As a Trainer, I want to view leads of all FLS assigned to my branch so that I can provide coaching without needing to be in the reporting hierarchy.
- As a Trainer, I want to filter leads by activity type so that I can identify which FLS need skill support.

### Sales Co-ordinator

- As a Sales Co-ordinator, I want to see all leads across my channel so that I can manage distribution and follow escalations.
- As a Sales Co-ordinator, I want to import leads in bulk via a CSV so that campaigns can be onboarded quickly.
- As a Sales Co-ordinator, I want to assign leads to specific FLS so that distribution is managed centrally.

### Admin

- As an Admin, I want to view leads, proposals, and policies across all channels so that I have full operational oversight.
- As an Admin, I want to configure channel membership and branch-trainer mappings so that visibility rules work correctly.
- As an Admin, I want to manage deduplication rules so that the same customer is not contacted twice for the same product.

### Customer (via WhatsApp)

- As a Customer, I want to submit a query via WhatsApp so that I can get support without calling.
- As a Customer, I want my query to appear against my 360 profile so that the sales team has context when they respond.

---

## 7. Functional Requirements

### P0 — Must Have

#### Lead Management
- [ ] Lead creation via manual entry with fields: Name, Full Name, Mobile, Email, Source, Channel, Product, Branch, Assigned FLS
- [ ] Lead creation via bulk CSV import with field mapping UI
- [ ] Lead creation via REST API (dummy form integration)
- [ ] Deduplication engine (see Section 8)
- [ ] Lead status lifecycle: New → Contacted → Interested → Converted / Not Interested / Junk
- [ ] Activity logging: Face-to-Face Visit, Phone Call (with date, notes, outcome)
- [ ] Channel-based data isolation (Agency / BANCA / Direct)
- [ ] Role-based visibility: FLS, Manager, Trainer (branch-based), Sales Co-ordinator, Admin

#### Proposal (Opportunity)
- [ ] Convert Lead → Proposal when status = Interested
- [ ] Proposal triggers DDE (Data Entry) form to capture complete customer details
- [ ] BI (Benefit Illustration) samples displayed per product at proposal stage
- [ ] Product selection by customer → Payment trigger
- [ ] Proposal status: Draft → Under Review → Payment Pending → Policy Issued

#### Document Management
- [ ] Document upload via Salesforce Files on Lead, Proposal, and Policy records
- [ ] Supported types: KYC docs (Aadhaar, PAN, passport), signed proposals, payment receipts
- [ ] Documents linked to Customer 360 view under respective record
- [ ] File size limit enforcement and type validation (PDF, JPG, PNG)

#### Policy
- [ ] Policy object created on successful payment
- [ ] On first-ever policy for a customer → generate unique Customer ID
- [ ] Customer ID stored on both Policy and Contact/Account record
- [ ] Policy details: Policy Number, Product, Premium, Start Date, Status

#### Permissions & Security
- [ ] Profile and Permission Set setup per role per channel
- [ ] Sharing Rules for Trainer (branch-based) and Sales Co-ordinator (channel-wide)
- [ ] OWD (Org-Wide Defaults): Private for Leads, controlled sharing via rules

---

### P1 — Nice to Have

- [ ] WhatsApp integration via Open API (see Section 11)
- [ ] Customer 360 page showing Leads + Proposals + Policies + Cases
- [ ] Case module for customer queries received via WhatsApp
- [ ] Email notifications on lead assignment
- [ ] Dashboard for Manager: team conversion funnel
- [ ] Lead age tracking (flagging leads not contacted in X days)
- [ ] Re-assignment workflow (Sales Co-ordinator reassigns stale leads)

---

### P2 — Future Considerations

- [ ] Mobile app (Salesforce Mobile or custom LWC)
- [ ] Real-time WhatsApp chatbot for customer self-service
- [ ] Claims module
- [ ] Integration with external policy admin system

---

## 8. Deduplication Logic

A lead is considered a **duplicate** when the same customer exists in the system **for the same product**. The same customer CAN have multiple lead records for different products.

### Deduplication Key
```
Duplicate = Same (Mobile Number OR Email) + Same Product
```

### Rules
1. On lead creation (manual/import/API), check existing Lead and Contact records for matching Mobile or Email.
2. If a match is found for the **same product** → block creation, surface a warning: *"A lead for [Customer Name] for [Product] already exists. Assigned to [FLS Name]."*
3. If a match is found for a **different product** → allow creation, link to same Contact, flag as cross-sell opportunity.
4. Duplicate matching should be case-insensitive and strip formatting from mobile numbers (spaces, +91, dashes).

### Implementation Note (Salesforce)
- Use **Duplicate Rules + Matching Rules** on the Lead object.
- Custom Matching Rule: `MobilePhone + Product__c` (custom field).
- Alert mode (not block) for cross-product duplicates; Block mode for same-product duplicates.

---

## 9. Lead Lifecycle

```
[New Lead Created]
       ↓
[Contacted] ← Activity logged (Call / F2F)
       ↓
[Interested] ← Customer expresses interest
       ↓
[Proposal Generated] ← DDE Form + BI shown
       ↓
[Product Selected] ← Customer selects plan
       ↓
[Payment Made]
       ↓
[Policy Issued] ← Policy record created
       ↓
[Customer ID Generated] ← (First policy only)

Alt paths:
[Contacted] → [Not Interested] → Closed (no further action)
[Contacted] → [Junk] → Closed (invalid lead)
```

---

## 10. Channel Structure

Each channel (Agency, BANCA, Direct) is independent with its own:
- User base (FLS, Manager, Trainer, Sales Co-ordinator)
- Lead pool
- Reporting hierarchy

### Branch-Trainer Mapping
A custom object `Branch_Trainer_Mapping__c` links:
- `Branch__c` (lookup to Branch object)
- `Trainer__c` (lookup to User)

Sharing logic: Any FLS whose `Branch__c` matches the Trainer's mapped branches will have their Lead records shared with that Trainer via a custom Apex Sharing or Criteria-Based Sharing Rule.

---

## 11. AI Scoring & Intelligence

Salesforce's native AI capabilities (Einstein) combined with custom scoring models will be used to surface actionable intelligence on every Lead and Customer record. Scores are calculated automatically and displayed on the Lead detail page and Customer 360.

### 11.1 Scoring Models

| Score | Definition | Range | Basis |
|-------|-----------|-------|-------|
| **Lead Score** | Overall quality of the lead based on completeness, source, and engagement | 0–100 | Fields filled, source channel, activity count |
| **Propensity Score** | Likelihood that this lead will convert to a Proposal | 0–100 | Historical conversion patterns per channel/product |
| **Likely to Buy Score** | Probability that a Proposal will result in a Policy | 0–100 | Product affinity, income band, interaction history |
| **Engagement Score** | Activity intensity: call frequency, response rate | 0–100 | Activity logs, response times |
| **Churn Risk Score** | For existing policy holders — likelihood of not renewing | 0–100 | Policy age, complaint history, interaction recency |

### 11.2 Implementation Approach

#### Phase 1 (Rule-Based Scoring — available immediately)
Before Einstein models have enough training data, scores are computed via Apex using deterministic rules:

```
Lead Score Factors:
  + Email present              → +10
  + Mobile present             → +10
  + Source = Referral          → +20
  + Source = API/Web           → +10
  + Activity logged (Call)     → +15 per call (max 2)
  + Activity logged (F2F)      → +20 per visit (max 2)
  + Product field filled       → +10
  + Response within 24h        → +5

Propensity Score Factors (historical channel averages):
  Agency leads → base 45
  BANCA leads  → base 60
  Direct leads → base 35
  Adjusted by product category, lead age, and FLS activity rate
```

#### Phase 2 (Einstein AI — after sufficient data volume)
Once ≥ 500 converted leads exist per channel, enable:
- **Einstein Lead Scoring** (native Salesforce feature) — ML model trained on historical Lead → Proposal conversions
- **Einstein Opportunity Scoring** — on Proposals, predicts likelihood of converting to Policy
- **Einstein Activity Capture** — auto-log emails and meetings against leads

#### Phase 3 (Custom AI Models)
- Train custom propensity models per product category using Data Cloud + Einstein Studio
- Likely to Buy model: uses demographic data, product preference, and payment history
- Churn Risk model: applied to Policy holders at renewal time

### 11.3 Score Display

Scores appear as:
- **On Lead record**: Score badges in a custom LWC "AI Insights" panel (top-right of page layout)
- **On Customer 360**: Aggregated AI summary card showing current Lead Score, Propensity, and Engagement
- **On Manager Dashboard**: Ranked list of FLS leads sorted by Propensity Score (highest first)

### 11.4 Score-Triggered Automations

| Trigger | Action |
|---------|--------|
| Lead Score drops below 30 after 7 days | Flag as "At Risk" — alert FLS and Manager |
| Propensity Score > 75 | Auto-tag lead as "Hot" — push notification to FLS |
| Likely to Buy > 80 on Proposal | Escalate to Manager for priority follow-up |
| Churn Risk > 70 on Policy | Create a retention Case; assign to Sales Co-ordinator |
| Engagement Score = 0 for 14 days | Trigger re-assignment workflow |

### 11.5 Salesforce AI Features Used

| Feature | Purpose |
|---------|---------|
| Einstein Lead Scoring | Native ML-based lead quality scoring |
| Einstein Opportunity Scoring | Proposal-to-Policy conversion prediction |
| Einstein Activity Capture | Auto-log emails and calendar events |
| Flow + Apex | Rule-based scoring for Phase 1 |
| Data Cloud (future) | Unified customer data for advanced model training |
| Einstein Studio (future) | Custom model training and deployment |

---

## 12. WhatsApp Integration

> **Note:** For v1, this will use a dummy/sandbox WhatsApp Open API endpoint. Production WhatsApp Business API setup is out of scope.

### Flow
1. Customer sends a WhatsApp message to the business number.
2. Message received via Open API webhook → Salesforce REST API endpoint.
3. A **Case** record is created in Salesforce, linked to the customer's Contact (matched by mobile number).
4. Case appears on the Customer 360 page under "Cases / Queries".
5. FLS / Sales Co-ordinator can respond from Salesforce (via Case feed or manual WhatsApp reply link).

### Data Captured in Case
- Customer Mobile (used to link to Contact)
- Message content
- Timestamp
- Status: Open / In Progress / Resolved

---

## 13. Customer 360

The Customer 360 is a unified view on the **Contact** record (or a custom Lightning Page) that aggregates:

| Section | Data Shown |
|---------|-----------|
| **Profile** | Name, Mobile, Email, Customer ID, Date of First Policy |
| **Leads** | All lead records linked to this customer (any product, any status) |
| **Proposals** | All proposals generated (status, product, date) |
| **Policies** | All active policies (Policy Number, Product, Premium, Start Date) |
| **Cases / Queries** | All WhatsApp-sourced cases (message summary, date, status) |
| **Activities** | All F2F / call logs across all leads |

### Implementation
- Built as a **Lightning Record Page** with custom LWC components per section.
- Each component queries related records via SOQL.
- Customer ID (`Customer_ID__c`) is the linking key across objects.

---

## 14. Success Metrics

### Leading Indicators (First 30 Days Post-Launch)
| Metric | Target |
|--------|--------|
| % of leads created via system (vs. spreadsheets) | > 80% |
| Duplicate lead rate (same customer, same product) | < 2% |
| Activity log rate (% of leads with at least 1 activity) | > 70% |
| Lead-to-Proposal conversion | Baseline measurement |

### Lagging Indicators (60–90 Days)
| Metric | Target |
|--------|--------|
| Lead-to-Policy conversion rate | Baseline + 10% improvement |
| Average days from lead creation to policy issuance | Reduce by 15% |
| WhatsApp case resolution time | < 24 hours |
| Customer 360 page adoption (% of FLS using it) | > 60% |

---

## 15. Open Questions

| # | Question | Owner | Blocking? |
|---|----------|-------|-----------|
| OQ1 | What is the exact list of products across channels? (For deduplication key and BI illustrations) | Business / Admin | Yes |
| OQ2 | What payment gateway will be used for the payment trigger? Or is it a manual status update? | Engineering | Yes |
| OQ3 | Which WhatsApp Open API provider is being used? (e.g., Twilio, Meta direct, WATI) | Engineering | For WhatsApp phase |
| OQ4 | Should Trainer visibility be restricted to read-only, or can Trainers log activities too? | Business | No |
| OQ5 | Is "Branch" a Salesforce custom object or a picklist field on the User record? | Admin | Yes |
| OQ6 | What fields are part of the DDE form for customer onboarding? | Business | For Proposal phase |
| OQ7 | Should the Customer ID be auto-generated (sequential) or follow a specific format? | Business | No |
| OQ8 | Can a lead exist in multiple channels simultaneously? | Business | Yes |

---

## 16. Phasing & Timeline

### Phase 1 — Core Lead Management (Salesforce Foundation)
**Scope:**
- Salesforce project setup (this repo)
- Lead object + custom fields (incl. `Full_Name__c`, `Product__c`, `Channel__c`, `Branch__c`)
- Deduplication rules (Matching Rules + Duplicate Rules)
- Role hierarchy + profiles + sharing rules (FLS, Manager, Trainer, Sales Co-ordinator, Admin)
- Manual lead creation + bulk import
- Activity object (Face-to-Face, Phone Call)
- Document upload via Salesforce Files (KYC docs, signed proposals)
- **AI Rule-Based Scoring** (Lead Score, Propensity Score via Apex + Flow)

**Approach:** Planned with **Claude Opus**, implemented with **Claude Sonnet** on Salesforce org.

---

### Phase 2 — API Integration + Proposal Journey
**Scope:**
- REST API endpoint (Salesforce Connected App)
- Dummy web form (HTML page) that POSTs to Salesforce API
- Lead → Proposal conversion
- DDE form (custom LWC)
- BI illustration display (static samples per product)
- Payment status field (manual trigger for v1)
- Policy object creation

---

### Phase 3 — Customer 360 + WhatsApp + Einstein AI
**Scope:**
- Customer ID generation on first policy
- Customer 360 Lightning Page (custom LWC components)
- WhatsApp Open API webhook integration (dummy)
- Case object creation from WhatsApp messages
- Cases on 360 page
- **Einstein Lead Scoring** (if data volume ≥ 500 converted leads)
- **Einstein Opportunity Scoring** on Proposals
- Score-triggered automations (Hot lead alerts, At Risk flags, re-assignment)

---

### Phase 4 — Dashboards, Reports & Enhancements
**Scope:**
- Manager dashboards (funnel, conversion rates)
- Lead age alerts
- Re-assignment workflow
- Performance reports per channel

---

## 17. Technical Notes

### Salesforce Metadata Structure (This Repo)
```
force-app/
└── main/
    └── default/
        ├── objects/
        │   ├── Lead/
        │   │   └── fields/
        │   │       └── Full_Name__c.field-meta.xml   ✅ Created
        │   ├── Opportunity/          (Proposal)
        │   ├── Policy__c/            (Custom Object - Phase 2)
        │   └── Case/                 (Phase 3)
        ├── classes/                  (Apex - Phase 2+)
        ├── lwc/                      (Lightning Web Components - Phase 3)
        ├── permissionsets/           (Phase 1)
        └── sharingRules/             (Phase 1)
manifest/
└── package.xml                       ✅ Updated
```

### Dev Workflow
- **Planning:** Claude Opus (architecture, data model, rules design)
- **Implementation:** Claude Sonnet (metadata XML, Apex, LWC generation)
- **Deployment:** VS Code Salesforce Extension Pack → `sf project deploy start`
- **Version Control:** GitHub (this repo)
- **Portfolio:** PRD hosted on personal portfolio site as project documentation

### API Version
Salesforce API: **67.0** (Summer '25)

---

*This PRD is a living document and will be updated at the start of each phase.*
