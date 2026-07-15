@isTest
private class pdfPageControllerBulkTest {
    @testSetup
    static void setupTestData() {
        // Create a test Custom Email Template record
        Custom_Email_Template__c nc = new Custom_Email_Template__c();
        insert nc;
        Bulk_Custom_Email_Template__c testTemplate = new Bulk_Custom_Email_Template__c(
            Custom_Email_Template__c = nc.id,
            Final_Email_Body__c = 'Sample PDF Content'
        );
        insert testTemplate;
    }

    @isTest
    static void testControllerWithRecId() {
        // Simulate the page context with a parameter
        Test.startTest();
        
        Custom_Email_Template__c cet = [select id from Custom_Email_Template__c limit 1];
        PageReference testPage = Page.renderPdfBulk; // Replace with actual Visualforce Page name
        testPage.getParameters().put('recId', cet.Id);
        Test.setCurrentPage(testPage);
        
        pdfPageControllerBulk controller = new pdfPageControllerBulk();
        
        Test.stopTest();
        
        // Verify that the PDF text list is populated
        System.assertNotEquals(0, controller.pdfText.size(), 'pdfText should not be empty');
        System.assertEquals('Sample PDF Content', controller.pdfText[0], 'Expected text not found');
    }
}