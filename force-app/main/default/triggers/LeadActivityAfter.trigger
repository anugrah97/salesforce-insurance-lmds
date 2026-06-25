/**
 * LeadActivityAfter
 * After a Lead Activity is inserted or updated, triggers score recalculation
 * and updates the Activity Count on the parent Lead.
 */
trigger LeadActivityAfter on Lead_Activity__c (after insert, after update, after delete) {
    Set<Id> leadIds = new Set<Id>();

    if (Trigger.isDelete) {
        for (Lead_Activity__c a : Trigger.old) {
            if (a.Lead__c != null) leadIds.add(a.Lead__c);
        }
    } else {
        for (Lead_Activity__c a : Trigger.new) {
            if (a.Lead__c != null) leadIds.add(a.Lead__c);
        }
    }

    if (!leadIds.isEmpty()) {
        LeadScoringEngine.enqueueScoring(leadIds);
    }
}
