/**
* @File Name : FlowLookupControllerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 16, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 16, 2025 |   | Initial Version
**/

@IsTest
public with sharing class FlowLookupControllerTest {
    @TestSetup
    static void setupData() {
        List<Account> accts = new List<Account>();
        accts.add(new Account(Name = 'MicroTech Industries', AccountNumber = 'A1001'));
        accts.add(new Account(Name = 'MacroTech Systems', AccountNumber = 'A1002'));
        accts.add(new Account(Name = 'Micron Labs', AccountNumber = 'A1003'));
        insert accts;
    }

    @IsTest
    static void testEqualsOperator() {
        Test.startTest();
        FlowLookupController.searchRecords(
            'Account',
            'Name',
            '=',
            'MicroTech Industries',
            'Name'
        );
        Test.stopTest();
    }

    @IsTest
    static void testContainsOperator() {
        Test.startTest();
        FlowLookupController.searchRecords(
            'Account',
            'Name',
            'Contains',
            'Micro',
            'Name'
        );
        Test.stopTest();
    }

    @IsTest
    static void testStartsWithOperator() {
        Test.startTest();
        FlowLookupController.searchRecords(
            'Account',
            'Name',
            'StartsWith',
            'Macro',
            'Name'
        );
        Test.stopTest();
    }

    @IsTest
    static void testDisplayFieldAccountNumber() {
        Test.startTest();
        FlowLookupController.searchRecords(
            'Account',
            'Name',
            'StartsWith',
            'Micro',
            'AccountNumber'
        );
        Test.stopTest();
    }

    @IsTest
    static void testInvalidInputs() {
        Test.startTest();
        FlowLookupController.searchRecords(
            'NotARealObject', 'Name', '=', 'X', 'Name');
        FlowLookupController.searchRecords(
            'Account', 'NotARealField', '=', 'X', 'Name');
        FlowLookupController.searchRecords(
            'Account', 'Name', '=', 'MicroTech Industries', 'NotARealField');
        Test.stopTest();
    }
}