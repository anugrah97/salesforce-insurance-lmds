/**
 * BranchTrainerMappingTrigger
 * Fires on Branch_Trainer_Mapping__c insert/update/delete to manage Trainer Lead sharing.
 */
trigger BranchTrainerMappingTrigger on Branch_Trainer_Mapping__c (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        TrainerSharingService.grantAccess(Trigger.new);
    } else if (Trigger.isUpdate) {
        // Revoke old access then grant new
        TrainerSharingService.revokeAccess(Trigger.old);
        TrainerSharingService.grantAccess(Trigger.new);
    } else if (Trigger.isDelete) {
        TrainerSharingService.revokeAccess(Trigger.old);
    }
}
