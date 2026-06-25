/**
 * LeadScoringEngine
 * Queueable Apex that calculates Lead Score, Propensity Score, and Engagement Score
 * for a batch of leads. Triggered from LeadActivityAfter trigger and LeadScoreScheduler.
 *
 * Scoring Rules (Phase 1 — Rule-Based):
 *
 * LEAD SCORE (0-100):
 *   Email present:           +10
 *   Mobile present:          +10
 *   Product filled:          +10
 *   Source = Referral:       +20
 *   Source = Web/API:        +10
 *   Activity (Phone Call):   +15 per call (max 30)
 *   Activity (F2F Visit):    +20 per visit (max 40)
 *
 * PROPENSITY SCORE (0-100):
 *   Channel base: Agency=45, BANCA=60, Direct=35
 *   Activity Count > 2:      +10
 *   Lead Score > 60:         +15
 *   Source = Referral:       +10
 *   Lead Age > 30 days:      -10
 *
 * ENGAGEMENT SCORE (0-100):
 *   0 activities:    0
 *   1 activity:      25
 *   2 activities:    50
 *   3+ activities:   75
 *   F2F in last 7d:  +25 (cap at 100)
 */
public with sharing class LeadScoringEngine implements Queueable {

    private Set<Id> leadIds;

    public LeadScoringEngine(Set<Id> leadIds) {
        this.leadIds = leadIds;
    }

    /**
     * Entry point from triggers — enqueues scoring job.
     */
    public static void enqueueScoring(Set<Id> leadIds) {
        if (!leadIds.isEmpty()) {
            System.enqueueJob(new LeadScoringEngine(leadIds));
        }
    }

    public void execute(QueueableContext ctx) {
        List<Lead> leads = [
            SELECT Id, Email, MobilePhone, Product__c, Source__c,
                   Channel__c, CreatedDate, Lead_Score__c,
                   Propensity_Score__c, Engagement_Score__c,
                   Score_Tag__c, Activity_Count__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

        // Get all activities for these leads
        Map<Id, List<Lead_Activity__c>> activitiesByLead = getActivities(leadIds);

        List<Lead> toUpdate = new List<Lead>();
        for (Lead l : leads) {
            List<Lead_Activity__c> activities = activitiesByLead.containsKey(l.Id)
                ? activitiesByLead.get(l.Id)
                : new List<Lead_Activity__c>();

            Integer leadScore       = calculateLeadScore(l, activities);
            Integer propensityScore = calculatePropensityScore(l, activities, leadScore);
            Integer engagementScore = calculateEngagementScore(activities);
            String  scoreTag        = deriveTag(leadScore, propensityScore, l.CreatedDate, activities);

            l.Lead_Score__c        = leadScore;
            l.Propensity_Score__c  = propensityScore;
            l.Engagement_Score__c  = engagementScore;
            l.Score_Tag__c         = scoreTag;
            l.Activity_Count__c    = activities.size();
            l.Last_Score_Updated__c = DateTime.now();
            toUpdate.add(l);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // ─── Score Calculators ───────────────────────────────────────────────────

    @TestVisible
    static Integer calculateLeadScore(Lead l, List<Lead_Activity__c> activities) {
        Integer score = 0;

        if (String.isNotBlank(l.Email))       score += 10;
        if (String.isNotBlank(l.MobilePhone)) score += 10;
        if (String.isNotBlank(l.Product__c))  score += 10;

        if (l.Source__c == 'Referral')               score += 20;
        else if (l.Source__c == 'Web' || l.Source__c == 'API') score += 10;

        Integer callScore = 0;
        Integer f2fScore  = 0;
        for (Lead_Activity__c a : activities) {
            if (a.Activity_Type__c == 'Phone Call')        callScore = Math.min(callScore + 15, 30);
            else if (a.Activity_Type__c == 'Face-to-Face Visit') f2fScore = Math.min(f2fScore + 20, 40);
        }
        score += callScore + f2fScore;

        return Math.min(score, 100);
    }

    @TestVisible
    static Integer calculatePropensityScore(Lead l, List<Lead_Activity__c> activities, Integer leadScore) {
        Integer base = 35; // Default: Direct
        if (l.Channel__c == 'Agency') base = 45;
        else if (l.Channel__c == 'BANCA') base = 60;

        Integer score = base;
        if (activities.size() > 2)   score += 10;
        if (leadScore > 60)          score += 15;
        if (l.Source__c == 'Referral') score += 10;

        // Penalise old leads
        Integer ageDays = l.CreatedDate != null
            ? (Integer) (Date.today().daysBetween(l.CreatedDate.date()) * -1)
            : 0;
        if (ageDays > 30) score -= 10;

        return Math.min(Math.max(score, 0), 100);
    }

    @TestVisible
    static Integer calculateEngagementScore(List<Lead_Activity__c> activities) {
        if (activities.isEmpty()) return 0;

        Integer count = activities.size();
        Integer score = count == 1 ? 25 : count == 2 ? 50 : 75;

        // Bonus for recent F2F
        Date sevenDaysAgo = Date.today().addDays(-7);
        for (Lead_Activity__c a : activities) {
            if (a.Activity_Type__c == 'Face-to-Face Visit'
                && a.Activity_Date__c != null
                && a.Activity_Date__c >= sevenDaysAgo) {
                score = Math.min(score + 25, 100);
                break;
            }
        }
        return score;
    }

    @TestVisible
    static String deriveTag(Integer leadScore, Integer propensityScore, Datetime createdDate, List<Lead_Activity__c> activities) {
        if (propensityScore > 75) return 'Hot';

        // At Risk: low score + no activity in 7 days + lead older than 7 days
        Integer ageDays = createdDate != null
            ? (Integer) (Date.today().daysBetween(createdDate.date()) * -1)
            : 0;
        if (leadScore < 30 && ageDays >= 7 && activities.isEmpty()) return 'At Risk';

        if (leadScore < 30 && ageDays >= 7) {
            Date sevenDaysAgo = Date.today().addDays(-7);
            Boolean recentActivity = false;
            for (Lead_Activity__c a : activities) {
                if (a.Activity_Date__c != null && a.Activity_Date__c >= sevenDaysAgo) {
                    recentActivity = true;
                    break;
                }
            }
            if (!recentActivity) return 'At Risk';
        }

        return 'Normal';
    }

    // ─── Helper ──────────────────────────────────────────────────────────────

    private static Map<Id, List<Lead_Activity__c>> getActivities(Set<Id> leadIds) {
        Map<Id, List<Lead_Activity__c>> result = new Map<Id, List<Lead_Activity__c>>();
        for (Lead_Activity__c a : [
            SELECT Id, Lead__c, Activity_Type__c, Activity_Date__c, Outcome__c
            FROM Lead_Activity__c
            WHERE Lead__c IN :leadIds
            ORDER BY Activity_Date__c DESC
        ]) {
            if (!result.containsKey(a.Lead__c)) {
                result.put(a.Lead__c, new List<Lead_Activity__c>());
            }
            result.get(a.Lead__c).add(a);
        }
        return result;
    }
}
