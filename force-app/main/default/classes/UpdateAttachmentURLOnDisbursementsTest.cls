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
        TruelinkData__c setting = new TruelinkData__c();
        setting.Sandbox_ApiKey__c = 'Bearer dummy-key';
        setting.Sandbox_Endpoint__c = 'https://dummy-endpoint.com';
        setting.Production_ApiKey__c = 'Bearer dummy-key';
        setting.Production_Endpoint__c = 'https://dummy-endpoint.com';
        insert setting;

        Truelink_Feature_Management__c feature = new Truelink_Feature_Management__c(
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert feature;

        Contact con = new Contact(LastName = 'Account VALUE NEW');
        insert con;

        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;

        Trust_Portfolio__c tp = new Trust_Portfolio__c(
            Name = 'test',
            Is_Default__c = true,
            True_Link_Portfolio_ID__c = 'test',
            Type__c = 'Portfolio',
            Pooled_Trust__c = pc.Id
        );
        insert tp;

        Trust__c trust = new Trust__c(
            Name = 'Test Account',
            TrueLink_ID__c = 'abc',
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

        tranx = [SELECT Id, Attachment_URL__c FROM Transaction__c WHERE True_Link_Transaction_ID__c = 'D123' LIMIT 1];
        System.assertEquals('https://test-url.com/12345', tranx.Attachment_URL__c);
    }

    @isTest
    static void testSkipsRecordsWithNoAttachmentId() {
        Trust__c trust = [SELECT Id FROM Trust__c LIMIT 1];

        Transaction__c tranx = new Transaction__c(
            Type__c = 'Disbursement',
            Trust__c = trust.Id,
            True_Link_Transaction_ID__c = 'D999'
        );
        insert tranx;

        Test.setMock(HttpCalloutMock.class, new AttachmentMock());

        Test.startTest();
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
        Test.stopTest();

        tranx = [SELECT Id, Attachment_URL__c FROM Transaction__c WHERE True_Link_Transaction_ID__c = 'D999' LIMIT 1];
        System.assertEquals(null, tranx.Attachment_URL__c);
    }

    @isTest
    static void testQueueableChaining() {
        Trust__c trust = [SELECT Id FROM Trust__c LIMIT 1];

        List<Transaction__c> tranxList = new List<Transaction__c>();
        for (Integer i = 1; i <= 3; i++) {
            tranxList.add(new Transaction__c(
                Type__c = 'Disbursement',
                Trust__c = trust.Id,
                True_Link_Transaction_ID__c = 'D' + i,
                Attachment_Id__c = 'A' + i
            ));
        }
        insert tranxList;

        UpdateAttachmentURLOnDisbursements.BATCH_SIZE = 2;
        Test.setMock(HttpCalloutMock.class, new AttachmentMock());

        Test.startTest();
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
        Test.stopTest();

        Integer updatedCount = 0;
        for (Transaction__c t : [SELECT Attachment_URL__c FROM Transaction__c WHERE Trust__c = :trust.Id AND Attachment_Id__c != null]) {
            if (!String.isBlank(t.Attachment_URL__c)) updatedCount++;
        }
        System.assertEquals(2, updatedCount);
    }
}