/**
 * @File Name : DocsumoFlowRecordQueryController
 * @Description : Query the records created using the response from the docsumo application
 * @Author : Roman Regmi
 * @Last Modified By :
 * @Last Modified On : January 20, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | January 20, 2025 |   | Initial Version
 **/

public without sharing class DocsumoFlowRecordQueryController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> queryCreatedRecords(List<String> recIds) {
    Map<String, Object> result = new Map<String, Object>();

    if (recIds == null || recIds.isEmpty()) {
      result.put('records', new List<SObject>());
      result.put('fields', new List<String>());
      return result;
    }

    // Get the object type from the record ID
    Id recId = recIds.get(0);
    String sObjName = recId.getSObjectType().getDescribe().getName();

    // Get the fields dynamically from the object
    List<String> fieldNames = new List<String>();

    // Make this dynamic, so it can be used for any object
    fieldNames.add('Name');
    fieldNames.add('doc_id__c');
    fieldNames.add('doc_status__c');
    fieldNames.add('review_url__c');

    // Construct the SOQL query
    String query =
      'SELECT Id, ' +
      String.join(fieldNames, ', ') +
      ' FROM ' +
      sObjName +
      ' WHERE Id IN :recIds';

    // Execute the query and get the records
    List<SObject> sObjRec = Database.query(query);

    // Add the queried records and the field names to the result map
    result.put('records', sObjRec);
    result.put('fields', fieldNames);

    return result;
  }
}