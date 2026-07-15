@isTest
public class DocumentDetailsTest {
    
    // Test method to validate the getSFLabel method of DocsumoFieldDetail
    @isTest
    public static void testDocsumoDocumentDetailGetSFLabel() {
        DocumentDetails.DocsumoDocumentDetail documentDetail = new DocumentDetails.DocsumoDocumentDetail();
        documentDetail.name = 'Name';
        
        // Validate the getSFLabel method behavior
        String fieldLabel = documentDetail.getSFLabel();
        
        System.assertEquals('DS Name', fieldLabel);
    }
    
    
    // Test method to validate the getSFLabel method of DocsumoFieldDetail
    @isTest
    public static void testDocsumoDocumentDetailGetSFObjectName() {
        DocumentDetails.DocsumoDocumentDetail documentDetail = new DocumentDetails.DocsumoDocumentDetail();
        documentDetail.name = 'Name';
        
        // Validate the getSFLabel method behavior
        String objectLabel = documentDetail.getSFObjectName();
        
        System.assertEquals('DS_name__c', objectLabel);
    }
    
    // Test method to validate the getSFLabel method of DocsumoFieldDetail
    @isTest
    public static void testDocsumoFieldDetailGetSFLabel() {
        DocumentDetails.DocsumoFieldDetail fieldDetail = new DocumentDetails.DocsumoFieldDetail();
        fieldDetail.label = 'Test Field';
        fieldDetail.section = 'Test Section';
        
        // Validate the getSFLabel method behavior
        String fieldLabel = fieldDetail.getSFLabel();
        
        System.assertEquals('TS Test Field', fieldLabel);
    }
    
    // Test method to validate the getSFColumnName method of DocsumoFieldDetail
    @isTest
    public static void testDocsumoFieldDetailGetSFColumnName() {
        DocumentDetails.DocsumoFieldDetail fieldDetail = new DocumentDetails.DocsumoFieldDetail();
        fieldDetail.label = 'Test Field';
        fieldDetail.section = 'Test Section';
        
        // Validate the getSFColumnName method behavior
        String columnName = fieldDetail.getSFColumnName();
        
        System.assertEquals('ts_test_field__c', columnName);
    }

    // Test method to validate the getSFLabel method of DocsumoTable
    @isTest
    public static void testDocsumoTableGetSFLabel() {
        DocumentDetails.DocsumoTable table = new DocumentDetails.DocsumoTable();
        table.label = 'Test Table';
        table.section = 'Test Section';
        
        // Validate the getSFLabel method behavior
        String tableLabel = table.getSFLabel();
        
        System.assertEquals('DS Test Section Test Table', tableLabel);
    }
    
    // Test method to validate the getSFObjectName method of DocsumoTable
    @isTest
    public static void testDocsumoTableGetSFObjectName() {
        DocumentDetails.DocsumoTable table = new DocumentDetails.DocsumoTable();
        table.label = 'Table';
        table.section = 'Section';
        
        // Validate the getSFObjectName method behavior
        String objectName = table.getSFObjectName();
        
        System.assertEquals('DS_section_table__c', objectName);
    }
  
    // Test method for DocsumoAPIUtils.fetchApi()
    @isTest
    public static void testFetchApi() {
        // Setup mock response for fetchApi method
        String mockResponse = '{"data":{"sections":[{"title":"Section 1","children":[{"type":"line_item","label":"Item 1","children":[[{"label":"Column 1","type":"string","content":{"value":"Value 1"}}]]}]}]}}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Test fetchApi call
        String url = 'https://appstaging.docsumo.com/api/v2/pik/documents/123456/data/';
        String result = DocsumoAPIUtils.fetchApi(url);
        
        // Asserts to verify the behavior of the fetchApi method
        System.assertNotEquals(null, result);
        System.assert(result.contains('Value 1'), 'Expected response to contain "Value 1"');
    }

    // Test method for DocsumoAPIUtils.post()
    @isTest
    public static void testPost() {
        // Setup mock response for post method
        String mockResponse = '{"status":"success","message":"Data submitted successfully"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        
        // Test data for post
        Map<String, Object> postData = new Map<String, Object>();
        postData.put('field1', 'value1');
        postData.put('field2', 'value2');

        // Test post method
        String url = 'https://appstaging.docsumo.com/api/v2/pik/documents/submit/';
        String result = DocsumoAPIUtils.post(url, postData);
        
        // Asserts to verify the behavior of the post method
        System.assertNotEquals(null, result);
        System.assert(result.contains('success'), 'Expected response to contain "success"');
    }
    
    // Mock HttpCallout for testing
    class MockHttpResponseGenerator implements HttpCalloutMock {
        String jsonResponse;
        
        MockHttpResponseGenerator(String jsonResponse) {
            this.jsonResponse = jsonResponse;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody(jsonResponse);
            res.setStatusCode(200);
            return res;
        }
    }
}