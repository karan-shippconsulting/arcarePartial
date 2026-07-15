@IsTest
public class DocsumoBSAnalyticsTest {
  @IsTest
  static void testGetBSAnalytics() {
    // Set up a mock HTTP response
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

    // Call the method to test
    String result = DocsumoBSAnalytics.getBSAnalytics('12345');

    // Verify the result
    System.assertEquals('{"example":"test"}', result);
  }

  // Mock HTTP response class
  public class MockHttpResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"example":"test"}');
      res.setStatusCode(200);
      return res;
    }
  }
}