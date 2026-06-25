trigger ContentVersionBeforeInsert on ContentVersion (before insert) {
    FileValidationTrigger.validateOnVersionInsert(Trigger.new);
}
