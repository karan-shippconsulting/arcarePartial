@IsTest
public class CustomMetadaCheckerTest {
  @IsTest
  static void testCheckIfMetadataExists() {
    // Create test data
    List<CustomMetadaChecker.ConfigData> configDataList = new List<CustomMetadaChecker.ConfigData>();
    CustomMetadaChecker.ConfigData configData = new CustomMetadaChecker.ConfigData();
    configData.label = 'TestLabel';
    configDataList.add(configData);

    // Call the method to test
    List<Boolean> results = CustomMetadaChecker.checkIfMetadataExists(
      configDataList
    );

    // Assert the results
    System.assertEquals(1, results.size());
    System.assertEquals(false, results[0]);
  }
}