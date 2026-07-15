public class DocsumoRecordInsertQueueable implements Queueable {
  private final String leadRecId;
  private final String docId;
  private final String objectName;
  private final String ContentVersionId;
  private final String Title;
  private final String Status;
  private final String reviewURL;

  public DocsumoRecordInsertQueueable(String leadRecId, String docId, String Status, String Title, String reviewURL, String objectName, String ContentVersionId) {
    this.leadRecId = leadRecId;
    this.docId = docId;
    this.objectName = objectName;
    this.ContentVersionId = ContentVersionId;
    this.Status = Status;
    this.Title = Title;
    this.reviewURL = reviewURL;
  }

  public void execute(QueueableContext context) {
    // Get the global describe map of all objects
    Map<String, Schema.SObjectType> objectMap = Schema.getGlobalDescribe();

    // Check if the object exists in the map (i.e., Docsumo_us_license__c)
    if (objectMap.containsKey(objectName) && (this.leadRecId != null || String.isNotBlank(this.leadRecId))) {
      SObject newRecord = objectMap.get(objectName).newSObject();
      newRecord.put('Lead__c', leadRecId); // Setting the lookup field value (Lead__c)
      newRecord.put('Doc_Id__c', docId);
      newRecord.put('doc_status__c', Status);
      newRecord.put('file_name__c', Title);
      newRecord.put('review_url__c', reviewURL);

      // Insert the record into the database
      insert newRecord;

      ContentVersion contentVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id =: this.ContentVersionId

            LIMIT 1
        ];

      ContentDocumentLink cdl = new ContentDocumentLink();
      cdl.ContentDocumentId = contentVersion.ContentDocumentId;
      cdl.LinkedEntityId = newRecord.Id;
      insert cdl;
    }
  }
}