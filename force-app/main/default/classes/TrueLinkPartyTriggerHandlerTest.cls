@isTest
public class TrueLinkPartyTriggerHandlerTest {
   @isTest
    static void testcreateTrustBeneficiary() {
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB1234');
        insert pc; 
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test1', Is_Default__c=true, True_Link_Portfolio_ID__c='test1', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        contact party = TruelinkBeneficiaryRequestBuilderTest.createTestData();
        trust__c trust = new trust__c(Pooled_Trust__c = pc.Id,Trust_Portfolio__c = tp.id);
        trust.Trust_Status__c = 'Active';
        trust.TrueLink_ID__c = '1231234';
        trust.Beneficiary__c=party.id;
        insert trust;

        Test.startTest();
        TrueLinkPartyTriggerHandler.createTrustBeneficiary(party.id, trust.id);
        TrueLinkPartyTriggerHandler.updateTrustBeneficiary(party.id, trust.id,'test');
        TrueLinkPartyTriggerHandler.updateAddress(party.id,'test', false);
        Test.stopTest();

    }
    
}