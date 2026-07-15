@IsTest
private class remainderPersonTableControllerTest {

    @TestSetup
    static void setupData() {
        Contact beneficiaryContact = new Contact(
            FirstName = 'Test',
            LastName = 'Beneficiary',
            Email = 'test.beneficiary@example.com'
        );
        insert beneficiaryContact;

        // 3) Closing__c connected to the Trust (field: Trust__c)
        Closing__c closingRec = new Closing__c(
            Name = 'Test Closing',
            Beneficiary__c = beneficiaryContact.Id
        );
        insert closingRec;

        // 4) Remainder_Person__c minimal fields only:
        //    Closing__c = Closing__c.Id
        //    Remainder_Person_Contact__c = Beneficiary Contact Id
        Remainder_Person__c rp = new Remainder_Person__c(
            Closing__c = closingRec.Id,
            Remainder_Person_Contact__c = beneficiaryContact.Id
        );
        insert rp;
    }

    @IsTest
    static void testGetRemainderPeople() {
        Closing__c c = [SELECT Id FROM Closing__c LIMIT 1];

        Test.startTest();
        remainderPersonTableController.getRemainderPeople(c.Id, DateTime.now().getTime(), null);
        Test.stopTest();
    }

    @IsTest
    static void testGetRemainderPeopleWithNullId() {
        Test.startTest();
        remainderPersonTableController.getRemainderPeople(null, DateTime.now().getTime(), null);
        Test.stopTest();
    }

    @IsTest
    static void testGetRemainderPeopleWithFilterLogic() {
        Closing__c c = [SELECT Id FROM Closing__c LIMIT 1];

        // Keep filter simple/portable (doesn't rely on org-specific picklist values)
        String filter = 'Id != null';

        Test.startTest();
        remainderPersonTableController.getRemainderPeople(c.Id, DateTime.now().getTime(), filter);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemainderPerson_Insert_MinimalFields() {
        Closing__c c = [SELECT Id FROM Closing__c LIMIT 1];
        Contact beneficiaryContact = [SELECT Id FROM Contact WHERE LastName = 'Beneficiary' LIMIT 1];

        Remainder_Person__c rp = new Remainder_Person__c(
            Closing__c = c.Id,
            Remainder_Person_Contact__c = beneficiaryContact.Id
        );

        Test.startTest();
        remainderPersonTableController.saveRemainderPerson(rp);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemainderPerson_Update_NoFieldChanges() {
        Remainder_Person__c existing = [SELECT Id FROM Remainder_Person__c LIMIT 1];

        // Update with only Id (no additional fields)
        Remainder_Person__c toUpdate = new Remainder_Person__c(Id = existing.Id);

        Test.startTest();
        remainderPersonTableController.saveRemainderPerson(toUpdate);
        Test.stopTest();
    }

    @IsTest
    static void testSaveRemainderPerson_NullInput() {
        try {
            Test.startTest();
            remainderPersonTableController.saveRemainderPerson(null);
            Test.stopTest();
        } catch (Exception e) {
            // Expected
        }
    }
}