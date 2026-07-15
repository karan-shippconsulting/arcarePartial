@isTest
public class SignPdfControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a test Account (or any object you plan to attach the file to)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create ContentVersion (file to upload)
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestFile';
        cv.PathOnClient = 'TestFile.pdf';
        cv.VersionData = Blob.valueOf('Sample PDF content');
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = acc.Id;
        insert cv;

        /*// Retrieve the related ContentDocumentId
        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = cdId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;*/
    }

    @isTest
    static void testGetRecordsId() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        String result = SignPdfController.getRecordsId(acc.Id);
        System.assertNotEquals(null, result);
        //System.assert(result.containsIgnoreCase('015')); // Example ContentDocumentId prefix
        Test.stopTest();
    }

    @isTest
    static void testGetData() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<String> fileList = SignPdfController.getData(acc.Id);
        System.assert(fileList.size() > 0, 'Expected at least one file returned');
        Test.stopTest();
    }

    @isTest
    static void testAttachPdfOnRecord() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Signed PDF'));
        
        Test.startTest();
        SignPdfController.attachPdfOnRecord(base64Pdf, acc.Id);
        Test.stopTest();

        // Verify new file is attached
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];
        System.assertEquals(1, links.size(), 'One ContentDocumentLink should exist');
    }
}