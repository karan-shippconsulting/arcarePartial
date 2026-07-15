@isTest
public class UpdateAttachmentURLOnDisbursementsTest {

    private class AttachmentMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":{"id":"string","type":"attachment","attributes":{"attachableId":0,"attachableType":"Account","contentType":"string","createdAt":"string","name":"string","category":"string","contentDate":"string","uploader":"string","smartpayablesInsert":true,"url":"https://test-url.com/12345"},"meta":{"permissions":{}}}}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        TruelinkData__c tldata = new TruelinkData__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            endpoint__c = 'https://dummy-endpoint.com',
            ApiKey__c = 'Bearer dummy-key'
        );
        insert tldata;

        Contact con = new Contact(LastName = 'Test');
        insert con;

        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;

        Trust_Portfolio__c tp = new Trust_Portfolio__c(
            Name = 'test', Is_Default__c = true,
            True_Link_Portfolio_ID__c = 'testPortfolio',
            Type__c = 'Portfolio', Pooled_Trust__c = pc.Id
        );
        insert tp;

        Trust__c trust = new Trust__c(
            Name = 'Test Trust',
            TrueLink_ID__c = 'abc123',
            Beneficiary__c = con.Id,
            Trust_Portfolio__c = tp.Id,
            Pooled_Trust__c = pc.Id,
            Disbursement_Creation_Enabled__c = false,
            Trust_Status__c = 'Active'
        );
        insert trust;
    }

    @isTest
    static void testQueueableExecution() {
        Trust__c trust = [SELECT Id FROM Trust__c LIMIT 1];

        Transaction__c tranx = new Transaction__c(
            Type__c = 'Disbursement',
            Trust__c = trust.Id,
            True_Link_Transaction_ID__c = 'D123',
            Attachment_Id__c = 'A123'
        );
        insert tranx;

        Test.setMock(HttpCalloutMock.class, new AttachmentMock());

        Test.startTest();
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
        Test.stopTest();

        tranx = [SELECT Attachment_URL__c FROM Transaction__c WHERE True_Link_Transaction_ID__c = 'D123' LIMIT 1];
        System.assertEquals('https://test-url.com/12345', tranx.Attachment_URL__c);
    }

    @isTest
    static void testSkipsRecordsWithNoAttachmentId() {
        Trust__c trust = [SELECT Id FROM Trust__c LIMIT 1];

        // Record with no Attachment_Id__c — should be ignored
        insert new Transaction__c(
            Type__c = 'Disbursement',
            Trust__c = trust.Id,
            True_Link_Transaction_ID__c = 'D_NO_ATT'
        );

        Test.setMock(HttpCalloutMock.class, new AttachmentMock());

        Test.startTest();
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
        Test.stopTest();

        Transaction__c tx = [SELECT Attachment_URL__c FROM Transaction__c WHERE True_Link_Transaction_ID__c = 'D_NO_ATT' LIMIT 1];
        System.assertEquals(null, tx.Attachment_URL__c, 'Record without Attachment_Id__c should not have URL set');
    }

    @isTest
    static void testQueueableChaining() {
        Trust__c trust = [SELECT Id FROM Trust__c LIMIT 1];

        // Override batch size so we can test the chain path with just 3 records
        UpdateAttachmentURLOnDisbursements.BATCH_SIZE = 2;

        List<Transaction__c> tranxList = new List<Transaction__c>();
        for (Integer i = 0; i < 3; i++) {
            tranxList.add(new Transaction__c(
                Type__c = 'Disbursement',
                Trust__c = trust.Id,
                True_Link_Transaction_ID__c = 'CHAIN_TX_' + i,
                Attachment_Id__c = 'CHAIN_ATT_' + i
            ));
        }
        insert tranxList;

        Test.setMock(HttpCalloutMock.class, new AttachmentMock());

        Test.startTest();
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
        Test.stopTest();

        Integer updatedCount = 0;
        for (Transaction__c t : [SELECT Attachment_URL__c FROM Transaction__c WHERE Trust__c = :trust.Id]) {
            if (!String.isBlank(t.Attachment_URL__c)) updatedCount++;
        }
        System.assertEquals(2, updatedCount, 'Expected exactly the first batch of 2 to be processed');
    }
}