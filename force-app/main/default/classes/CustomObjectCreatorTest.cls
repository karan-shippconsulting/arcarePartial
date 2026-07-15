@IsTest
public class CustomObjectCreatorTest {
  @IsTest
  static void testHasDifferenceWhenFieldNotInSF() {
    // Arrange
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails = new List<DocumentDetails.DocsumoFieldDetail>();
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Basic Information';
    detail.label = 'first name';
    fieldDetails.add(detail);

    List<String> fields = new List<String>{ 'some_other_field__c' };

    // Act
    Boolean result = CustomObjectCreator.hasDifferenceInSFAndDocsumo(
      fieldDetails,
      fields
    );

    // Assert
    System.assert(
      result,
      'Should return true when field is not found in SF map'
    );
  }

  @IsTest
  static void testNoDifferenceWhenAllFieldsExist() {
    // Arrange
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails = new List<DocumentDetails.DocsumoFieldDetail>();
    DocumentDetails.DocsumoFieldDetail detail1 = new DocumentDetails.DocsumoFieldDetail();
    detail1.section = 'Basic Information';
    detail1.label = 'first name';
    fieldDetails.add(detail1);

    List<String> fields = new List<String>{
      detail1.getSFColumnName()
    };

    // Act
    Boolean result = CustomObjectCreator.hasDifferenceInSFAndDocsumo(
      fieldDetails,
      fields
    );

    // Assert
    System.assert(
      !result,
      'Should return false when all fields exist in SF map'
    );
  }

  @IsTest
  static void testShouldReturnFalseIfDocsumoHasEmptyFields() {
    // Arrange
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails = new List<DocumentDetails.DocsumoFieldDetail>();
    List<String> fields = new List<String>{
      'ExistingField'
    };

    // Act
    Boolean result = CustomObjectCreator.hasDifferenceInSFAndDocsumo(
      fieldDetails,
      fields
    );

    // Assert
    System.assert(
      !result,
      'Should return false when field detail list is empty'
    );
  }

  @IsTest
  static void testShouldReturnTrueIfSalesforceObjectHasEmptyFieldsAndDocsumoHasSome() {
    // Arrange
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails = new List<DocumentDetails.DocsumoFieldDetail>();
    DocumentDetails.DocsumoFieldDetail detail = new DocumentDetails.DocsumoFieldDetail();
    detail.section = 'Basic Information';
    detail.label = 'first name';
    fieldDetails.add(detail);

    List<String> fields = new List<String>();

    // Act
    Boolean result = CustomObjectCreator.hasDifferenceInSFAndDocsumo(
      fieldDetails,
      fields
    );

    // Assert
    System.assert(result, 'Should return true when SF field type map is empty');
  }

  @IsTest
  static void testMultipleFieldsWithMixedExistence() {
    // Arrange
    List<DocumentDetails.DocsumoFieldDetail> fieldDetails = new List<DocumentDetails.DocsumoFieldDetail>();

    DocumentDetails.DocsumoFieldDetail detail1 = new DocumentDetails.DocsumoFieldDetail();
    detail1.section = 'Basic Information';
    detail1.label = 'first name';
    fieldDetails.add(detail1);

    //Absent field
    DocumentDetails.DocsumoFieldDetail detail2 = new DocumentDetails.DocsumoFieldDetail();
    detail2.section = 'Basic Information';
    detail2.label = 'last name';
    fieldDetails.add(detail2);

    List<String> fields = new List<String>{
      detail1.getSFColumnName(),
      'ExistingField2'
    };

    // Act
    Boolean result = CustomObjectCreator.hasDifferenceInSFAndDocsumo(
      fieldDetails,
      fields
    );

    // Assert
    System.assert(
      result,
      'Should return true when at least one field is not found in SF map'
    );
  }
}