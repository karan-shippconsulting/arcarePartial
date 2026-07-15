@IsTest
private class DocsumoRecordServiceTest {
  @TestSetup
  static void setupTestData() {
    // Create test Lead
    Lead testLead = new Lead(
      LastName = 'Test Lead',
      Company = 'Test Company',
      Email = 'test@example.com'
    );
    insert testLead;
  }

  private static DocumentDetails.DocsumoFieldDetail createTestField(String label, String type, String value, String section) {
        DocumentDetails.DocsumoFieldDetail field = new DocumentDetails.DocsumoFieldDetail();
        field.label = label;
        field.type = type;
        field.value = value;
        field.section = section;
        return field;
    }

    private static DocumentDetails.DocsumoDocumentDetail createTestDocDetail(
        String name, 
        String docId, 
        List<DocumentDetails.DocsumoFieldDetail> fields,
        List<DocumentDetails.DocsumoTable> tables
    ) {
        DocumentDetails.DocsumoDocumentDetail docDetail = new DocumentDetails.DocsumoDocumentDetail();
        docDetail.name = name;
        docDetail.docId = docId;
        docDetail.fieldDetails = fields != null ? fields : new List<DocumentDetails.DocsumoFieldDetail>();
        docDetail.tables = tables != null ? tables : new List<DocumentDetails.DocsumoTable>();
        return docDetail;
    }

  @IsTest
  static void testFindLeadsFromField() {

    Lead testLead = [SELECT Id, Email FROM Lead LIMIT 1];

    DocumentDetails.DocsumoFieldDetail emailField = createTestField(
          'Email',
          'text',
          testLead.Email,
          'Contact Information'
      );
      
      DocumentDetails.DocsumoDocumentDetail docDetail = createTestDocDetail(
          'Test Document',
          'TEST-DOC-001',
          new List<DocumentDetails.DocsumoFieldDetail>{emailField},
          null
      );
      
    String docsumoField = 'Email';
    String leadField = 'Email';

    Test.startTest();

    List<Lead> results = DocsumoRecordService.findLeadsFromField(
      docDetail,
      docsumoField,
      leadField
    );

    Test.stopTest();

    // Assert the results
    System.assertNotEquals(null, results);
  }

    
}