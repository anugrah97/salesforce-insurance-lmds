/**
 * LeadNormaliser
 * Normalises mobile phone numbers and flags cross-sell opportunities before Lead insert/update.
 * Called from LeadBeforeInsert trigger.
 */
public with sharing class LeadNormaliser {

    /**
     * Normalises MobilePhone to 10-digit format and detects cross-sell leads.
     * @param leads List of Lead records from trigger context
     */
    public static void normalise(List<Lead> leads) {
        List<String> mobiles = new List<String>();

        for (Lead l : leads) {
            if (String.isNotBlank(l.MobilePhone)) {
                l.MobilePhone = normaliseMobile(l.MobilePhone);
                mobiles.add(l.MobilePhone);
            }
            // Auto-set Assigned_FLS__c to current user if not set
            if (l.Assigned_FLS__c == null) {
                l.Assigned_FLS__c = UserInfo.getUserId();
            }
        }

        // Cross-sell detection: same mobile exists with DIFFERENT product
        if (!mobiles.isEmpty()) {
            Map<String, Set<String>> existingProductsByMobile = getExistingProducts(mobiles);
            for (Lead l : leads) {
                if (String.isNotBlank(l.MobilePhone) && l.Product__c != null) {
                    Set<String> existingProducts = existingProductsByMobile.get(l.MobilePhone);
                    if (existingProducts != null && !existingProducts.isEmpty()) {
                        if (!existingProducts.contains(l.Product__c)) {
                            l.Is_Cross_Sell__c = true;
                        }
                    }
                }
            }
        }
    }

    /**
     * Strips +91, 91 prefix, spaces, and dashes from mobile number.
     * Returns 10-digit mobile string.
     */
    @TestVisible
    private static String normaliseMobile(String mobile) {
        // Remove all non-numeric characters
        String cleaned = mobile.replaceAll('[^0-9]', '');
        // Strip country code: 91 prefix on 12-digit number
        if (cleaned.length() == 12 && cleaned.startsWith('91')) {
            cleaned = cleaned.substring(2);
        }
        // Strip leading 0 on 11-digit number
        if (cleaned.length() == 11 && cleaned.startsWith('0')) {
            cleaned = cleaned.substring(1);
        }
        return cleaned;
    }

    /**
     * Queries existing Lead records to find which products already exist for given mobiles.
     */
    private static Map<String, Set<String>> getExistingProducts(List<String> mobiles) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        for (Lead l : [
            SELECT MobilePhone, Product__c
            FROM Lead
            WHERE MobilePhone IN :mobiles
            AND IsConverted = false
            AND Product__c != null
        ]) {
            if (!result.containsKey(l.MobilePhone)) {
                result.put(l.MobilePhone, new Set<String>());
            }
            result.get(l.MobilePhone).add(l.Product__c);
        }
        return result;
    }
}
