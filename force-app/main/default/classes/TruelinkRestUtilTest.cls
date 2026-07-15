@isTest
public class TruelinkRestUtilTest {
    
    @isTest
    static void testSetParams() {
        // Test data setup
        Map<String, String> params = new Map<String, String>{
            'param1' => 'value1',
            'param2' => 'value2'
        };
        
        // Test method invocation
        TruelinkRestUtil util = new TruelinkRestUtil('mockURL');
        util.setParams(params);
        
        // Assertion
        System.assertEquals('?param1=value1&param2=value2&', util.paramString);
    }
    
    @isTest
    static void testSetEndPoint() {
        // Test data setup
        String endPoint = '/testEndpoint';
        
        // Test method invocation
        TruelinkRestUtil util = new TruelinkRestUtil('mockURL');
        util.setEndPoint(endPoint);
        
        // Assertion
        System.assertEquals('mockURL/testEndpoint', util.apiURL);
    }
    
    @isTest
    static void testSetMethod() {
        // Test data setup
        String method = 'GET';
        
        // Test method invocation
        TruelinkRestUtil util = new TruelinkRestUtil('mockURL');
        util.setMethod(method);
        
        // Assertion
        System.assertEquals(method, util.req.getMethod());
    }
    
    @isTest
    static void testSetBody() {
        // Test data setup
        String body = '{"key": "value"}';
        
        // Test method invocation
        TruelinkRestUtil util = new TruelinkRestUtil('mockURL');
        util.setBody(body);
        // Assertion
        System.assertEquals(body, util.req.getBody());
    }
    
    @isTest
    static void testTrackObj() {
        TruelinkRestUtil util = new TruelinkRestUtil('mockURL');
        util.getTrackObj();
        util.logData('test');
        TruelinkRestUtil.formatDate(system.today());
    }
    
}