@isTest
public class InvoicingBatchUtilTest {
    @testSetup
    static void setupTestData() {
        // Create test users
        User testUser = new User(
            Username = 'testuser@test1113.com',
            LastName = 'Test',
            FirstName = 'User',
            Email = 'testuser@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            Can_Create_Invoices__c = true
        );
        insert testUser;
        
        // Create test periods
        Periods__c testPeriod1 = new Periods__c(Name = 'Period 1', Is_Closed__c = false, Period_Start_Date__c = Date.today().addMonths(-1));
        Periods__c testPeriod2 = new Periods__c(Name = 'Period 2', Is_Closed__c = false, Period_Start_Date__c = Date.today());
        insert new List<Periods__c>{testPeriod1, testPeriod2};
    }

    @isTest
    static void testCheckAccess() {
        User testUser = [SELECT Id FROM User where UserName='testuser@test1113.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Boolean hasAccess = InvoicingBatchUtil.checkAccess();
            Test.stopTest();
            
            System.assertEquals(true, hasAccess, 'User should have access to create invoices');
        }
    }

    @isTest
    static void testGetPeriodValues() {
        Test.startTest();
        List<Periods__c> periodValues = InvoicingBatchUtil.getPeriodValues();
        Test.stopTest();
        
        System.assertEquals(2, periodValues.size(), 'There should be 2 period values returned');
    }

    @isTest
    static void testRunBatch() {
        Periods__c testPeriod = [SELECT Id FROM Periods__c LIMIT 1];
        
        Test.startTest();
        InvoicingBatchUtil.runBatch(testPeriod.Id);
        Test.stopTest();
        
        // Check for asynchronous job
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobItemsProcessed FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
        System.assertNotEquals(0, jobs.size(), 'Batch job should have been executed');
    }
}