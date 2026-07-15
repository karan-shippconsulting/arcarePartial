public with sharing class CustomObjectCreator {
  @InvocableMethod
  public static void createCustomObject(List<String> payload) {
    //TODO: validate payload
    String jsonString = payload[0];

    DocumentDetails.DocsumoDocumentDetail docDetails = getDocsumoDocDetail(
      jsonString
    );
    String objectName = docDetails.getSFObjectName();

    Map<String, List<String>> existingFields = getExistingFields(docDetails);
    System.debug('inserting records....');
    System.debug('queueing job...');
    System.enqueueJob(new DocsumoUpsertRecords(docDetails, existingFields));
  }

  private static DocumentDetails.DocsumoDocumentDetail getDocsumoDocDetail(
    String jsonString
  ) {
    Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(
      jsonString
    );

    //Extract meta_data from payload
    Map<String, Object> metaData = (Map<String, Object>) rootMap.get(
      'meta_data'
    );
    String docId = (String) metaData.get('doc_id');
    String docType = (String) metaData.get('type');

    //Fetch document details from Docsumo
    //We're fetching document details instead of using the data from webhook here.
    //The reason being, document details api returns the data type which we
    //use to create object definition on the fly
    DocumentDetails.DocsumoDocumentDetail docsumoDocDetail = DocumentDetails.fetch(
      docId,
      docType
    );

    //Add extra fields
    List<DocumentDetails.DocsumoFieldDetail> metadataFields = buildMetadataFields(
      metaData
    );
    docsumoDocDetail.fieldDetails.addAll(metadataFields);
    return docsumoDocDetail;
  }

  private static List<DocumentDetails.DocsumoFieldDetail> buildMetadataFields(
    Map<String, Object> metaData
  ) {
    String docId = (String) metaData.get('doc_id');
    String fileName = (String) metaData.get('title');
    String reviewUrl = ((String) metaData.get('review_url')) + '?client=true';
    String docStatus = (String) metaData.get('status');

    System.debug('doc status: ' + docStatus);

    List<DocumentDetails.DocsumoFieldDetail> metadataFields = new List<DocumentDetails.DocsumoFieldDetail>();

    DocumentDetails.DocsumoFieldDetail docIdField = new DocumentDetails.DocsumoFieldDetail();
    docIdField.label = 'Doc Id';
    docIdField.type = 'string';
    docIdField.value = docId;
    metadataFields.add(docIdField);

    DocumentDetails.DocsumoFieldDetail fileNameField = new DocumentDetails.DocsumoFieldDetail();
    fileNameField.label = 'File Name';
    fileNameField.type = 'string';
    fileNameField.value = fileName;
    metadataFields.add(fileNameField);

    DocumentDetails.DocsumoFieldDetail reviewUrlField = new DocumentDetails.DocsumoFieldDetail();
    reviewUrlField.label = 'Review Url';
    reviewUrlField.type = 'URL';
    reviewUrlField.value = reviewUrl;
    metadataFields.add(reviewUrlField);

    DocumentDetails.DocsumoFieldDetail docStatusField = new DocumentDetails.DocsumoFieldDetail();
    docStatusField.label = 'Doc Status';
    docStatusField.type = 'string';
    docStatusField.value = docStatus;
    metadataFields.add(docStatusField);

    return metadataFields;
  }

  public static Boolean hasDifferenceInSFAndDocsumo(
    List<DocumentDetails.DocsumoFieldDetail> fieldDetailList,
    List<String> existingFields
  ) {
    //This function returns true if salesforce object has all the fields present in docsumo details
    for (DocumentDetails.DocsumoFieldDetail fieldDetail : fieldDetailList) {
      System.debug('Checking if field exists:' + fieldDetail.getSFColumnName());
      if (!existingFields.contains(fieldDetail.getSFColumnName())) {
        return true;
      }
    }
    return false;
  }

  public static Map<String, List<String>> getExistingFields(
    DocumentDetails.DocsumoDocumentDetail docDetails
  ) {
    Map<String, List<String>> objectFields = new Map<String, List<String>>();
    List<String> fields = DocsumoUtils.fetchSFObjectDetails(
      docDetails.getSFObjectName()
    );

    objectFields.put(docDetails.getSFObjectName(), fields);

    for (DocumentDetails.DocsumoTable table : docDetails.tables) {
      List<String> tableFields = DocsumoUtils.fetchSFObjectDetails(
        table.getSFObjectName()
      );
      objectFields.put(table.getSFObjectName(), tableFields);
    }

    return objectFields;
  }
}