@isTest
public class TrackApiUtilTest {
     @isTest
    static void testTrackMethodWithRequestAndResponse() {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://mockendpoint.com/api');
        req.setBody('{"key": "value"}');
        
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(200);
        resp.setBody('{"status": "success"}');
        
        Track_API_Call__c trackObj = new Track_API_Call__c();
        Track_API_Call__c result = TrackApiUtil.track(trackObj, req, resp, null);
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals('POST', result.Http_Method__c);
        System.assertEquals('{"key": "value"}', result.Request__c);
        System.assertEquals('https://mockendpoint.com/api', result.Request_URL__c);
        System.assertEquals('{"status": "success"}', result.Response__c);
        System.assertEquals(200, result.StatusCode__c);
        System.assertEquals('Success', result.Status__c);
    }
    
    @isTest
    static void testTrackMethodWithRequestAndErrorMessage() {
      
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('https://mockendpoint.com/api');
        
        Track_API_Call__c trackObj = new Track_API_Call__c();
        Track_API_Call__c result = TrackApiUtil.track(trackObj, req, null, 'Error occurred');
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals('GET', result.Http_Method__c);
        System.assertEquals('https://mockendpoint.com/api', result.Request_URL__c);
        System.assertEquals('Error occurred', result.Error_Message__c);
        System.assertEquals('Error', result.Status__c);
    }
    
    @isTest
    static void testTrackMethodWithNullRequestAndResponse() {
        try {
            TrackApiUtil.track(null, null, null, null);
            
        } catch (TrackApiUtil.ArgumentException ex) {
        }
    }
    
    @isTest
    static void testTrackMethodWithLargeRequestBodyAndResponseBody() {
        String largeBody = String.join(new List<String>{'a'.repeat(10000), 'b'.repeat(10000)}, '');
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://mockendpoint.com/api');
        req.setBody(largeBody);
        
        
        String largeResponse = String.join(new List<String>{'1'.repeat(10000), '2'.repeat(10000)}, '');
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(200);
        resp.setBody(largeResponse);
        
      
        Track_API_Call__c trackObj = new Track_API_Call__c();
        Track_API_Call__c result = TrackApiUtil.track(trackObj, req, resp, null);
        
        System.assertNotEquals(null, result.Id);
        System.assertEquals(13107, result.Request__c.length(), 'Request body should be truncated to 13107 characters');
        System.assertEquals(13107, result.Response__c.length(), 'Response body should be truncated to 13107 characters');
    }
}