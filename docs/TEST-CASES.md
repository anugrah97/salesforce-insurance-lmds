# Test Cases
**Project:** Insurance Lead Management & Distribution System  
**Platform:** Salesforce  
**Author:** Anugrah Pandya  
**Version:** 1.0  
**Last Updated:** June 2026  
**Repo:** [anugrah97/salesforce-insurance-lmds](https://github.com/anugrah97/salesforce-insurance-lmds)

---

## Test Case Format

| Field | Description |
|-------|-------------|
| **TC-ID** | Unique test case ID (used in RTM) |
| **US-ID** | Linked user story |
| **Title** | Short description |
| **Preconditions** | Setup required before test |
| **Steps** | Numbered test steps |
| **Expected Result** | What should happen |
| **Priority** | P0 / P1 |
| **Type** | Functional / Negative / Integration / UAT |

---

## Module 1 — Lead Management

### TC-001 — Create Lead with All Required Fields
**US:** US-001 | **Priority:** P0 | **Type:** Functional

**Preconditions:** FLS user logged in, Channel = Agency

**Steps:**
1. Navigate to Leads tab → click "New"
2. Enter: First Name = "Rahul", Last Name = "Sharma", Mobile = "9876543210"
3. Select Channel = "Agency", Product = "Term Life", Source = "Referral", Branch = "Delhi"
4. Click Save

**Expected Result:** Lead created with Status = "New", Assigned FLS = logged-in user, no errors shown.

---

### TC-002 — Create Lead with Missing Required Field
**US:** US-001 | **Priority:** P0 | **Type:** Negative

**Preconditions:** FLS user logged in

**Steps:**
1. Navigate to New Lead form
2. Enter First Name, Last Name — leave Mobile blank
3. Click Save

**Expected Result:** Validation error: "Mobile is required." Lead not saved.

---

### TC-003 — FLS Cannot Select Another Channel's Leads
**US:** US-001, US-002 | **Priority:** P0 | **Type:** Functional

**Preconditions:** FLS user with Channel = BANCA

**Steps:**
1. Navigate to Leads list view
2. Check if any Agency or Direct leads are visible

**Expected Result:** Zero leads from Agency or Direct channels visible in any list view.

---

### TC-010 — Bulk Import Valid CSV
**US:** US-010 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Sales Co-ordinator logged in, valid CSV with 10 lead rows prepared

**Steps:**
1. Navigate to Leads → Import
2. Upload the valid CSV file
3. Map columns to fields
4. Click Import

**Expected Result:** 10 leads imported successfully. Import summary shows: 10 imported, 0 failed, 0 duplicates.

---

### TC-011 — Bulk Import with Invalid Rows
**US:** US-010 | **Priority:** P0 | **Type:** Negative

**Preconditions:** CSV with 8 valid rows + 2 rows missing Mobile

**Steps:**
1. Upload the mixed CSV
2. Complete field mapping and click Import

**Expected Result:** 8 rows imported. 2 rows failed with error "Mobile is required." Error report downloadable.

---

### TC-012 — Bulk Import Deduplication Check
**US:** US-010, US-003 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead for "9876543210 + Term Life" already exists in system

**Steps:**
1. Import CSV containing a row with Mobile = 9876543210 and Product = Term Life

**Expected Result:** That row is blocked. Import summary: 1 duplicate blocked. Existing lead not modified.

---

### TC-013 — API Lead Creation — Success
**US:** US-011 | **Priority:** P0 | **Type:** Integration

**Preconditions:** Connected App configured, OAuth token obtained, dummy web form running

**Steps:**
1. Submit POST to `/services/apexrest/v1/leads` with valid payload: `{ firstName: "Priya", lastName: "Mehta", mobile: "9123456789", product: "Health", source: "Web", channel: "Direct" }`
2. Check response

**Expected Result:** HTTP 200, response body: `{ success: true, leadId: "00Q..." }`. Lead visible in Salesforce.

---

### TC-014 — API Lead Creation — Missing Field
**US:** US-011 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. POST to `/services/apexrest/v1/leads` with no `mobile` field

**Expected Result:** HTTP 400, response: `{ success: false, error: "mobile is required" }`.

---

### TC-015 — API Lead Creation — Duplicate
**US:** US-011, US-003 | **Priority:** P0 | **Type:** Negative

**Preconditions:** Lead for mobile 9123456789 + Health already exists

**Steps:**
1. POST same payload as TC-013

**Expected Result:** HTTP 200, response: `{ success: false, error: "Duplicate lead for product Health" }`. No new lead created.

---

### TC-016 — Deduplication Block — Same Product
**US:** US-003 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead exists for Mobile = 9876543210 + Product = "Term Life"

**Steps:**
1. FLS attempts to create new lead with Mobile = 9876543210, Product = "Term Life"
2. Click Save

**Expected Result:** Save blocked. Error: "A lead for Rahul Sharma for Term Life already exists, assigned to [FLS Name]."

---

### TC-017 — Deduplication Block — Mobile Normalisation
**US:** US-003 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead exists for Mobile = 9876543210 + Product = "Term Life"

**Steps:**
1. Attempt to create lead with Mobile = "+91 98765 43210" and same Product

**Expected Result:** Duplicate detected and blocked after normalisation. Same error as TC-016.

---

### TC-018 — Deduplication Allow — Different Product
**US:** US-003 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead exists for Mobile = 9876543210 + Product = "Term Life"

**Steps:**
1. Create new lead with same Mobile but Product = "Health Insurance"

**Expected Result:** Lead saved successfully. Info banner: "This customer has an existing lead for Term Life. Marked as cross-sell."

---

### TC-019 — Deduplication — Email-Based Match
**US:** US-003 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead exists for email = rahul@example.com + Product = "Term Life"

**Steps:**
1. Create lead with same email, same product, different mobile

**Expected Result:** Duplicate detected and blocked.

---

### TC-020 — Lead Status Transition: New → Contacted
**US:** US-004 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open a lead with Status = "New"
2. Change Status to "Contacted" and save

**Expected Result:** Status updated. Timestamp recorded in activity timeline.

---

### TC-021 — Lead Status Transition: Contacted → Interested
**US:** US-004 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open lead with Status = "Contacted"
2. Change Status to "Interested" and save

**Expected Result:** Status updated. Convert button becomes visible on the record.

---

### TC-022 — Lead Status Cannot Go Back to New
**US:** US-004 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Open lead with Status = "Contacted"
2. Attempt to change Status back to "New"

**Expected Result:** Validation error: "Status cannot be reverted to New."

---

### TC-023 — Log Face-to-Face Activity
**US:** US-006 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open a Lead record
2. Click "Log Activity" → select "Face-to-Face Visit"
3. Enter Date = today, Outcome = "Interested", Notes = "Met at client office"
4. Save

**Expected Result:** Activity saved. Visible in Lead timeline. Lead Score increases.

---

### TC-024 — Activity Without Outcome Blocked
**US:** US-006 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Log activity without selecting an Outcome
2. Click Save

**Expected Result:** Validation error: "Outcome is required."

---

### TC-025 — Log Phone Call Activity
**US:** US-006 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open Lead, click "Log Activity" → select "Phone Call"
2. Fill all fields, click Save

**Expected Result:** Activity saved in timeline. Engagement Score recalculates.

---

### TC-026 — Multiple Activities on One Lead
**US:** US-006 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Log 2 Phone Calls and 1 F2F on the same lead

**Expected Result:** All 3 activities visible in timeline in chronological order. Activity count = 3 on list view.

---

### TC-032 — Upload Valid Document to Lead
**US:** US-007 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open Lead record → Files section → Upload File
2. Select a valid PDF under 10 MB

**Expected Result:** File uploaded and visible in Files related list with upload date and uploader name.

---

### TC-033 — Upload Invalid File Type
**US:** US-007 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Attempt to upload a .xlsx file to the Lead

**Expected Result:** Error: "File type not allowed. Accepted types: PDF, JPG, PNG."

---

### TC-034 — Upload File Exceeding Size Limit
**US:** US-007 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Attempt to upload a PDF > 10 MB

**Expected Result:** Error: "File size exceeds 10 MB limit."

---

## Module 2 — Role-Based Visibility

### TC-040 — FLS Sees Only Own Leads
**US:** US-002 | **Priority:** P0 | **Type:** Functional

**Preconditions:** FLS-A and FLS-B exist in same channel; each has 5 leads

**Steps:**
1. Log in as FLS-A
2. Open Leads list view

**Expected Result:** Only FLS-A's 5 leads visible. FLS-B's leads not visible.

---

### TC-041 — FLS Cannot Edit Another FLS's Lead (Direct URL)
**US:** US-002 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Log in as FLS-A
2. Navigate directly to a Lead URL belonging to FLS-B

**Expected Result:** "Insufficient Privileges" error or redirect to home page.

---

### TC-042 — Manager Sees Own + FLS Leads
**US:** US-021 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Manager has 2 FLS reporting to them; each FLS has 5 leads; Manager has 3 own leads

**Steps:**
1. Log in as Manager
2. Open Leads list view

**Expected Result:** 13 leads visible (3 own + 5 FLS-A + 5 FLS-B). No leads from other Managers' FLS.

---

### TC-043 — Manager Cannot See Other Manager's FLS Leads
**US:** US-021 | **Priority:** P0 | **Type:** Negative

**Preconditions:** Manager-A and Manager-B exist in same channel with different FLS teams

**Steps:**
1. Log in as Manager-A
2. Check if Manager-B's FLS leads are visible

**Expected Result:** Manager-B's FLS leads not visible.

---

### TC-044 — Trainer Sees Branch FLS Leads
**US:** US-022 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Trainer-1 mapped to Delhi Branch; FLS-1 and FLS-2 are in Delhi Branch; both report to Manager-1 (not Trainer-1)

**Steps:**
1. Log in as Trainer-1
2. Open Leads list view

**Expected Result:** FLS-1 and FLS-2 leads visible. Manager-1's own leads NOT visible.

---

### TC-045 — Trainer Cannot See FLS Outside Their Branch
**US:** US-022 | **Priority:** P0 | **Type:** Negative

**Preconditions:** Trainer-1 mapped to Delhi Branch; FLS-3 is in Mumbai Branch

**Steps:**
1. Log in as Trainer-1 and open list view

**Expected Result:** FLS-3's leads not visible.

---

### TC-046 — Trainer Has Read-Only Access
**US:** US-022 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Log in as Trainer-1
2. Open a lead belonging to FLS-1
3. Attempt to edit a field

**Expected Result:** Fields are read-only. No Edit button visible (or edit blocked on save).

---

### TC-047 — Sales Co-ordinator Sees All Channel Leads
**US:** US-023 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Channel = Agency has 3 FLS with 5 leads each; Co-ordinator is Agency channel

**Steps:**
1. Log in as Sales Co-ordinator
2. Open Leads list view

**Expected Result:** All 15 Agency leads visible regardless of assigned FLS.

---

### TC-048 — Sales Co-ordinator Cannot See Other Channels
**US:** US-023 | **Priority:** P0 | **Type:** Negative

**Steps:**
1. Log in as Agency Co-ordinator
2. Check for BANCA or Direct leads

**Expected Result:** Zero leads from BANCA or Direct visible.

---

### TC-049 — Admin Sees All Leads
**US:** US-024 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Log in as Admin
2. Open Leads list view (All Leads view)

**Expected Result:** All leads across Agency, BANCA, and Direct visible.

---

### TC-050 — Admin Can Edit Any Lead
**US:** US-024 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Log in as Admin
2. Open any lead from any channel and edit a field

**Expected Result:** Edit successful with no permission errors.

---

## Module 3 — AI Scoring

### TC-080 — Lead Score Calculated on Creation
**US:** US-060, US-061 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Create a new lead with Email, Mobile, Product, Source = Referral

**Expected Result:** Lead Score = 50 (10+10+10+20 per scoring rules). AI Insights panel shows score within 30 seconds.

---

### TC-081 — Lead Score Increases After Activity
**US:** US-008 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Note current Lead Score (e.g., 30)
2. Log a Phone Call activity
3. Reload the Lead record

**Expected Result:** Lead Score increases by 15. AI Insights panel shows updated score.

---

### TC-082 — Lead Score Badge Colour
**US:** US-008 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Check Lead Score = 80 (should be Green)
2. Check Lead Score = 55 (should be Amber)
3. Check Lead Score = 25 (should be Red)

**Expected Result:** Correct colour badge shown for each range in AI Insights panel.

---

### TC-083 — Propensity Score — Agency Channel Base
**US:** US-060 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Create a new lead in Agency channel with no activities

**Expected Result:** Propensity Score = 45 (Agency base score per rules).

---

### TC-084 — Hot Tag Applied on Propensity > 75
**US:** US-062 | **Priority:** P1 | **Type:** Functional

**Steps:**
1. Manually set Propensity Score to 76 on a test lead (or trigger via activities)
2. Reload list view

**Expected Result:** "Hot" badge visible on list view. FLS notification sent.

---

### TC-085 — Engagement Score = 0 for New Lead
**US:** US-008 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Create a new lead with no activities

**Expected Result:** Engagement Score = 0 in AI Insights panel.

---

### TC-086 — AI Insights Panel Visible on Lead Page
**US:** US-061 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Open any Lead detail page

**Expected Result:** AI Insights LWC component visible in right sidebar. Shows Lead Score, Propensity Score, Engagement Score.

---

### TC-087 — At Risk Tag After 7 Days No Activity
**US:** US-062 | **Priority:** P1 | **Type:** Functional

**Preconditions:** Scheduled job configured to run daily

**Steps:**
1. Create a lead with Lead Score < 30
2. Leave it with no activity for 7 days (simulate with test data)

**Expected Result:** Lead tagged "At Risk". FLS and Manager notified via email.

---

### TC-088 — Churn Risk Notification on Policy Holder
**US:** US-065 | **Priority:** P1 | **Type:** Functional

**Preconditions:** Customer has active Policy, Churn Risk Score triggers to > 70

**Steps:**
1. Set Churn Risk Score = 75 on a policy holder Contact
2. Check Case and Sales Co-ordinator notification

**Expected Result:** Retention Case created and assigned to Sales Co-ordinator.

---

## Module 4 — Proposal & Policy

### TC-060 — Convert Lead to Proposal
**US:** US-005 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Lead Status = "Interested"

**Steps:**
1. Open Lead record → click "Convert to Proposal"
2. Review pre-filled fields in DDE form
3. Complete all mandatory fields
4. Click Save

**Expected Result:** Proposal (Opportunity) record created. Lead Status = "Converted". User redirected to Proposal record.

---

### TC-061 — Convert Button Hidden When Not Interested
**US:** US-005 | **Priority:** P0 | **Type:** Negative

**Preconditions:** Lead Status = "Contacted"

**Steps:**
1. Open Lead record and look for Convert button

**Expected Result:** Convert button not visible.

---

### TC-070 — Policy Created on Payment
**US:** US-050 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Proposal Status = "Payment Pending"

**Steps:**
1. Update Proposal Status to "Policy Issued" (simulating payment confirmation)
2. Verify Policy record

**Expected Result:** New Policy__c record created, linked to Proposal and Contact.

---

### TC-072 — Customer ID Generated on First Policy
**US:** US-051 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Contact has no existing policies

**Steps:**
1. Create first Policy for a Contact
2. Check Contact record for Customer ID field

**Expected Result:** Customer_ID__c field populated with unique ID (e.g., CUST-00001).

---

### TC-073 — Customer ID NOT Re-generated on Second Policy
**US:** US-051 | **Priority:** P0 | **Type:** Functional

**Preconditions:** Contact already has Customer ID from first policy

**Steps:**
1. Create second policy for the same Contact
2. Check Customer ID

**Expected Result:** Customer ID unchanged from first policy. Not overwritten.

---

### TC-074 — Customer ID Unique Across All Contacts
**US:** US-051 | **Priority:** P0 | **Type:** Functional

**Steps:**
1. Create first policies for Contact-A and Contact-B simultaneously
2. Compare their Customer IDs

**Expected Result:** Customer IDs are different. No collision.

---

## Module 5 — WhatsApp Integration

### TC-100 — Webhook Receives WhatsApp Message
**US:** US-070 | **Priority:** P1 | **Type:** Integration

**Preconditions:** WhatsApp dummy endpoint configured

**Steps:**
1. POST simulated WhatsApp payload to Salesforce webhook endpoint
2. Check Salesforce Cases

**Expected Result:** Case created within 60 seconds of POST.

---

### TC-102 — Case Created from WhatsApp Message
**US:** US-070 | **Priority:** P1 | **Type:** Functional

**Steps:**
1. POST payload with message: "I need help with my policy renewal"
2. Check created Case record

**Expected Result:** Case Subject = "I need help with my policy renewa" (50 chars), Status = Open, Origin = WhatsApp.

---

### TC-104 — Case Linked to Contact by Mobile
**US:** US-071 | **Priority:** P1 | **Type:** Functional

**Preconditions:** Contact exists with Mobile = 9876543210

**Steps:**
1. POST WhatsApp payload with from = "9876543210"
2. Check Case Contact lookup

**Expected Result:** Case Contact field = matched Contact record.

---

## Module 6 — Customer 360

### TC-110 — Customer 360 Page Loads
**US:** US-080 | **Priority:** P1 | **Type:** Functional

**Steps:**
1. Open a Contact record with at least 1 Lead, 1 Policy, and 1 Case
2. Navigate to Customer 360 tab/page

**Expected Result:** All sections load without error. Profile, Leads, Proposals, Policies, Cases all visible.

---

### TC-112 — 360 Leads Section Respects Visibility
**US:** US-080 | **Priority:** P1 | **Type:** Functional

**Preconditions:** FLS-A views Customer 360 for a customer; customer has 2 leads, one assigned to FLS-A and one to FLS-B

**Steps:**
1. Log in as FLS-A, open Customer 360

**Expected Result:** Only FLS-A's lead shown in Leads section. FLS-B's lead not shown.

---

### TC-117 — AI Score Card on 360 Page
**US:** US-081 | **Priority:** P1 | **Type:** Functional

**Steps:**
1. Open Customer 360 for a contact with an active lead
2. Locate AI summary card

**Expected Result:** Card shows highest Lead Score, Propensity Score, and Churn Risk (if policy holder). Correct colours applied.

---

*This document is maintained alongside RTM.md and USER-STORIES.md. All TC-IDs are referenced in RTM.md.*
