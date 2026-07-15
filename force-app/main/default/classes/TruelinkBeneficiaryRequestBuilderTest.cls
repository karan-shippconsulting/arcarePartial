@isTest
public class TruelinkBeneficiaryRequestBuilderTest {
    
    public static Contact createTestData(){        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc; 
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
                
        Contact party = new Contact(
            lastname = 'Test Account',
            MailingStreet = '123 Main St',
            MailingCity = 'Anytown',
            MailingState = 'CA',
            Mailingpostalcode = '12345',
            Salutation__c = 'Mr',
            email = 'john.doe@example.com',
            mobilephone = '9876543210',
            birthdate = Date.today().addDays(-30)
        );
        insert party;

        trust__c trust = new trust__c(Pooled_Trust__c = pc.Id,Trust_Portfolio__c = tp.id);
        trust.Trust_Status__c = 'Active';
        trust.TrueLink_ID__c = '123123';
        trust.Beneficiary__c=party.id;
        insert trust;
        
        return party;
    }
    
    @isTest
    public static void testBuild() {
        TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
        contact party = createTestData();
        trust__c trust = [select id,Trust_Status__c,TrueLink_ID__c,Pooled_Trust__c,Trust_Portfolio__c from trust__c limit 1];
        TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id,trust.Id,'test',true);
        TruelinkBeneficiaryRequestWrapper wrapper1 = builder.build(party.Id,trust.Id,'test',false);
        TruelinkBeneficiaryRequestWrapper wrapper2 = builder.buildRequestForEinBidUpdate(trust.id);
        TruelinkBeneficiaryRequestWrapper wrapper3 = builder.buildRequestForTrustDisbursement(trust.id);
        TruelinkBeneficiaryAddressRequestWrapper wrapper4 = builder.buildAddress(party.id,trust.TrueLink_ID__c);
        System.assertNotEquals(null, wrapper);
    }
    
}