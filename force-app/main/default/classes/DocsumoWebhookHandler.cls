@RestResource(UrlMapping='/webhook-handler/')
global class DocsumoWebhookHandler {
  private static final Docsumo_Config__mdt configMetadata = [
    SELECT label, api_key__c, Auth_Token__c
    FROM Docsumo_Config__mdt
    LIMIT 1
  ];

  @HttpPost
  global static void handleWebhook() {
    try {
      // Get and print the webhook payload
      RestRequest req = RestContext.request;

      if (!isValidToken(req, configMetadata.Auth_Token__c)) {
        RestContext.response.statusCode = 400;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(
          '{"status": "fail", "message": "authentication error"}'
        );
        System.debug('could not verify the token. Authentication error.');
        return;
      }

      String requestBody = req.requestBody.toString();
      System.debug('Received webhook payload: ' + requestBody);

      //Experimental: invoke flow
      Map<String, Object> flowInputs = new Map<String, Object>();
      flowInputs.put('docsumo_webhook_payload', requestBody);

      Flow.Interview.Docusmo_Create_Object_and_Record_Flow flow = new Flow.Interview.Docusmo_Create_Object_and_Record_Flow(
        flowInputs
      );
      System.debug('flow started successfully');
      flow.start();

      // Send success response
      RestContext.response.statusCode = 200;
      RestContext.response.addHeader('Content-Type', 'application/json');
      RestContext.response.responseBody = Blob.valueOf('{"status": "success"}');
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
      RestContext.response.statusCode = 400;
      String errMessage = 'Err: ' + e.getMessage();
      RestContext.response.responseBody = Blob.valueOf(
        '{"status": "fail", "message":"' + errMessage + '"}'
      );
    }
  }

  @TestVisible
  private static Boolean isValidToken(RestRequest req, String configAuthToken) {
    Map<String, String> headers = req.headers;

    String authToken = headers.get('x-custom-auth');
    return !(authToken == null || configAuthToken != authToken);
  }
}