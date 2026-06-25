/**
 * LeadNormaliserTest
 * Unit tests for LeadNormaliser — mobile normalisation and cross-sell detection.
 */
@IsTest
private class LeadNormaliserTest {

    @IsTest
    static void testMobileNormalisation_WithCountryCode() {
        Lead l = new Lead(
            LastName = 'Test', Company = 'Test Co',
            MobilePhone = '+91 98765 43210',
            Channel__c = 'Agency', Product__c = 'Term Life',
            Branch__c = 'Delhi'
        );
        insert l;
        Lead result = [SELECT MobilePhone FROM Lead WHERE Id = :l.Id];
        System.assertEquals('9876543210', result.MobilePhone, 'Mobile should be normalised to 10 digits');
    }

    @IsTest
    static void testMobileNormalisation_WithSpacesAndDashes() {
        Lead l = new Lead(
            LastName = 'Test2', Company = 'Test Co',
            MobilePhone = '98765-43210',
            Channel__c = 'Direct', Product__c = 'Health Insurance',
            Branch__c = 'Mumbai'
        );
        insert l;
        Lead result = [SELECT MobilePhone FROM Lead WHERE Id = :l.Id];
        System.assertEquals('9876543210', result.MobilePhone, 'Dashes should be stripped');
    }

    @IsTest
    static void testCrossSellFlagSet() {
        // Insert first lead
        Lead existing = new Lead(
            LastName = 'CrossSell', Company = 'Test Co',
            MobilePhone = '9123456789',
            Channel__c = 'Agency', Product__c = 'Term Life',
            Branch__c = 'Delhi'
        );
        insert existing;

        // Insert second lead with same mobile, different product
        Lead crossSell = new Lead(
            LastName = 'CrossSell', Company = 'Test Co',
            MobilePhone = '9123456789',
            Channel__c = 'Agency', Product__c = 'Health Insurance',
            Branch__c = 'Delhi'
        );
        insert crossSell;

        Lead result = [SELECT Is_Cross_Sell__c FROM Lead WHERE Id = :crossSell.Id];
        System.assertEquals(true, result.Is_Cross_Sell__c, 'Cross-sell flag should be true for same mobile, different product');
    }

    @IsTest
    static void testAssignedFLSDefaultsToCurrentUser() {
        Lead l = new Lead(
            LastName = 'FLSTest', Company = 'Test Co',
            MobilePhone = '9000000001',
            Channel__c = 'BANCA', Product__c = 'Motor Insurance',
            Branch__c = 'Chennai'
        );
        insert l;
        Lead result = [SELECT Assigned_FLS__c FROM Lead WHERE Id = :l.Id];
        System.assertEquals(UserInfo.getUserId(), result.Assigned_FLS__c, 'Assigned FLS should default to current user');
    }
}
