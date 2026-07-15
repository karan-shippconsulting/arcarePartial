public with sharing class DocsumoBSAnalytics {
  public static final Docsumo_Config__mdt configMetadata = [
          SELECT label, base_url__c, api_key__c
          FROM Docsumo_Config__mdt
          LIMIT 1
  ];
  @AuraEnabled
  public static String getBSAnalytics(String docId) {
    String url =
      configMetadata.base_url__c + '/api/v1/mew/usbs-analytics/' +
      docId +
      '/?date_format=mmddyy&mode=full';

    Integer maxRetries = 5;
    for (Integer i = 0; i < maxRetries; i++) {
      try {
        System.debug('fetching analytics. Call:' + 1);
        return DocsumoAPIUtils.fetchApi(url);
      } catch (CalloutException e) {
        System.debug('Callout exception: ' + e.getMessage());
      }
    }

    return null;
  }
}