public without sharing class DocsumoRecordService {
  public static SObject buildCustomObjectRecord(
    String objectName,
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails,
    List<String> existingFields
  ) {
    SObject customObjectRecord = Schema.getGlobalDescribe()
      .get(objectName)
      .newSObject();

    for (DocumentDetails.DocsumoFieldDetail fieldDetail : fieldDetails) {
      String columnName = fieldDetail.getSFColumnName();
      if (!existingFields.contains(columnName)) {
        continue;
      }

      if (fieldDetail.type.toLowerCase() == 'date') {
        customObjectRecord.put(
          columnName,
          DocsumoUtils.parseDate(fieldDetail.value)
        );
      } else if (fieldDetail.type.toLowerCase() == 'number') {
        Decimal value = DocsumoUtils.parseDecimal(fieldDetail.value);
        customObjectRecord.put(columnName, value);
      } else {
        String value = fieldDetail.value;

        if (value != null && value.length() > 100) {
          value = value.substring(0, 99);
        }
        customObjectRecord.put(columnName, value);
      }
    }

    return customObjectRecord;
  }

  public static void upsertTableRecord(
    DocumentDetails.DocsumoTable table,
    String parentObjName,
    Id parentId,
    List<String> existingFields
  ) {
    String objectName = table.getSFObjectName();

    try {
      deleteTableRecordsIfExists(objectName, parentObjName, parentId);

      List<SObject> tableRecords = new List<SObject>();
      for (DocumentDetails.DocsumoTableRow row : table.rows) {
        SObject customObjectRecord = buildCustomObjectRecord(
          objectName,
          row.cells,
          existingFields
        );

        customObjectRecord.put(parentObjName, parentId);
        tableRecords.add(customObjectRecord);
      }

      insert tableRecords;
    } catch (DmlException ex) {
      System.debug(ex.getMessage());
      throw ex;
    }
  }

  public static void deleteTableRecordsIfExists(
    String tableName,
    String parentObjName,
    String parentId
  ) {
    try {
      List<SObject> tableRecords = findTableRecordsByParentId(
        tableName,
        parentObjName,
        parentId
      );
      delete tableRecords;
    } catch (DmlException ex) {
      System.debug('error while deleting records');
      throw ex;
    }
  }

  public static List<SObject> findTableRecordsByParentId(
    String tableName,
    String parentObjName,
    String parentId
  ) {
    String query =
      String.escapeSingleQuotes('select Id from ') +
      tableName +
      String.escapeSingleQuotes(' where ') +
      parentObjName +
      String.escapeSingleQuotes('= :parentId');
    return Database.query(query);
  }

  public static List<Lead> findLeadsFromField(
    DocumentDetails.DocsumoDocumentDetail docsumoDocDetail,
    String docsumoField,
    String leadField
  ) {
    String matchFieldName = null;
    String objectName = docsumoDocDetail.getSFObjectName();

    for (
      DocumentDetails.DocsumoFieldDetail fieldDetail : docsumoDocDetail.fieldDetails
    ) {
      if (
        fieldDetail.getSFColumnName()
          .toLowerCase()
          .equals(docsumoField.toLowerCase())
      ) {
        matchFieldName = String.valueOf(fieldDetail.value);
        break;
      }
    }

    // If we have both docId and buyerName, create the relationship
    if (
      String.isNotBlank(docsumoDocDetail.docId) &&
      String.isNotBlank(matchFieldName)
    ) {
      try {
        String query =
          'SELECT Id FROM Lead WHERE ' +
          leadField +
          ' = :matchFieldName LIMIT 1';
        System.debug('Query : ' + query);
        List<Lead> matchingLeads = Database.query(query);

        System.debug(
          'Found matching leads for document: ' +
            docsumoDocDetail.docId +
            ' Matching leads: ' +
            matchingLeads
        );
        return matchingLeads;
      } catch (Exception e) {
        System.debug('Error creating relationship: ' + e.getMessage());
        // Consider whether to throw the exception or handle it differently
      }
    }

    System.debug(
      'Missing required fields - DocId: ' +
        docsumoDocDetail.docId +
        ', Buyer Name: ' +
        matchFieldName
    );
    return new List<Lead>();
  }

  public static Lead findLeadsFromConfig(
    DocumentDetails.DocsumoDocumentDetail docsumoDocDetail,
    String docType
  ) {
    List<Docsumo_Lead_Mapping__mdt> fieldMappings = [
      SELECT Document_Field__c, Lead_Field__c
      FROM Docsumo_Lead_Mapping__mdt
      WHERE Document_Type__c = :docType.toLowerCase()
      LIMIT 1
    ];

    if (fieldMappings.isEmpty()) {
      System.debug('No field mapping configuration found for: ' + docType);
      return null;
    }

    Docsumo_Lead_Mapping__mdt fieldMapping = fieldMappings[0];
    List<Lead> leads = findLeadsFromField(
      docsumoDocDetail,
      fieldMapping.Document_Field__c,
      fieldMapping.Lead_Field__c
    );

    if (leads.isEmpty()) {
      return null;
    }
    // TODO: Update how to match when multiple leads are found.
    return leads[0];
  }

  public static SObject getRecordByExistingId(
    String objectName,
    String externalIdField,
    String externalIdValue
  ) {
    String query =
      'select Id, Lead__c from ' +
      objectName +
      ' where ' +
      externalIdField +
      ' = :externalIdValue limit 1';

    List<SObject> existingRecords = Database.query(query);
    if (!existingRecords.isEmpty()) {
      System.debug('existing record found.');
      return existingRecords[0];
    }
    return null;
  }

  public static void upsertRecord(
    DocumentDetails.DocsumoDocumentDetail docsumoDocDetail,
    Map<String, List<String>> existingFields
  ) {
    String objectName = docsumoDocDetail.getSFObjectName();
    System.debug('fetching object :' + objectName);

    SObject customObjectRecord = buildCustomObjectRecord(
      objectName,
      docsumoDocDetail.fieldDetails,
      existingFields.get(objectName)
    );

    System.debug('custom object record: ');
    System.debug(customObjectRecord);

    String docIdField = 'doc_id__c';
    String docIdValue = docsumoDocDetail.docId;
    String doc_type = docsumoDocDetail.name;

    try {
      SObject existingRecord = getRecordByExistingId(
        objectName,
        docIdField,
        docIdValue
      );
      if (existingRecord == null) {
        //check if record exists in auto classify table
        SObject autoClassifyObject = DocsumoAutoClassifyAI.getRecordByDocId(
          docIdValue
        );

        if (
          autoClassifyObject != null &&
          autoClassifyObject.get('Lead__c') != null
        ) {
          customObjectRecord.put('Lead__c', autoClassifyObject.get('Lead__c'));
        } else {
          System.debug('inserting new record');
          Lead lead = findLeadsFromConfig(docsumoDocDetail, doc_type);
          if (lead != null) {
            customObjectRecord.put('Lead__c', lead.Id);
          }
        }

        insert customObjectRecord;
      } else {
        System.debug('updating existing record: ' + existingRecord.Id);
        customObjectRecord.put('Id', existingRecord.Id);

        //while updating only search for the lead if Lead doesn't exist in record
        if (existingRecord.get('Lead__c') == null) {
          Lead lead = findLeadsFromConfig(docsumoDocDetail, doc_type);
          System.debug('Found Matching Lead: ' + lead);
          if (lead != null) {
            customObjectRecord.put('Lead__c', lead.Id);
          }
        }
        update customObjectRecord;
      }
    } catch (DmlException e) {
      System.debug('Error inserting record: ' + e.getMessage());
    }

    //Insert table data
    String parentId = customObjectRecord.Id;
    for (DocumentDetails.DocsumoTable table : docsumoDocDetail.tables) {
      System.debug('inserting data for table ' + table.getSFObjectName());
      upsertTableRecord(
        table,
        objectName,
        parentId,
        existingFields.get(table.getSFObjectName())
      );
    }
  }
}