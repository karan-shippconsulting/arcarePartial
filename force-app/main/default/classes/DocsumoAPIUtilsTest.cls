@isTest
public class DocsumoAPIUtilsTest {
    
    // Mock class to simulate HTTP responses
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response based on the request
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"Document fetched successfully"}');
            return res;
        }
    }

    @isTest
    static void testFetchApi() {
        // Setup: Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Test: Call the method
        Test.startTest();
        String response = DocsumoAPIUtils.fetchApi('https://api.docsumo.com/v1/documents');
        Test.stopTest();

        // Assert: Check that the response is as expected
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.contains('Document fetched successfully'), 'Response body should contain success message');
    }

    @isTest
    static void testPost() {
        // Setup: Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Setup: Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('document_id', '12345');
        requestBody.put('action', 'process');

        // Test: Call the method
        Test.startTest();
        String response = DocsumoAPIUtils.post('https://api.docsumo.com/v1/documents', requestBody);
        Test.stopTest();

        // Assert: Check that the response is as expected
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assert(response.contains('Document fetched successfully'), 'Response body should contain success message');
    }
    
    @isTest
    public static void testFetchApiErrorHandling() {
        // Mock HTTP response for error scenario (non-2xx status code)
        String mockErrorResponse = '{"error": "Server Error"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator(mockErrorResponse, 500));

        // Test fetchApi method
        try {
            Test.startTest();
            String response = DocsumoAPIUtils.fetchApi('https://api.docsumo.com/some-endpoint');
            Test.stopTest();
            System.assert(false, 'The test should have thrown an exception due to HTTP error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('HTTP Error: 500 -'), 'Expected HTTP error message');
        }
    }

    @isTest
    public static void testPostErrorHandling() {
        // Mock HTTP response for error scenario (non-2xx status code)
        String mockErrorResponse = '{"error": "Internal Server Error"}';
        Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator(mockErrorResponse, 500));

        // Prepare test data for the POST request
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('file', 'base64Content');
        requestBody.put('type', 'Invoice');
        requestBody.put('filename', 'testFile.pdf');

        // Test post method
        try {
            Test.startTest();
            String response = DocsumoAPIUtils.post('https://api.docsumo.com/upload', requestBody);
            Test.stopTest();
            System.assert(false, 'The test should have thrown an exception due to HTTP error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('HTTP Error: 500 -'), 'Expected HTTP error message');
        }
    }

    @isTest
    public static void testUnexpectedExceptionHandlingFetch() {
        // Mock the HTTP response to simulate an unexpected error (network issue, timeout, etc.)
        Test.setMock(HttpCalloutMock.class, new MockHttpUnexpectedErrorResponseGenerator());

        // Test fetchApi method for unexpected exception
        try {
            Test.startTest();
            String response = DocsumoAPIUtils.fetchApi('https://api.docsumo.com/some-endpoint');
            Test.stopTest();
            System.assert(false, 'The test should have thrown an exception due to unexpected error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Unexpected exception during API request'), 'Expected unexpected exception message');
        }

    }
    
    @isTest
    public static void testUnexpectedExceptionHandlingPost() {
        // Mock the HTTP response to simulate an unexpected error (network issue, timeout, etc.)
        Test.setMock(HttpCalloutMock.class, new MockHttpUnexpectedErrorResponseGenerator());


        // Test post method for unexpected exception
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('file', 'base64Content');
        requestBody.put('type', 'Invoice');
        requestBody.put('filename', 'testFile.pdf');

        try {
            Test.startTest();
            String response = DocsumoAPIUtils.post('https://api.docsumo.com/upload', requestBody);
            Test.stopTest();
            System.assert(false, 'The test should have thrown an exception due to unexpected error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('Unexpected exception during API request'), 'Expected unexpected exception message');
        }
    }

    // Mock response generator for HTTP error (non-2xx status code)
    public class MockHttpErrorResponseGenerator implements HttpCalloutMock {
        private String mockResponse;
        private Integer statusCode;

        public MockHttpErrorResponseGenerator(String response, Integer code) {
            this.mockResponse = response;
            this.statusCode = code;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(statusCode);
            return res;
        }
    }

    // Mock response generator for unexpected errors (e.g., network issues)
    public class MockHttpUnexpectedErrorResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Unexpected exception during API request');
        }
    }
}