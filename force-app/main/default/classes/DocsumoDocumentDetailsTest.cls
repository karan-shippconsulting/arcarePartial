@IsTest
private class DocsumoDocumentDetailsTest {
  @IsTest
  static void testGetSFLabel_WithSection() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Invoice Details';
    detail.label = 'Amount Due';

    // Act
    String result = detail.getSFLabel();

    // Assert
    System.assertEquals('ID Amount Due', result);
  }

  @IsTest
  static void testGetSFLabel_WithoutSection() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.label = 'Amount Due';

    // Act
    String result = detail.getSFLabel();

    // Assert
    System.assertEquals('Amount Due', result);
  }

  @IsTest
  static void testGetSFLabel_WithSpecialCharacters() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Invoice/Details';
    detail.label = 'Amount_Due&Tax';

    // Act
    String result = detail.getSFLabel();

    // Assert
    System.assertEquals('I Amount Due Tax', result);
  }

  @IsTest
  static void testGetSFColumnName_WithSection() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Invoice Details';
    detail.label = 'Amount Due';

    // Act
    String result = detail.getSFColumnName();

    // Assert
    System.assertEquals('id_amount_due__c', result);
  }

  @IsTest
  static void testGetSFColumnName_WithoutSection() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.label = 'Amount Due';

    // Act
    String result = detail.getSFColumnName();

    // Assert
    System.assertEquals('amount_due__c', result);
  }

  @IsTest
  static void testGetSFColumnName_WithSpecialCharacters() {
    // Arrange
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Invoice/Details Section';
    detail.label = '123 Amount_Due&Tax';

    // Act
    String result = detail.getSFColumnName();

    // Assert
    System.assertEquals('is_123_amount_due_ta__c', result);
  }

  // Test for sanitizeFieldName utility method
  @IsTest
  static void testSanitizeFieldName() {
    // Test various scenarios
    System.assertEquals(
      'test_field__c',
      DocsumoUtils.sanitizeFieldName('Test Field')
    );

    System.assertEquals(
      'amount_due__c',
      DocsumoUtils.sanitizeFieldName('123Amount Due')
    );

    System.assertEquals(
      'invoice_details__c',
      DocsumoUtils.sanitizeFieldName('Invoice/Details')
    );

    System.assertEquals(
      'test_field__c',
      DocsumoUtils.sanitizeFieldName('_Test_Field_')
    );

    System.assertEquals(
      'test_field__c',
      DocsumoUtils.sanitizeFieldName('Test&Field')
    );
  }
}