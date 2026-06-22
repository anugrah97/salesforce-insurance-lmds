# User Stories
**Project:** Insurance Lead Management & Distribution System  
**Platform:** Salesforce  
**Author:** Anugrah Pandya  
**Version:** 1.0  
**Last Updated:** June 2026  
**Repo:** [anugrah97/salesforce-insurance-lmds](https://github.com/anugrah97/salesforce-insurance-lmds)

---

## Story Format

Each story follows:
- **ID** — unique reference (used in RTM and Test Cases)
- **Persona** — who the story belongs to
- **Story** — As a [persona], I want [capability] so that [benefit]
- **Priority** — P0 / P1 / P2
- **Acceptance Criteria** — Given/When/Then or checklist
- **Dependencies** — other stories or REQs that must be done first
- **Phase** — delivery phase

---

## Persona: FLS (Field Sales)

### US-001 — Create a Lead Manually
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-001

> As an FLS, I want to create a new lead manually so that I can track a prospect I met in the field.

**Acceptance Criteria:**
- [ ] FLS can access the New Lead form from the Salesforce navigation bar
- [ ] Required fields: First Name, Last Name, Mobile, Channel, Product, Source, Branch
- [ ] Optional fields: Email, Full Name (custom), Address, Notes
- [ ] On save, Lead is assigned to the logged-in FLS automatically
- [ ] Lead Status defaults to "New"
- [ ] FLS cannot select a Channel other than their own
- [ ] Success message shown on creation

**Dependencies:** REQ-016 (profiles set up), REQ-009 (channel isolation)

---

### US-002 — View My Own Leads
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-001, REQ-011

> As an FLS, I want to see only my own leads so that my view is focused and uncluttered.

**Acceptance Criteria:**
- [ ] FLS list view shows only leads where Assigned FLS = current user
- [ ] FLS cannot see leads assigned to other FLS, even in the same branch
- [ ] FLS cannot see leads from other channels
- [ ] Search results respect the same visibility rule

**Dependencies:** REQ-017 (OWD Private), REQ-016 (profiles)

---

### US-003 — Deduplication Warning on Lead Creation
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-004, REQ-005

> As an FLS, I want to be warned when a lead already exists for the same customer and product so that I don't create duplicate outreach.

**Acceptance Criteria:**
- [ ] On lead creation, system checks Mobile + Product combination
- [ ] If duplicate found (same product): block save, show error: *"A lead for [Name] for [Product] already exists, assigned to [FLS Name]."*
- [ ] If same customer, different product: allow save, show info banner: *"This customer has an existing lead for [Other Product]. Marked as cross-sell."*
- [ ] Matching is case-insensitive; mobile numbers normalised (strip +91, spaces, dashes)
- [ ] Duplicate check applies to both Lead and converted Contact records

**Dependencies:** REQ-001

---

### US-004 — Update Lead Status
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-006

> As an FLS, I want to update the status of a lead so that the system reflects where the prospect is in the sales journey.

**Acceptance Criteria:**
- [ ] FLS can update status from: New → Contacted → Interested → Not Interested → Junk
- [ ] Status "Converted" is set automatically on Lead → Proposal conversion, not manually
- [ ] Status change is timestamped and visible in the activity timeline
- [ ] FLS cannot move a lead back to "New" once Contacted

**Dependencies:** US-001

---

### US-005 — Convert Lead to Proposal
**Priority:** P0 | **Phase:** 2 | **REQ:** REQ-020

> As an FLS, I want to convert an interested lead into a proposal so that I can initiate the customer onboarding journey.

**Acceptance Criteria:**
- [ ] Convert button appears on Lead record only when Status = "Interested"
- [ ] Clicking Convert creates a linked Opportunity (Proposal) record
- [ ] Lead Status auto-updates to "Converted"
- [ ] FLS is redirected to the new Proposal record after conversion
- [ ] Lead remains visible (read-only) after conversion; not deleted

**Dependencies:** US-004, REQ-006

---

### US-006 — Log an Activity Against a Lead
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-007, REQ-008

> As an FLS, I want to log a phone call or face-to-face visit against a lead so that all interactions are tracked.

**Acceptance Criteria:**
- [ ] FLS can log activity types: "Phone Call" and "Face-to-Face Visit"
- [ ] Activity form fields: Type, Date, Duration (optional), Outcome, Notes
- [ ] Outcome picklist: Interested / Not Interested / Follow Up Required / No Answer
- [ ] Activity is saved and visible in the lead's activity timeline
- [ ] Lead Score recalculates after activity is logged
- [ ] Activity count is visible on the Lead list view as a column

**Dependencies:** US-001

---

### US-007 — Upload Documents Against a Lead
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-010

> As an FLS, I want to upload documents against a lead so that KYC and other supporting files are stored in one place.

**Acceptance Criteria:**
- [ ] FLS can upload files from the Lead record's Files related list
- [ ] Accepted types: PDF, JPG, PNG
- [ ] Maximum file size: 10 MB per file
- [ ] File is tagged with upload date and uploaded-by user
- [ ] Uploaded files appear in the Customer 360 under the relevant Lead
- [ ] FLS cannot delete files uploaded by others

**Dependencies:** US-001

---

### US-008 — View AI Insights on a Lead
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-031–034

> As an FLS, I want to see AI-generated scores on my leads so that I can prioritise who to contact first.

**Acceptance Criteria:**
- [ ] AI Insights panel visible on Lead detail page (top-right component)
- [ ] Panel shows: Lead Score, Propensity Score, Engagement Score (all 0–100)
- [ ] Scores are colour-coded: Green (>70), Amber (40–70), Red (<40)
- [ ] Scores refresh automatically when activities are logged
- [ ] Tooltip on each score explains what it means
- [ ] "Hot" badge shown if Propensity Score > 75

**Dependencies:** US-006, REQ-031–033

---

## Persona: Manager

### US-021 — View Team Leads
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-012

> As a Manager, I want to see all leads created by my FLS as well as my own so that I can monitor and coach my team.

**Acceptance Criteria:**
- [ ] Manager list view shows own leads + all leads where Assigned FLS reports to the Manager
- [ ] Manager can filter by FLS name within their team
- [ ] Manager can see but NOT edit leads belonging to other Managers
- [ ] Manager cannot see leads from other channels

**Dependencies:** REQ-016 (role hierarchy configured)

---

### US-022-M — Reassign a Lead
**Priority:** P1 | **Phase:** 4 | **REQ:** REQ-054

> As a Manager, I want to reassign a stale lead from one FLS to another so that no lead goes unworked.

**Acceptance Criteria:**
- [ ] Manager can change "Assigned FLS" on any lead within their team
- [ ] On reassignment, previous FLS loses visibility; new FLS gains it
- [ ] Reassignment is logged in the activity timeline with timestamp
- [ ] Both old and new FLS receive an email notification

**Dependencies:** US-021

---

### US-090 — View Conversion Dashboard
**Priority:** P1 | **Phase:** 4 | **REQ:** REQ-052

> As a Manager, I want to see a conversion funnel dashboard for my team so that I can identify bottlenecks.

**Acceptance Criteria:**
- [ ] Dashboard shows: New → Contacted → Interested → Converted rates per FLS
- [ ] Filterable by date range (this week / this month / custom)
- [ ] Sortable by conversion rate (lowest first for coaching focus)
- [ ] Exportable as CSV

**Dependencies:** US-021

---

## Persona: Trainer

### US-022 — View Branch FLS Leads
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-013, REQ-018

> As a Trainer, I want to view leads of all FLS assigned to my branch so that I can provide coaching without needing to be in their reporting hierarchy.

**Acceptance Criteria:**
- [ ] Trainer list view shows leads of all FLS tagged to the Trainer's branch(es)
- [ ] Trainer visibility is NOT dependent on role hierarchy — driven by Branch mapping
- [ ] Trainer can see leads across multiple FLS if mapped to multiple branches
- [ ] Trainer has read-only access — cannot edit lead fields or reassign
- [ ] Trainer can log activities against leads for coaching purposes
- [ ] Trainer cannot see leads from other channels

**Dependencies:** REQ-018 (branch-trainer mapping configured)

---

### US-023-T — Filter Leads by Activity Type
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-013

> As a Trainer, I want to filter leads by activity type so that I can identify which FLS need skill support.

**Acceptance Criteria:**
- [ ] Trainer can filter their branch leads by: No Activity, Call Only, F2F Only, Both
- [ ] Filter shows count of leads per FLS per activity category
- [ ] Results sortable by "Days Since Last Activity"

**Dependencies:** US-022, US-006

---

## Persona: Sales Co-ordinator

### US-023 — View All Channel Leads
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-014, REQ-019

> As a Sales Co-ordinator, I want to see all leads across my channel so that I can manage distribution and escalations.

**Acceptance Criteria:**
- [ ] Sales Co-ordinator sees all leads within their channel regardless of FLS assignment
- [ ] Can filter by: Status, FLS, Branch, Product, Source, Date Created
- [ ] Cannot see leads from other channels
- [ ] Can export filtered list as CSV

**Dependencies:** REQ-019 (sharing rules configured)

---

### US-010 — Bulk Import Leads via CSV
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-002

> As a Sales Co-ordinator, I want to import leads in bulk via a CSV so that campaign leads can be onboarded quickly.

**Acceptance Criteria:**
- [ ] Import UI accessible from the Leads tab
- [ ] CSV template downloadable from the import screen
- [ ] Required columns: First Name, Last Name, Mobile, Product, Source, Channel, Branch
- [ ] System validates all rows before committing: shows error report for invalid rows
- [ ] Deduplication check runs on each imported row
- [ ] Successful rows are imported; failed rows are skipped with error log
- [ ] Import summary shown: X imported, Y failed, Z duplicates blocked
- [ ] Imported leads are assigned to the Co-ordinator for distribution

**Dependencies:** REQ-004 (deduplication rules)

---

### US-011-SC — Assign Leads to FLS
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-001

> As a Sales Co-ordinator, I want to assign imported or unassigned leads to specific FLS so that distribution is managed centrally.

**Acceptance Criteria:**
- [ ] Co-ordinator can update "Assigned FLS" on any lead in their channel
- [ ] FLS lookup is filtered to show only FLS within the same channel
- [ ] Bulk assignment supported: select multiple leads → assign to one FLS
- [ ] FLS receives email notification on assignment

**Dependencies:** US-010, US-023

---

## Persona: Admin

### US-024 — Full System Access
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-015

> As an Admin, I want full visibility across all channels, all leads, proposals, policies, and users so that I have complete operational oversight.

**Acceptance Criteria:**
- [ ] Admin can view all records across Agency, BANCA, and Direct channels
- [ ] Admin can create, edit, and delete any record
- [ ] Admin can access all reports and dashboards across channels
- [ ] Admin cannot be restricted by OWD or sharing rules

**Dependencies:** REQ-016 (System Admin profile)

---

### US-025 — Configure Branch-Trainer Mapping
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-013, REQ-018

> As an Admin, I want to configure which Trainers are mapped to which branches so that Trainer visibility rules work correctly.

**Acceptance Criteria:**
- [ ] Admin can create Branch_Trainer_Mapping__c records
- [ ] Each mapping links one Trainer (User) to one Branch
- [ ] A Trainer can be mapped to multiple branches
- [ ] On mapping save, sharing recalculation triggers automatically
- [ ] Admin can deactivate a mapping without deleting it

**Dependencies:** Branch__c custom object exists

---

### US-026 — Manage Deduplication Rules
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-004, REQ-005

> As an Admin, I want to manage deduplication rules so that the same customer is not contacted twice for the same product.

**Acceptance Criteria:**
- [ ] Admin can view and edit the Matching Rule (Mobile + Product) in Setup
- [ ] Admin can toggle Duplicate Rule between Alert and Block mode per scenario
- [ ] Admin can view a deduplication log showing blocked entries

**Dependencies:** None

---

## Persona: API / System

### US-011 — Submit Lead via API (Dummy Web Form)
**Priority:** P0 | **Phase:** 2 | **REQ:** REQ-003

> As an external web form, I want to POST lead data to Salesforce via a REST API so that leads from partner websites are captured automatically.

**Acceptance Criteria:**
- [ ] Salesforce exposes a REST endpoint: `POST /services/apexrest/v1/leads`
- [ ] Payload fields: firstName, lastName, mobile, email, product, source, channel
- [ ] Endpoint returns: `{ success: true, leadId: "00Q..." }` on success
- [ ] Endpoint returns: `{ success: false, error: "Duplicate lead for product X" }` on duplicate
- [ ] Deduplication runs on API-submitted leads same as manual
- [ ] API calls authenticated via Connected App (OAuth 2.0 client credentials)
- [ ] Dummy web form (HTML page) available in `/api-demo/` folder of this repo

**Dependencies:** REQ-004, Connected App configured

---

## Persona: Customer (via WhatsApp)

### US-070 — Submit Query via WhatsApp
**Priority:** P1 | **Phase:** 3 | **REQ:** REQ-041, REQ-042

> As a Customer, I want to send a WhatsApp message to the insurance business number so that I can get support without calling.

**Acceptance Criteria:**
- [ ] Customer sends message to registered WhatsApp number
- [ ] Message is received by Salesforce via webhook within 60 seconds
- [ ] A Case record is created with: Subject = first 50 chars of message, Status = Open
- [ ] Case is linked to Contact record matched by mobile number
- [ ] If no Contact match found, Case is created as an orphan with mobile stored

**Dependencies:** REQ-041 (webhook configured)

---

### US-071 — Case Linked to Customer Profile
**Priority:** P1 | **Phase:** 3 | **REQ:** REQ-043

> As a Sales Co-ordinator, I want WhatsApp cases to automatically link to the customer's contact record so that context is available when responding.

**Acceptance Criteria:**
- [ ] On Case creation, system looks up Contact by mobile number
- [ ] If matched: Case Account/Contact lookup fields populated automatically
- [ ] If unmatched: Case flagged as "Unlinked" for manual resolution
- [ ] Match is normalised (strip +91, spaces)

**Dependencies:** US-070

---

### US-072 — Manage Case Status
**Priority:** P1 | **Phase:** 3 | **REQ:** REQ-044

> As a Sales Co-ordinator, I want to update the status of WhatsApp cases so that resolution is tracked.

**Acceptance Criteria:**
- [ ] Case status picklist: Open → In Progress → Resolved
- [ ] Status change is timestamped
- [ ] Resolved cases show resolution notes (required field on close)
- [ ] SLA warning shown if case is Open for > 24 hours

**Dependencies:** US-070

---

## Persona: FLS / Manager (Customer 360)

### US-080 — View Customer 360
**Priority:** P1 | **Phase:** 3 | **REQ:** REQ-045–050

> As an FLS or Manager, I want to see a unified 360° view of a customer so that I have full context before any interaction.

**Acceptance Criteria:**
- [ ] 360 page accessible from Contact record
- [ ] Sections: Profile, Leads, Proposals, Policies, Cases, Activities
- [ ] Each section shows records the user has access to (visibility rules apply)
- [ ] Leads section shows: Status, Product, Assigned FLS, Created Date
- [ ] Proposals section shows: Status, Product, Created Date
- [ ] Policies section shows: Policy Number, Product, Premium, Start Date, Status
- [ ] Cases section shows: Subject, Status, Created Date
- [ ] Activities section shows all logged interactions across all leads

**Dependencies:** Customer ID generated (REQ-028), all related objects exist

---

### US-081 — AI Score Summary on Customer 360
**Priority:** P1 | **Phase:** 3 | **REQ:** REQ-051

> As an FLS, I want to see the AI score summary on the Customer 360 page so that I can assess the customer's potential at a glance.

**Acceptance Criteria:**
- [ ] AI summary card shown at top of 360 page
- [ ] Shows: highest current Lead Score, Propensity Score, Churn Risk (if policy holder)
- [ ] Colour-coded badges (Green / Amber / Red)
- [ ] "View Details" link navigates to the most recent Lead's AI Insights panel

**Dependencies:** US-080, REQ-031–034

---

## Persona: Manager (AI)

### US-060 — AI Scores Visible on Lead List View
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-031–034

> As a Manager, I want to see AI scores on the Lead list view so that I can quickly identify which leads my FLS should prioritise.

**Acceptance Criteria:**
- [ ] Lead Score and Propensity Score visible as columns on Manager list view
- [ ] List view sortable by Lead Score (highest first)
- [ ] "Hot" tag shown on list view for leads with Propensity Score > 75

**Dependencies:** REQ-031, REQ-032

---

### US-061 — AI Insights Panel on Lead Record
**Priority:** P0 | **Phase:** 1 | **REQ:** REQ-034

> As an FLS or Manager, I want an AI Insights panel on the Lead detail page so that scores are visible without leaving the record.

**Acceptance Criteria:**
- [ ] LWC panel renders in the right sidebar of the Lead page layout
- [ ] Shows: Lead Score, Propensity Score, Engagement Score with colour badges
- [ ] Last updated timestamp shown
- [ ] Recalculates on page load if last score is > 1 hour old

**Dependencies:** REQ-031, REQ-032, REQ-033

---

### US-062 — Score-Triggered Alerts
**Priority:** P1 | **Phase:** 1 | **REQ:** REQ-035

> As an FLS, I want to receive an alert when a lead becomes "Hot" so that I can follow up immediately.

**Acceptance Criteria:**
- [ ] Salesforce notification sent to assigned FLS when Propensity Score crosses 75
- [ ] Manager also notified for team leads crossing 75
- [ ] Lead tagged "Hot" on list view and record header
- [ ] "At Risk" tag applied when Lead Score drops below 30 after 7 days with no activity
- [ ] At Risk leads trigger email to FLS and Manager

**Dependencies:** US-060, REQ-033

---

*This document is maintained alongside RTM.md and TEST-CASES.md.*
