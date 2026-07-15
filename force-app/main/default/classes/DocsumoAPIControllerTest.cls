@isTest
public class DocsumoAPIControllerTest {

    @isTest
    public static void testSendFileForProcessing() {
        // Set up test data
        // Create a ContentVersion (representing an uploaded file)
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            VersionData = Blob.valueOf('Test File Content'),
            PathOnClient = 'test'
        );
        insert testContentVersion;
        
        Lead ld = new Lead(LastName = 'Test', Company='Test');
        insert ld;
        

        // Create a FileDetails object and set the required values
        DocsumoAPIController.FileDetails fileDetails = new DocsumoAPIController.FileDetails();
        fileDetails.contentVersionIds = new List<String>{testContentVersion.Id};
        fileDetails.documentCategory = 'us_license';
        fileDetails.recordId = ld.Id;

        // Mock HTTP response for the callout
        String mockResponse = '{"data": {"document": [{"user_id": "testUser", "title": "Test Document", "email": "test@example.com", "review_url": "https://review.url", "doc_id": "doc123", "type": "Invoice", "status": "processed"}]}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Call the method
        Test.startTest();
        List<List<String>> result = DocsumoAPIController.sendFileForProcessing(new List<DocsumoAPIController.FileDetails>{fileDetails});
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(result, null, 'The result should not be null');
        System.assertEquals(result.size(), 1, 'There should be one result');
        System.assertEquals(result[0].size(), 1, 'There should be one record ID in the list');
        
        // Verify the created record (could be a custom object or standard object with docsumo fields)
        // You would need to query and verify the fields populated based on the response
        List<SObject> records = [SELECT doc_id__c, doc_status__c, review_url__c FROM DS_us_license__c WHERE Lead__c =: ld.Id];
        System.assertEquals(records.size(), 1, 'One record should be created');
        System.assertEquals(records[0].get('doc_id__c'), 'doc123', 'The doc_id should be correct');
        System.assertEquals(records[0].get('doc_status__c'), 'Processed', 'The doc_status should be correct');
        System.assertEquals(records[0].get('review_url__c'), 'https://review.url?&client=true', 'The review URL should be correct');
    }

    // Mock response generator for the HTTP callout
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private String mockResponse;

        public MockHttpResponseGenerator(String response) {
            this.mockResponse = response;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}