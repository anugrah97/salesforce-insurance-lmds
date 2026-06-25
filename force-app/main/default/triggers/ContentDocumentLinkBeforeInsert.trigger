trigger ContentDocumentLinkBeforeInsert on ContentDocumentLink (before insert) {
    FileValidationTrigger.validateOnLinkInsert(Trigger.new);
}
