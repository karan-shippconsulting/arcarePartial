@isTest
public class DocsumoRecordInsertQueueableTest {

    // Test case where the object name is invalid (object doesn't exist)
    @isTest
    static void testInvalidObjectName() {
        // Create a Lead record (mocking related data)
        Lead testLead = new Lead(FirstName = 'John', LastName = 'Doe', Company = 'Test Company');
        insert testLead;

        // Create a ContentVersion (mocking the file)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Document',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient = 'test'
        );
        insert contentVersion;

        // Set an object name
        String ObjectName = 'DS_us_bank_statement__c';
        
        String docId = '8ea74c58177845ba87a3713aa45638bv';

        DocsumoRecordInsertQueueable queueableJob = new DocsumoRecordInsertQueueable(
            testLead.Id, docId, 'Completed', contentVersion.Title, 'https://docsumo.com/review', ObjectName, contentVersion.Id
        );

        // Enqueue the queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();

        // Records should have been created due in the object name
        Integer recordCount = [SELECT COUNT() FROM DS_us_bank_statement__c];
        System.assertEquals(recordCount, 1, 'No records should be inserted for invalid object name.');
        
    }
}