/*
 * @description: The class serves as a helper for making HTTP GET and POST requests to the docsumo application
 */

public with sharing class DocsumoAPIUtils {
  public static final Docsumo_Config__mdt configMetadata = [
    SELECT label, base_url__c, api_key__c
    FROM Docsumo_Config__mdt
    LIMIT 1
  ];

  public static String fetchApi(String url) {
    // Initialize HTTP Request
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setHeader('accept', 'application/json');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('apikey', configMetadata.api_key__c);

    Http http = new Http();
    HttpResponse res;

    try {
      // Send the HTTP request
      res = http.send(req);

        // Check if the response status code is 200 OK
        if (res.getStatusCode() == 200 && res.getStatusCode() < 300) {
            return res.getBody(); // Return response body on success
        } else {
            // Log the error and throw an exception if the status code is not successful
            String errorMessage = 'HTTP Error: ' + res.getStatusCode() + ' - ' + res.getStatus();
            System.debug(errorMessage);
            throw new CalloutException(errorMessage);
        }

    } catch (CalloutException ce) {
      // Catch callout-specific exceptions and log the error
      System.debug('Callout failed: ' + ce.getMessage());
      throw ce; // Rethrow exception for higher-level handling
    } catch (Exception e) {
      // Catch any other unexpected exceptions (network issues, timeouts, etc.)
      String exceptionMessage =
        'Unexpected exception during API request: ' + e.getMessage();
      System.debug(exceptionMessage);
      throw new CalloutException(exceptionMessage); // Throw a general exception for unknown errors
    }
  }

  public static String post(String url, Map<String, Object> body) {
    // Initialize the HTTP Request
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('POST');
    req.setHeader('accept', 'application/json');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('apikey', configMetadata.api_key__c);

    req.setBody(JSON.serialize(body));

    Http http = new Http();
    HttpResponse res;

    try {
      res = http.send(req);

      // Check if the response status code is in the successful range (200-299)
      if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
        return res.getBody();
      } else {
        // Log the error and throw an exception if the status code is not successful
        String errorMessage =
          'HTTP Error: ' +
          res.getStatusCode() +
          ' - ' +
          res.getStatus();
        System.debug(errorMessage);
        throw new CalloutException(errorMessage);
      }
    } catch (CalloutException ce) {
      // Catch Salesforce CalloutException and log the error
      System.debug('Callout failed: ' + ce.getMessage());
      throw ce;
    } catch (Exception e) {
      // Catch any other exceptions, including issues with HTTP connection, timeouts, etc.
      String exceptionMessage =
        'Exception during HTTP callout: ' + e.getMessage();
      System.debug(exceptionMessage);
      throw new CalloutException(exceptionMessage);
    }
  }
}