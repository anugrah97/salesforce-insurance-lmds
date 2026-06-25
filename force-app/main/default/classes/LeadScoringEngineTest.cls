/**
 * LeadScoringEngineTest
 * Unit tests for LeadScoringEngine score calculators.
 */
@IsTest
private class LeadScoringEngineTest {

    static Lead buildLead(String channel, String source, String product) {
        return new Lead(
            LastName = 'ScoreTest', Company = 'Test Co',
            Email = 'test@test.com',
            MobilePhone = '9000000099',
            Channel__c = channel,
            Source__c = source,
            Product__c = product,
            Branch__c = 'Delhi'
        );
    }

    @IsTest
    static void testLeadScore_ReferralWithEmail() {
        Lead l = buildLead('Agency', 'Referral', 'Term Life');
        Integer score = LeadScoringEngine.calculateLeadScore(l, new List<Lead_Activity__c>());
        // Email +10, Mobile +10, Product +10, Referral +20 = 50
        System.assertEquals(50, score, 'Lead score should be 50 for referral with email and mobile');
    }

    @IsTest
    static void testLeadScore_WithActivities() {
        Lead l = buildLead('BANCA', 'Web', 'Health Insurance');
        List<Lead_Activity__c> acts = new List<Lead_Activity__c>{
            new Lead_Activity__c(Activity_Type__c = 'Phone Call', Activity_Date__c = Date.today()),
            new Lead_Activity__c(Activity_Type__c = 'Face-to-Face Visit', Activity_Date__c = Date.today())
        };
        Integer score = LeadScoringEngine.calculateLeadScore(l, acts);
        // Email+10, Mobile+10, Product+10, Web+10, Call+15, F2F+20 = 75
        System.assertEquals(75, score, 'Score should include activity bonuses');
    }

    @IsTest
    static void testPropensityScore_BANCABase() {
        Lead l = buildLead('BANCA', 'Referral', 'Term Life');
        // CreatedDate is null for in-memory lead; engine treats null as "new" (no age penalty)
        Integer score = LeadScoringEngine.calculatePropensityScore(l, new List<Lead_Activity__c>(), 40);
        // Base 60 (BANCA) + 10 (Referral) = 70
        System.assertEquals(70, score, 'BANCA base + referral should be 70');
    }

    @IsTest
    static void testPropensityScore_HotThreshold() {
        Lead l = buildLead('BANCA', 'Referral', 'Health Insurance');
        // CreatedDate is null for in-memory lead; no age penalty applied
        List<Lead_Activity__c> acts = new List<Lead_Activity__c>{
            new Lead_Activity__c(Activity_Type__c='Phone Call'),
            new Lead_Activity__c(Activity_Type__c='Phone Call'),
            new Lead_Activity__c(Activity_Type__c='Face-to-Face Visit')
        };
        Integer score = LeadScoringEngine.calculatePropensityScore(l, acts, 85);
        // Base 60 + 10 (acts>2) + 15 (leadScore>60) + 10 (referral) = 95
        System.assert(score > 75, 'Score should cross Hot threshold');
    }

    @IsTest
    static void testEngagementScore_Zero() {
        Integer score = LeadScoringEngine.calculateEngagementScore(new List<Lead_Activity__c>());
        System.assertEquals(0, score, 'No activities = 0 engagement');
    }

    @IsTest
    static void testEngagementScore_RecentF2F() {
        List<Lead_Activity__c> acts = new List<Lead_Activity__c>{
            new Lead_Activity__c(Activity_Type__c = 'Face-to-Face Visit', Activity_Date__c = Date.today()),
            new Lead_Activity__c(Activity_Type__c = 'Phone Call', Activity_Date__c = Date.today())
        };
        Integer score = LeadScoringEngine.calculateEngagementScore(acts);
        // 2 activities = 50, recent F2F +25 = 75
        System.assertEquals(75, score, 'Recent F2F should add 25 bonus');
    }

    @IsTest
    static void testDeriveTag_Hot() {
        String tag = LeadScoringEngine.deriveTag(80, 80, DateTime.now(), new List<Lead_Activity__c>());
        System.assertEquals('Hot', tag, 'Propensity > 75 should be Hot');
    }

    @IsTest
    static void testDeriveTag_AtRisk() {
        DateTime old = DateTime.now().addDays(-10);
        String tag = LeadScoringEngine.deriveTag(20, 30, old, new List<Lead_Activity__c>());
        System.assertEquals('At Risk', tag, 'Low score, old lead, no activity = At Risk');
    }

    @IsTest
    static void testDeriveTag_Normal() {
        String tag = LeadScoringEngine.deriveTag(60, 55, DateTime.now(), new List<Lead_Activity__c>());
        System.assertEquals('Normal', tag, 'Average scores should be Normal');
    }
}
