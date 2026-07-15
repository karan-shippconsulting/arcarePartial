public with sharing class DocsumoUtils {
  public static String buildSFObjectName(String name) {
    return 'DS_' + DocsumoUtils.sanitizeFieldName(name);
  }

  public static String sanitizeFieldName(String fieldName) {
    //converts fieldName to salesforce compatible field name
    fieldName = fieldName.replaceAll('^\\d+', '')
      .replaceAll('[ /&_]+', '_')
      .toLowerCase();
    if (fieldName.length() > 20) {
      fieldName = fieldName.substring(0, 20);
    }

    return fieldName.replaceAll('[_]+', '_')
        .replaceAll('^\\_+', '')
        .replaceAll('\\_+$', '') + '__c';
  }

  public static Date parseDate(String dateStr) {
    //NOTE: assumed format: dd/mm/yyyy
    String[] values = dateStr.split('/');
    try {
      return Date.newInstance(
        Integer.valueOf(values[2]),
        Integer.valueOf(values[1]),
        Integer.valueOf(values[0])
      );
    } catch (Exception ex) {
      System.debug('error while parsing date. Date: ' + dateStr);
      return null;
    }
  }

  public static Decimal parseDecimal(String value) {
    try {
      String strValue = value.trim().replaceAll('\\$', '');
      return strValue == '' ? 0.0 : Decimal.valueOf(strValue);
    } catch (Exception ex) {
      return 0.0;
    }
  }

  public static List<String> fetchSFObjectDetails(String objectName) {
    System.debug('fetching fields for object ' + objectName);
    SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);

    if (sObjectType == null) {
      System.debug('Object ' + objectName + ' does not exist.');
      return null;
    }

    Map<String, Schema.SObjectField> fields = sObjectType.getDescribe()
      .fields.getMap();

    Set<String> existingFields = new Set<String>();
    for (String field : fields.keySet()) {
      //consider only the custom fields
      if (field.endsWith('__c')) {
        existingFields.add(field);
      }
    }

    return new List<String>(existingFields);
  }
}