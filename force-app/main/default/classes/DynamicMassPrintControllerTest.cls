@IsTest
public class DynamicMassPrintControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Visualforce_PDF__c records
        List<Visualforce_PDF__c> pdfTemplates = new List<Visualforce_PDF__c>{
            new Visualforce_PDF__c(
                Name = 'Test Template',
                Email_Body__c = 'Hello {Name}, this is a test email.',
                Visual_Force_Page_Name__c = 'TestPage',
                Type__c = 'Print',
                Print_Type__c = 'Bulk',
                IsActive__c = true,
                Object_Api_Name__c = 'Contact',
                Display_Sort_Order__c = 1,
				Recipient_Address_Field__c = 'Owner.email',
                Fields_to_Update_For_Email__c = 'firstname,lastname,email',
                Fields_Values_to_Update_For_Email__c = 'test,test,test@test.com',
                Send_Attachment__c = true
            )
        };
        insert pdfTemplates;

        // Create test Contact records
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com'),
            new Contact(FirstName = 'Jane', LastName = 'Smith', Email = 'jane.smith@example.com')
        };
        insert contacts;
    }

    @IsTest
    static void testGetPDFTempList() {
        Test.startTest();
        List<Visualforce_PDF__c> result = DynamicMassPrintController.getPDFTempList('Contact');
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals('Test Template', result[0].Name);
    }

    @IsTest
    static void testFetchRecords() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 2];
        List<String> recordIds = new List<String>();
        for (Contact c : contacts) {
            recordIds.add(c.Id);
        }
        List<String> fields = new List<String>{'FirstName', 'LastName', 'Email'};

        Test.startTest();
        List<SObject> fetchedRecords = DynamicMassPrintController.fetchRecords(recordIds, fields, 'Contact');
        Test.stopTest();

        System.assertNotEquals(null, fetchedRecords);
        System.assertEquals(2, fetchedRecords.size());
    }

    @IsTest
    static void testSendBulkEmail() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 1];
        Visualforce_PDF__c pdfTemplate = [SELECT Id FROM Visualforce_PDF__c LIMIT 1];
        List<String> recordIds = new List<String>{contacts[0].Id};

        Test.startTest();
        DynamicMassPrintController.sendBulkEmail(recordIds, pdfTemplate.Id, 'Contact');
        Test.stopTest();

        // Check Email Queues (if applicable in your org)
        //System.assertEquals(1, Limits.getEmailInvocations());
    }
        
        @IsTest
    static void testupdateBulkPrint() {
        List<Contact> contacts = [SELECT Id, Email FROM Contact LIMIT 1];
        Visualforce_PDF__c pdfTemplate = [SELECT Id FROM Visualforce_PDF__c LIMIT 1];
        List<String> recordIds = new List<String>{contacts[0].Id};

        Test.startTest();
        DynamicMassPrintController.updateBulkPrint(recordIds, pdfTemplate.Id, 'Contact');
        Test.stopTest();

        // Check Email Queues (if applicable in your org)
        //System.assertEquals(1, Limits.getEmailInvocations());
    }

    @IsTest
    static void testSendBulkEmailWithNoRecords() {
        Test.startTest();
        try {
            DynamicMassPrintController.sendBulkEmail(new List<String>(), 'templateId', 'Contact');
            System.assert(false, 'Expected exception not thrown for empty record list');
        } catch (Exception e) {
            //System.assert(e.getMessage().contains('List has no rows for assignment'), 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}