public with sharing class CustomMetadataUpdater {
  public with sharing class ConfigData {
    @InvocableVariable
    public string masterLabel;
    @InvocableVariable
    public string apiKey;
  }

  public class DocsumoConfigException extends Exception {
  }

  // Callback class to handle deployment result
  public class DocsumoConfigCallback implements Metadata.DeployCallback {
    public void handleResult(
      Metadata.DeployResult result,
      Metadata.DeployCallbackContext context
    ) {
      if (result.status == Metadata.DeployStatus.Succeeded) {
        System.debug('Successfully deployed Docsumo Config');
      } else {
        System.debug('Deploy failed: ' + result.errorMessage);
      }
    }
  }

  @TestVisible
  private static void insertMetadata(String recordName, String apiKey) {
    try {
      // Create Custom Metadata record
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
      customMetadata.fullName = 'Docsumo_Config__mdt.' + recordName;
      customMetadata.label = recordName;

      // Set the api_key field value
      Metadata.CustomMetadataValue apiKeyField = new Metadata.CustomMetadataValue();
      apiKeyField.field = 'api_key__c';
      apiKeyField.value = apiKey;
      customMetadata.values.add(apiKeyField);

      // Create deployment container
      Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
      mdContainer.addMetadata(customMetadata);

      // Deploy the container
      Id jobId = Metadata.Operations.enqueueDeployment(
        mdContainer,
        new DocsumoConfigCallback()
      );

      System.debug('Deployment Job ID: ' + jobId);
    } catch (Exception e) {
      System.debug('Error creating Docsumo Config: ' + e.getMessage());
      throw new DocsumoConfigException(
        'Failed to create Docsumo Config: ' + e.getMessage()
      );
    }
  }

  @InvocableMethod
  public static void updateDocsumoConfig(List<ConfigData> configDataList) {
    for (ConfigData data : configDataList) {
      System.debug('received data: ' + data.masterLabel + '\t' + data.apiKey);

      insertMetadata(data.masterLabel, data.apiKey);
    }
  }
}