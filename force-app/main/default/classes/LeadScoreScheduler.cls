/**
 * LeadScoreScheduler
 * Runs daily to re-evaluate aging leads and apply At Risk tags.
 * Schedule via: System.schedule('Daily Lead Scoring', '0 0 0 * * ?', new LeadScoreScheduler());
 */
public with sharing class LeadScoreScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        // Find all open leads older than 7 days that haven't been scored recently
        Set<Id> leadIds = new Set<Id>();
        for (Lead l : [
            SELECT Id
            FROM Lead
            WHERE IsConverted = false
            AND Status NOT IN ('Converted', 'Not Interested', 'Junk')
            AND (Last_Score_Updated__c = null OR Last_Score_Updated__c < :DateTime.now().addHours(-23))
            LIMIT 200
        ]) {
            leadIds.add(l.Id);
        }

        if (!leadIds.isEmpty()) {
            LeadScoringEngine.enqueueScoring(leadIds);
        }
    }
}
