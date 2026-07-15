public with sharing class CustomMetadaChecker {
  public with sharing class ConfigData {
    @InvocableVariable
    public String label;
  }

  @InvocableMethod(
    Label='Checks if api key already exists'
    Description='Returns true or false based on if api key with given label already exists'
  )
  public static List<Boolean> checkIfMetadataExists(
    List<ConfigData> configDataList
  ) {
    List<Boolean> results = new List<Boolean>();
    for (ConfigData data : configDataList) {
      System.debug('config: ' + data.label);

      List<Docsumo_Config__mdt> configs = [
        SELECT api_key__c
        FROM Docsumo_Config__mdt
        WHERE label = :data.label
        LIMIT 1
      ];

      Boolean result =
        !configs.isEmpty() &&
        (configs[0].api_key__c != null &&
        configs[0].api_key__c.trim() != '');

      results.add(result);
    }

    return results;
  }
}