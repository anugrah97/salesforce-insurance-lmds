# Requirements Traceability Matrix (RTM)
**Project:** Insurance Lead Management & Distribution System  
**Platform:** Salesforce  
**Author:** Anugrah Pandya  
**Version:** 1.0  
**Last Updated:** June 2026  
**Repo:** [anugrah97/salesforce-insurance-lmds](https://github.com/anugrah97/salesforce-insurance-lmds)

---

## How to Read This Document

| Column | Description |
|--------|-------------|
| **REQ-ID** | Requirement ID from PRD |
| **Requirement** | Brief description of the requirement |
| **Priority** | P0 = Must Have, P1 = Nice to Have, P2 = Future |
| **US-ID** | Linked User Story ID(s) from USER-STORIES.md |
| **TC-ID** | Linked Test Case ID(s) from TEST-CASES.md |
| **Phase** | Delivery phase (1–4) |
| **Status** | Not Started / In Progress / Done |

---

## Module 1 — Lead Management

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-001 | Manual lead creation via Salesforce UI | P0 | US-001, US-002 | TC-001, TC-002, TC-003 | 1 | Not Started |
| REQ-002 | Bulk lead import via CSV | P0 | US-010 | TC-010, TC-011, TC-012 | 1 | Not Started |
| REQ-003 | Lead creation via REST API (dummy web form) | P0 | US-011 | TC-013, TC-014, TC-015 | 2 | Not Started |
| REQ-004 | Lead deduplication — same product block | P0 | US-003 | TC-016, TC-017 | 1 | Not Started |
| REQ-005 | Lead deduplication — cross product allow + flag | P0 | US-003 | TC-018, TC-019 | 1 | Not Started |
| REQ-006 | Lead status lifecycle management | P0 | US-004, US-005 | TC-020, TC-021, TC-022 | 1 | Not Started |
| REQ-007 | Activity logging — Face-to-Face Visit | P0 | US-006 | TC-023, TC-024 | 1 | Not Started |
| REQ-008 | Activity logging — Phone Call | P0 | US-006 | TC-025, TC-026 | 1 | Not Started |
| REQ-009 | Channel-based data isolation | P0 | US-030, US-031 | TC-030, TC-031 | 1 | Not Started |
| REQ-010 | Document upload on Lead (KYC, signed docs) | P0 | US-012 | TC-032, TC-033, TC-034 | 1 | Not Started |

---

## Module 2 — Role-Based Access & Visibility

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-011 | FLS sees own leads only | P0 | US-020 | TC-040, TC-041 | 1 | Not Started |
| REQ-012 | Manager sees own + FLS leads | P0 | US-021 | TC-042, TC-043 | 1 | Not Started |
| REQ-013 | Trainer sees leads of branch-assigned FLS | P0 | US-022 | TC-044, TC-045, TC-046 | 1 | Not Started |
| REQ-014 | Sales Co-ordinator sees all leads in channel | P0 | US-023 | TC-047, TC-048 | 1 | Not Started |
| REQ-015 | Admin sees all leads across all channels | P0 | US-024 | TC-049, TC-050 | 1 | Not Started |
| REQ-016 | Profile + Permission Set setup per role | P0 | US-020–024 | TC-051, TC-052 | 1 | Not Started |
| REQ-017 | OWD Private on Lead object | P0 | US-020 | TC-053 | 1 | Not Started |
| REQ-018 | Criteria-based sharing for Trainer (branch) | P0 | US-022 | TC-044, TC-045 | 1 | Not Started |
| REQ-019 | Criteria-based sharing for Sales Co-ordinator | P0 | US-023 | TC-047 | 1 | Not Started |

---

## Module 3 — Proposal & Onboarding

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-020 | Convert Lead → Proposal on Interest | P0 | US-040 | TC-060, TC-061 | 2 | Not Started |
| REQ-021 | DDE Form for complete customer data capture | P0 | US-041 | TC-062, TC-063 | 2 | Not Started |
| REQ-022 | BI Illustration display per product | P0 | US-042 | TC-064 | 2 | Not Started |
| REQ-023 | Product selection by customer | P0 | US-042 | TC-065 | 2 | Not Started |
| REQ-024 | Payment trigger on product selection | P0 | US-043 | TC-066, TC-067 | 2 | Not Started |
| REQ-025 | Proposal status lifecycle | P0 | US-040 | TC-068, TC-069 | 2 | Not Started |
| REQ-026 | Document upload on Proposal | P0 | US-012 | TC-035, TC-036 | 2 | Not Started |

---

## Module 4 — Policy

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-027 | Policy object created on payment | P0 | US-050 | TC-070, TC-071 | 2 | Not Started |
| REQ-028 | Customer ID generated on first policy | P0 | US-051 | TC-072, TC-073, TC-074 | 2 | Not Started |
| REQ-029 | Customer ID stored on Policy + Contact | P0 | US-051 | TC-075 | 2 | Not Started |
| REQ-030 | Document upload on Policy | P0 | US-012 | TC-037 | 2 | Not Started |

---

## Module 5 — AI Scoring

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-031 | Rule-based Lead Score via Apex (Phase 1) | P0 | US-060 | TC-080, TC-081, TC-082 | 1 | Not Started |
| REQ-032 | Rule-based Propensity Score via Apex | P0 | US-060 | TC-083, TC-084 | 1 | Not Started |
| REQ-033 | Engagement Score calculation | P0 | US-060 | TC-085 | 1 | Not Started |
| REQ-034 | AI Insights panel on Lead record (LWC) | P0 | US-061 | TC-086 | 1 | Not Started |
| REQ-035 | Score-triggered automations (Hot/At Risk flags) | P1 | US-062 | TC-087, TC-088 | 1 | Not Started |
| REQ-036 | Einstein Lead Scoring (ML — data threshold) | P1 | US-063 | TC-089 | 3 | Not Started |
| REQ-037 | Einstein Opportunity Scoring on Proposals | P1 | US-063 | TC-090 | 3 | Not Started |
| REQ-038 | Likely to Buy Score (custom model) | P1 | US-064 | TC-091 | 3 | Not Started |
| REQ-039 | Churn Risk Score on Policy holders | P1 | US-065 | TC-092 | 3 | Not Started |
| REQ-040 | AI scores visible on Customer 360 | P1 | US-061 | TC-093 | 3 | Not Started |

---

## Module 6 — WhatsApp Integration

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-041 | WhatsApp webhook receiver (Salesforce endpoint) | P1 | US-070 | TC-100, TC-101 | 3 | Not Started |
| REQ-042 | Case creation from WhatsApp message | P1 | US-070 | TC-102, TC-103 | 3 | Not Started |
| REQ-043 | Case linked to Contact via mobile number | P1 | US-071 | TC-104 | 3 | Not Started |
| REQ-044 | Case status management (Open/In Progress/Resolved) | P1 | US-072 | TC-105, TC-106 | 3 | Not Started |

---

## Module 7 — Customer 360

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-045 | Customer 360 Lightning Page | P1 | US-080 | TC-110, TC-111 | 3 | Not Started |
| REQ-046 | 360 — All Leads section | P1 | US-080 | TC-112 | 3 | Not Started |
| REQ-047 | 360 — All Proposals section | P1 | US-080 | TC-113 | 3 | Not Started |
| REQ-048 | 360 — All Policies section | P1 | US-080 | TC-114 | 3 | Not Started |
| REQ-049 | 360 — WhatsApp Cases section | P1 | US-080 | TC-115 | 3 | Not Started |
| REQ-050 | 360 — Activities timeline | P1 | US-080 | TC-116 | 3 | Not Started |
| REQ-051 | 360 — AI Scores summary card | P1 | US-081 | TC-117 | 3 | Not Started |

---

## Module 8 — Dashboards & Reports

| REQ-ID | Requirement | Priority | US-ID | TC-ID | Phase | Status |
|--------|-------------|----------|-------|-------|-------|--------|
| REQ-052 | Manager dashboard — team conversion funnel | P1 | US-090 | TC-120 | 4 | Not Started |
| REQ-053 | Lead age alert (not contacted in X days) | P1 | US-091 | TC-121 | 4 | Not Started |
| REQ-054 | Re-assignment workflow for stale leads | P1 | US-092 | TC-122 | 4 | Not Started |
| REQ-055 | Channel performance reports | P1 | US-093 | TC-123 | 4 | Not Started |

---

## Coverage Summary

| Phase | Total REQs | P0 | P1 | P2 | Covered by US | Covered by TC |
|-------|-----------|----|----|----|----|-----|
| Phase 1 | 21 | 19 | 2 | 0 | 21 | 21 |
| Phase 2 | 11 | 11 | 0 | 0 | 11 | 11 |
| Phase 3 | 16 | 0 | 16 | 0 | 16 | 16 |
| Phase 4 | 4 | 0 | 4 | 0 | 4 | 4 |
| **Total** | **52** | **30** | **22** | **0** | **52** | **52** |

---

*This document is maintained alongside PRD.md and updated at the start of each phase.*
