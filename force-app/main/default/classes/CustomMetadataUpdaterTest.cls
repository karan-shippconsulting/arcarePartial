@isTest
public class CustomMetadataUpdaterTest {

    // Mock class to simulate Metadata.DeployCallback
    class MockDeployCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            // Mocking the deployment callback with success
            result.status = Metadata.DeployStatus.Succeeded;
            result.errorMessage = '';
        }
    }
    
    @isTest
    public static void testHandleErrorScenario() {
        // This tests the error handling within insertMetadata method
        List<CustomMetadataUpdater.ConfigData> testConfigDataList = new List<CustomMetadataUpdater.ConfigData>();
        CustomMetadataUpdater.ConfigData configData = new CustomMetadataUpdater.ConfigData();
        configData.masterLabel = 'Test Config Error';
        configData.apiKey = 'APIKEYERROR';
        
        testConfigDataList.add(configData);
        
        // Try to simulate the error when Metadata cannot be deployed from within a test
        Test.startTest();
        
        try {
            CustomMetadataUpdater.updateDocsumoConfig(testConfigDataList);
        } catch (Exception e) {
            // Expecting the custom DocsumoConfigException to be thrown
            System.assert(e instanceof CustomMetadataUpdater.DocsumoConfigException, 
                'Expected DocsumoConfigException to be thrown');
            System.assert(e.getMessage().contains('Failed to create Docsumo Config'));
        }

        Test.stopTest();
    }
}