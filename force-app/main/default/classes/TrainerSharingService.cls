/**
 * TrainerSharingService
 * Manages Apex Sharing for Trainers based on Branch_Trainer_Mapping__c records.
 * Called from BranchTrainerMappingTrigger.
 *
 * Logic:
 *   On mapping INSERT / activate:
 *     1. Resolve Branch__c record names from the mapping's Branch__c lookup
 *     2. Find all Lead records whose Lead.Branch__c (text) matches those branch names
 *     3. Insert LeadShare (Read, Manual) for the Trainer
 *
 *   On mapping DELETE / deactivate:
 *     Delete LeadShare rows for the Trainer where RowCause = Manual
 *
 * Note: Lead.Branch__c is a Text(100) field containing the branch name.
 *       Branch__c is a custom object with a Name field. We join on Name.
 */
public with sharing class TrainerSharingService {

    public static void grantAccess(List<Branch_Trainer_Mapping__c> mappings) {
        // Build a map of Branch__c Id → Trainer User Id for active mappings
        Map<Id, Id> trainerByBranchId = new Map<Id, Id>();
        for (Branch_Trainer_Mapping__c m : mappings) {
            if (m.Is_Active__c) {
                trainerByBranchId.put(m.Branch__c, m.Trainer__c);
            }
        }
        if (trainerByBranchId.isEmpty()) return;

        // Resolve branch names from Branch__c records
        List<Branch__c> branches = [
            SELECT Id, Name FROM Branch__c WHERE Id IN :trainerByBranchId.keySet()
        ];
        // Map: branch name → trainer Id
        Map<String, Id> trainerByBranchName = new Map<String, Id>();
        for (Branch__c b : branches) {
            trainerByBranchName.put(b.Name, trainerByBranchId.get(b.Id));
        }
        if (trainerByBranchName.isEmpty()) return;

        // Find open leads in those branches (Lead.Branch__c is a text field = branch name)
        List<Lead> leads = [
            SELECT Id, Branch__c
            FROM Lead
            WHERE Branch__c IN :trainerByBranchName.keySet()
            AND IsConverted = false
        ];
        if (leads.isEmpty()) return;

        List<LeadShare> shares = new List<LeadShare>();
        for (Lead l : leads) {
            Id trainerId = trainerByBranchName.get(l.Branch__c);
            if (trainerId != null) {
                shares.add(new LeadShare(
                    LeadId          = l.Id,
                    UserOrGroupId   = trainerId,
                    LeadAccessLevel = 'Read',
                    RowCause        = Schema.LeadShare.RowCause.Manual
                ));
            }
        }

        if (!shares.isEmpty()) {
            Database.insert(shares, false); // partial success — skip duplicate shares
        }
    }

    public static void revokeAccess(List<Branch_Trainer_Mapping__c> mappings) {
        Set<Id> trainerIds = new Set<Id>();
        for (Branch_Trainer_Mapping__c m : mappings) {
            if (m.Trainer__c != null) {
                trainerIds.add(m.Trainer__c);
            }
        }
        if (trainerIds.isEmpty()) return;

        List<LeadShare> toDelete = [
            SELECT Id FROM LeadShare
            WHERE UserOrGroupId IN :trainerIds
            AND RowCause = :Schema.LeadShare.RowCause.Manual
        ];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}
