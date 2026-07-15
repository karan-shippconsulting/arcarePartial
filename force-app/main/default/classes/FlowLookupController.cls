/**
* @File Name : FlowLookupController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 15, 2025 |   | Initial Version
**/

/**
* @File Name : FlowLookupController.cls
* @Description : Dynamic lookup for Screen Flow component
* @Author :
* @Last Modified On : September 15, 2025
**/
public with sharing class FlowLookupController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchRecords(
        String objectApiName,
        String fieldApiName,
        String operator,
        String searchValue,
        String displayFieldApiName
    ) {
        List<Map<String, String>> results = new List<Map<String, String>>();

        // Basic guard clauses
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName) || String.isBlank(operator)) {
            return results;
        }

        // Validate object
        Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
        if (sType == null) return results;

        Schema.DescribeSObjectResult sobjDesc = sType.getDescribe();

        // Validate search field
        if (!sobjDesc.fields.getMap().containsKey(fieldApiName)) return results;

        // Validate display field, fallback to Name
        if (String.isBlank(displayFieldApiName) || !sobjDesc.fields.getMap().containsKey(displayFieldApiName)) {
            displayFieldApiName = 'Name';
        }

        // Build operator/value
        String soqlOperator;
        String boundValue = searchValue == null ? '' : searchValue.trim();

        if (operator == '=') {
            soqlOperator = ' = ';
        } else if (operator == 'Contains') {
            soqlOperator = ' LIKE ';
            boundValue = '%' + boundValue + '%';
        } else if (operator == 'StartsWith') {
            soqlOperator = ' LIKE ';
            boundValue = boundValue + '%';
        } else {
            soqlOperator = ' = ';
        }

        // Build SOQL
        String soql =
            'SELECT Id, ' + displayFieldApiName +
            ' FROM ' + objectApiName +
            ' WHERE ' + fieldApiName + soqlOperator + ':boundValue ' +
            ' ORDER BY ' + displayFieldApiName +
            ' LIMIT 50';

        try {
            List<SObject> rows = Database.query(soql);
            for (SObject rec : rows) {
                Map<String, String> row = new Map<String, String>();
                row.put('Id', (String) rec.get('Id'));
                row.put('Label',
                    rec.get(displayFieldApiName) != null
                        ? String.valueOf(rec.get(displayFieldApiName))
                        : '(no value)'
                );
                results.add(row);
            }
        } catch (Exception ex) {
            System.debug('FlowLookupController query failed: ' + ex.getMessage());
            // Return empty list on failure
        }

        return results;
    }
}