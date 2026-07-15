/*
 * @description: This class sends the uploaded files to the Docsumo app for processing.
 * @reference : This class is called from the DS Document Process Flow.
 */

public with sharing class DocsumoAPIController {
  public static final Docsumo_Config__mdt configMetadata = [
          SELECT label, base_url__c, api_key__c
          FROM Docsumo_Config__mdt
          LIMIT 1
  ];

  public class FileDetails {
    @InvocableVariable(required=true)
    public List<String> contentVersionIds; //Content Version Id of the file uploaded from the flow

    @InvocableVariable(required=true)
    public String documentCategory;

    @InvocableVariable
    public String recordId; //recordId of the record that the flow is in
  }

  // Details we initially receive after sending the file to the app.
  // Received before processing
  public class DocumentDetails {
    public string user_id;
    public string title;
    public String email;
    public String review_url;
    public String doc_id;
    public string type;
    public string status;
  }

  public class Document {
    public List<DocumentDetails> document;
  }

  public class Response {
    @InvocableVariable(label='output')
    public Document data;
  }

  @InvocableMethod(
    Label='Docsumo Document AI'
    Description='Post the uploaded file(s) to the docsumo application for processing'
    Category='Docsumo'
  )
  //TODO : Handle multiple file uploads.
  //Note : Even though we won't be sending multiple files to the app, it's still recommended to be able to handle multiple files.
  public static List<List<String>> sendFileForProcessing(
    List<FileDetails> fileDetailsList
  ) {
    if (fileDetailsList.isEmpty()) {
      return new List<List<String>>();
    }

    // Callout URL
    String url = configMetadata.base_url__c + '/api/v1/eevee/apikey/upload/custom/';

    FileDetails fileDetails = fileDetailsList.get(0);
    List<List<String>> sObjectsRecordIdsList = new List<List<String>>();
    List<String> sObjectRecordIdList = new List<String>();

    // Retrieve file content from each file uploaded.
    List<ContentVersion> fileVersions = [
      SELECT Id, Title, VersionData, ContentDocumentId, FileType
      FROM ContentVersion
      WHERE Id IN :fileDetails.contentVersionIds
      LIMIT 1
    ];

    List<String> base64Contents = new List<String>();

    //TODO : Check if the file size is too large
    //Appending files with large size to the list could cause HEAP SIZE error.
    for (ContentVersion fileVersion : fileVersions) {
      base64Contents.add(EncodingUtil.base64Encode(fileVersion.VersionData));
    }

    // Add the file content as Blob
    String base64Content = base64Contents[0];

    // Prepare request body with base64 content
    Map<String, Object> requestBody = new Map<String, Object>{
      'file' => base64Content,
      'type' => fileDetails.documentCategory,
      'file_type' => 'base64',
      'review_token' => false,
      'filename' => fileVersions[0].Title +
      '.' +
      fileVersions[0].FileType
    };

    String responseBody = DocsumoAPIUtils.post(url, requestBody);

    Response response = (Response) JSON.deserialize(
      responseBody,
      Response.class
    );

    DocumentDetails documentDetails = response.data.document[0];
    String reviewUrl = documentDetails.review_url + '?&client=true';

    SObject records = createRecordsBasedOnResponse(
      fileDetails.documentCategory,
      documentDetails.doc_id,
      documentDetails.status,
      reviewUrl,
      fileDetails.recordId
    );
    Database.insert(records);

    if (records.Id != null) {
      attachFileToCreatedObject(fileVersions[0].ContentDocumentId, records.Id);
    }

    if (!String.isBlank(fileDetails.recordId)) {
      attachFileToParentObject(
        fileVersions[0].ContentDocumentId,
        fileDetails.recordId
      );
    }

    sObjectRecordIdList.add(records.Id);
    sObjectsRecordIdsList.add(sObjectRecordIdList);

    return sObjectsRecordIdsList;
  }

  // Create records based on response
  private static SObject createRecordsBasedOnResponse(
    String documentCategory,
    String docsumoDocumentId,
    String docsumoStatus,
    String reviewUrl,
    String recordId
  ) {
    String objectName = DocsumoUtils.buildSFObjectName(documentCategory);

    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
    SObject record = objectType.newSObject();

    // We can add the mapping in the custom metadata and enable these fields as primary.
    record.put('doc_id__c', docsumoDocumentId);
    record.put('doc_status__c', docsumoStatus.capitalize());
    record.put('review_url__c', reviewUrl);
    record.put('Lead__c', recordId);

    return record;
  }

  /*
   * @description : Attach the file uploaded by the user to the record that got created from the response recieved after sending the file for processing to the docsumo app.
   */
  private static void attachFileToCreatedObject(
    Id ContentDocumentId,
    String recordId
  ) {
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = ContentDocumentId;
    cdl.LinkedEntityId = recordId;
    insert cdl;
  }

  /*
   * @description : Attach the file uploaded by the user to the record that the flow component is a part of.
   */
  private static void attachFileToParentObject(
    Id ContentDocumentId,
    String recordId
  ) {
    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.ContentDocumentId = ContentDocumentId;
    cdl.LinkedEntityId = recordId;
    insert cdl;
  }
}