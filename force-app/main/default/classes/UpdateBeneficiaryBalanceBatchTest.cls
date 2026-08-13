@isTest
public class UpdateBeneficiaryBalanceBatchTest {
    @isTest
    static void testStart() {
        HttpCalloutMock mock = new TrueLinkApiHandlerMock();
        Test.setMock(HttpCalloutMock.class, mock);
        
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'test';
        insert setting;
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB1234');
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

        list<trust__c> accList = new list<trust__c>();
        acclist.add(trust);
        UpdateBeneficiaryBalanceBatch cb = new UpdateBeneficiaryBalanceBatch();
        Database.QueryLocator ql = cb.start(null);
        cb.execute(null);
        cb.Finish(null);
        try{
            cb.execute(null,accList);
        }
        catch(exception e){}
    }
    
    @isTest
    static void testStartExcludesIneligibleTrustStatus() {
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'test';
        insert setting;

        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB1234');
        insert pc;

        Trust_Portfolio__c tp = new Trust_Portfolio__c(name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;

        Contact party = new Contact(lastname = 'Test Account');
        insert party;

        trust__c eligible = new trust__c(Pooled_Trust__c = pc.Id, Trust_Portfolio__c = tp.id, Trust_Status__c = 'Active', TrueLink_ID__c = 'eligible-1', Beneficiary__c = party.id);
        insert eligible;

        trust__c ineligible = new trust__c(Pooled_Trust__c = pc.Id, Trust_Portfolio__c = tp.id, Trust_Status__c = 'Intake', TrueLink_ID__c = 'ineligible-1', Beneficiary__c = party.id);
        insert ineligible;

        UpdateBeneficiaryBalanceBatch cb = new UpdateBeneficiaryBalanceBatch();
        Database.QueryLocator ql = cb.start(null);
        Set<Id> resultIds = new Set<Id>();
        Database.QueryLocatorIterator it = ql.iterator();
        while (it.hasNext()) {
            resultIds.add(((trust__c) it.next()).Id);
        }

        System.assert(resultIds.contains(eligible.Id), 'Eligible trust should be included');
        System.assert(!resultIds.contains(ineligible.Id), 'Ineligible trust should be excluded');
    }

    // Mock class for successful callout
    public class TrueLinkApiHandlerMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data": {"id": "123","meta":{"totalAccountBalance":123.0}, "attributes" : { "disallowDisbursementRequests" : true, "chargeSetupFee": true}}}');
            res.setStatusCode(200);
            return res;
        }
    }
}