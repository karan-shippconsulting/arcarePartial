public without sharing class DocsumoAutoClassifyAI {
  public static SObject getRecordByDocId(String docId) {
    try {
      /*String query = 'select Id, Name, Lead__c from ds_auto_classify_ai__c where doc_id__c = :docId limit 1';

      List<SObject> existingObjects = Database.query(query);

      if (!existingObjects.isEmpty()) {
        return existingObjects[0];
      }*/
      return null;
    } catch (DmlException e) {
      System.debug('error while fetching data.');
      System.debug(e.getMessage());
      return null;
    }
  }
}