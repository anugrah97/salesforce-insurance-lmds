/**
 * TrainerSharingService
 * Manages Apex Sharing for Trainers based on Branch_Trainer_Mapping__c records.
 * Called from BranchTrainerMappingTrigger.
 *
 * Logic:
 *   On mapping INSERT / activate: find all FLS users in the branch,
 *     find all their Lead records, insert LeadShare rows for the Trainer.
 *   On mapping DELETE / deactivate: delete LeadShare rows for the Trainer
 *     where RowCause = Schema.LeadShare.RowCause.Manual.
 */
public with sharing class TrainerSharingService {

    public static void grantAccess(List<Branch_Trainer_Mapping__c> mappings) {
        Map<Id, Id> trainerByBranch = new Map<Id, Id>();
        for (Branch_Trainer_Mapping__c m : mappings) {
            if (m.Is_Active__c) {
                trainerByBranch.put(m.Branch__c, m.Trainer__c);
            }
        }
        if (trainerByBranch.isEmpty()) return;

        // Find FLS users in these branches
        List<User> flsUsers = [
            SELECT Id, Branch__c
            FROM User
            WHERE Branch__c IN :trainerByBranch.keySet()
            AND IsActive = true
        ];
        if (flsUsers.isEmpty()) return;

        // Find leads assigned to these FLS
        Set<Id> flsIds = new Set<Id>();
        Map<Id, Id> branchByFLS = new Map<Id, Id>();
        for (User u : flsUsers) {
            flsIds.add(u.Id);
            branchByFLS.put(u.Id, u.Branch__c);
        }

        List<Lead> leads = [
            SELECT Id, Assigned_FLS__c
            FROM Lead
            WHERE Assigned_FLS__c IN :flsIds
            AND IsConverted = false
        ];

        List<LeadShare> shares = new List<LeadShare>();
        for (Lead l : leads) {
            Id branchId  = branchByFLS.get(l.Assigned_FLS__c);
            Id trainerId = branchId != null ? trainerByBranch.get(branchId) : null;
            if (trainerId != null) {
                shares.add(new LeadShare(
                    LeadId      = l.Id,
                    UserOrGroupId = trainerId,
                    LeadAccessLevel = 'Read',
                    RowCause    = Schema.LeadShare.RowCause.Manual
                ));
            }
        }

        if (!shares.isEmpty()) {
            Database.insert(shares, false); // Partial success — ignore existing shares
        }
    }

    public static void revokeAccess(List<Branch_Trainer_Mapping__c> mappings) {
        Set<Id> trainerIds = new Set<Id>();
        for (Branch_Trainer_Mapping__c m : mappings) {
            trainerIds.add(m.Trainer__c);
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
