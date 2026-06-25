/**
 * LeadBeforeInsert
 * Normalises mobile numbers and detects cross-sell opportunities before Lead insert/update.
 */
trigger LeadBeforeInsert on Lead (before insert, before update) {
    LeadNormaliser.normalise(Trigger.new);
}
