@isTest
public class UpdateTruelinkBatchesTest {

    @TestSetup
    static void setupTestData() {
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'https://test.com';
        setting.Sandbox_Apikey__c = 'Apikey test';
        setting.Sandbox_Endpoint__c = 'https://test.com';
        insert setting;

        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB1234');
        insert pc;

        Trust_Portfolio__c tp = new Trust_Portfolio__c(name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
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

        trust__c trust = new trust__c(Pooled_Trust__c = pc.Id, Trust_Portfolio__c = tp.id);
        trust.Trust_Status__c = 'Active';
        trust.TrueLink_ID__c = '123123';
        trust.Beneficiary__c = party.id;
        insert trust;
    }

    private static trust__c getSetupTrust() {
        return [SELECT Id, TrueLink_ID__c, True_Link_Balance__c, Trust_Status__c FROM trust__c LIMIT 1];
    }

    @isTest
    static void testStart() {
        HttpCalloutMock mock = new TrueLinkApiHandlerMock();
        Test.setMock(HttpCalloutMock.class, mock);

        trust__c trust = getSetupTrust();

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

    @isTest
    static void testUpdateDepositsBatchSuccess() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c trust = getSetupTrust();
        TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;

        Test.startTest();
        Database.executeBatch(new UpdateDepositsBatch(), 1);
        Test.stopTest();

        List<Transaction__c> deposits = [SELECT Id FROM Transaction__c WHERE Trust__c = :trust.Id];
        System.assert(!deposits.isEmpty(), 'Deposit transactions should be created');
    }

    @isTest
    static void testUpdateDepositsBatchHandlesErrors() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c trust = getSetupTrust();
        delete trust;

        UpdateDepositsBatch batch = new UpdateDepositsBatch();
        batch.execute(null, new List<trust__c>{trust});
        batch.finish(null);

        List<Track_API_Call__c> errors = [SELECT Id FROM Track_API_Call__c WHERE Status__c = 'Error'];
        System.assert(!errors.isEmpty(), 'Error should be tracked when the trust lookup fails');
    }

    @isTest
    static void testUpdateDepositsBatchExcludesIneligibleStatus() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c eligibleTrust = getSetupTrust();
        TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;

        Pooled_Trust__c pc = [SELECT Id FROM Pooled_Trust__c LIMIT 1];
        Trust_Portfolio__c tp = [SELECT Id FROM Trust_Portfolio__c LIMIT 1];
        Contact party = [SELECT Id FROM Contact LIMIT 1];
        trust__c ineligibleTrust = new trust__c(Pooled_Trust__c = pc.Id, Trust_Portfolio__c = tp.Id, Beneficiary__c = party.Id, TrueLink_ID__c = 'ineligible-conn', Trust_Status__c = 'Intake');
        insert ineligibleTrust;

        Test.startTest();
        Database.executeBatch(new UpdateDepositsBatch(), 1);
        Test.stopTest();

        List<Transaction__c> ineligibleDeposits = [SELECT Id FROM Transaction__c WHERE Trust__c = :ineligibleTrust.Id];
        System.assert(ineligibleDeposits.isEmpty(), 'Deposits batch should not process a trust with an ineligible status');

        List<Transaction__c> eligibleDeposits = [SELECT Id FROM Transaction__c WHERE Trust__c = :eligibleTrust.Id];
        System.assert(!eligibleDeposits.isEmpty(), 'Deposits batch should still process the eligible trust');
    }

    @isTest
    static void testUpdateDisbursementsBatchSuccess() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c trust = getSetupTrust();
        TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;

        Test.startTest();
        Database.executeBatch(new UpdateDisbursementsBatch(), 1);
        Test.stopTest();

        List<Transaction__c> disbursements = [SELECT Id FROM Transaction__c WHERE Trust__c = :trust.Id];
        System.assert(!disbursements.isEmpty(), 'Disbursement transactions should be created');
    }

    @isTest
    static void testUpdateDisbursementsBatchWithTrustIdsFilter() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c trust = getSetupTrust();
        TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;

        Test.startTest();
        Database.executeBatch(new UpdateDisbursementsBatch(new List<Id>{trust.Id}), 1);
        Test.stopTest();

        List<Transaction__c> disbursements = [SELECT Id FROM Transaction__c WHERE Trust__c = :trust.Id];
        System.assert(!disbursements.isEmpty(), 'Disbursement transactions should be created when filtering by trust Ids');
    }

    @isTest
    static void testUpdateDisbursementsBatchHandlesErrors() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkTransactionMock());
        trust__c trust = getSetupTrust();
        delete trust;

        UpdateDisbursementsBatch batch = new UpdateDisbursementsBatch();
        batch.execute(null, new List<trust__c>{trust});
        batch.finish(null);

        List<Track_API_Call__c> errors = [SELECT Id FROM Track_API_Call__c WHERE Status__c = 'Error'];
        System.assert(!errors.isEmpty(), 'Error should be tracked when the trust lookup fails');
    }

    // Mock class for TrueLink deposit/disbursement transaction callouts
    public class TrueLinkTransactionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('/deposits/')) {
                res.setBody('{"data":[{"id":"dep-1","type":"deposit","attributes":{"status":"Cleared","clearedDate":"2026-01-01","deliveryDate":"2026-01-01","merchant":"Test Merchant","paymentId":"pay-1","paymentMethod":"Check","amount":{"amount":100.0,"field_currency":"USD"}}}]}');
            } else if (req.getEndpoint().contains('/disbursements/')) {
                res.setBody('{"data":[{"id":"dis-1","type":"disbursement","attributes":{"status":"Cleared","clearedDate":"2026-01-01","deliveryDate":"2026-01-01","processedDate":"2026-01-01","paymentMethod":"Check","requestorDescription":"test","requestedBySignature":"test","payeeName":"John Payee","payeeDescription":"desc","payeeDisposition":"disp","postageCode":1,"postageType":"First Class","checkNum":"123","checkMemoLine":"memo","payeeMemo":"memo2","payeeSwiftCode":"SWIFT","payeeSpecialInstructions":"instructions","fromRecurring":false,"amount":{"amount":200.0,"field_currency":"USD"},"payeeAddress":{"street1":"123 St","street2":"Apt 1","city":"City","state":"CA","zip":"12345"},"payeeBankAccount":{"accountNumber":"123","routingNumber":"456"}},"relationships":{"categoryAmounts":{"data":[{"id":"cat-1","type":"disbursement_category_amount"}]},"recurringDisbursement":{"data":{"id":"rec-1","type":"recurring_disbursement"}},"attachments":{"data":[{"id":"att-1","type":"attachment"}]}},"meta":{"displayCategory":"Category A"}}],"included":[{"id":"cat-1","type":"disbursement_category_amount","attributes":{"notes":"some notes","recurringType":"Monthly","frequency":1}},{"id":"rec-1","type":"recurring_disbursement","attributes":{"notes":null,"recurringType":"Monthly","frequency":1}}]}');
            } else {
                res.setBody('{"data":[]}');
            }
            return res;
        }
    }
}