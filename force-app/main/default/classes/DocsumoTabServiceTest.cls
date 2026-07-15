@IsTest
public class DocsumoTabServiceTest {
  @IsTest
  static void testDoesTabExist() {
    // Create a test custom object
    String customObjectName = 'TestCustomObject__c';

    // Call the doesTabExist method
    Boolean tabExists = DocsumoTabService.doesTabExist(customObjectName);

    // Assert that the tab does not exist
    System.assertEquals(false, tabExists, 'Tab should not exist');
  }
}