@isTest
public class UpdateConnectionsBatchTest {

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
            lastname = 'Test Beneficiary',
            email = 'jane.doe@example.com'
        );
        insert party;

        trust__c trust = new trust__c(Pooled_Trust__c = pc.Id, Trust_Portfolio__c = tp.id);
        trust.Trust_Status__c = 'Active';
        trust.TrueLink_ID__c = 'trustbenef-123';
        trust.Beneficiary__c = party.id;
        insert trust;

        Connections__c con = new Connections__c();
        con.Trust__c = trust.Id;
        con.True_Link_Id__c = 'connection-123';
        con.First_Name__c = 'John';
        con.Last_Name__c = 'Connection';
        con.Mobile__c = '9876543210';
        con.Email__c = 'john.connection@example.com';
        con.Company_Name__c = 'Acme Co';
        con.Notes__c = 'Some notes';
        con.Street_1__c = '123 Main St';
        con.Street_2__c = 'Apt 1';
        con.City__c = 'Anytown';
        con.State__c = 'CA';
        con.Zip__c = '12345';
        con.Relationship_Types__c = 'Sibling;Guardian';
        con.Is_Statement_Recipient__c = true;
        con.Update_True_Link__c = true;
        insert con;
    }

    private static Connections__c getSetupConnection() {
        return [SELECT Id, Update_True_Link__c FROM Connections__c LIMIT 1];
    }

    @isTest
    static void testUpdateConnectionsBatchSuccess() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkConnectionMock());

        Test.startTest();
        Database.executeBatch(new UpdateConnectionsBatch(), 1);
        Test.stopTest();

        Connections__c con = getSetupConnection();
        System.assertEquals(false, con.Update_True_Link__c, 'Update_True_Link__c should be reset to false after a successful callout');

        List<Track_API_Call__c> successes = [SELECT Id FROM Track_API_Call__c WHERE Status__c = 'Success'];
        System.assert(!successes.isEmpty(), 'A successful Track_API_Call__c record should be created');
    }

    @isTest
    static void testUpdateConnectionsBatchHandlesErrors() {
        Test.setMock(HttpCalloutMock.class, new TrueLinkConnectionMock());
        Connections__c con = getSetupConnection();
        trust__c trust = [SELECT Id FROM trust__c LIMIT 1];
        delete trust;

        UpdateConnectionsBatch batch = new UpdateConnectionsBatch();
        batch.execute(null, new List<Connections__c>{con});
        batch.finish(null);

        List<Track_API_Call__c> errors = [SELECT Id FROM Track_API_Call__c WHERE Status__c = 'Error'];
        System.assert(!errors.isEmpty(), 'Error should be tracked when the connection lookup fails');

        Connections__c reQueried = getSetupConnection();
        System.assertEquals(true, reQueried.Update_True_Link__c, 'Update_True_Link__c should remain true when the update failed');
    }

    // Mock class for successful connection PATCH callout
    public class TrueLinkConnectionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data": {"id": "connection-123", "type": "connection", "attributes": {"firstName": "John", "lastName": "Connection"}}}');
            return res;
        }
    }
}