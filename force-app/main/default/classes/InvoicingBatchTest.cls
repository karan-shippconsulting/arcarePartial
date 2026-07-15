@isTest
public class InvoicingBatchTest {
    @testSetup
    static void setupTestData() {
        // Create test periods
        Periods__c testPeriod = new Periods__c(
            Name = 'Test Period',
            Is_Closed__c = false,
            Period_Start_Date__c = Date.today().addMonths(-1),
            Period_End_Date__c = Date.today().addDays(15)
        );
        insert testPeriod;

        // Create test pricebook
         Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 testPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update testPricebook;
        
        Service__c ser = new Service__c(name = 'Test Service');
        insert ser;

        // Create test products and pricebook entries
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.0,
            Original_System_ID__c = 'test',
            IsActive = true
        );
        insert testPricebookEntry;

        

        // Create test accounts and contacts
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create test service enrollments
        Service_Enrollment__c testServiceEnrollment = new Service_Enrollment__c(
            Name = 'Test Enrollment',
            Client__c = testContact.Id,
            Service__c = ser.Id,
            Status__c = 'Pending',
            Account_Number__c = 'Test',
            Date_Closed__c = Date.today().addDays(30)
        );
        insert testServiceEnrollment;
    
        opportunity oppr = new opportunity(Name='testing DIE 4/6/2015' ,  AccountId= testAccount.Id,StageName = 'Invoiced', 
                                   CloseDate = Date.today());
        insert oppr;
        
        OpportunityLineItem oli = new OpportunityLineItem(
             OpportunityId = oppr.Id,
             Quantity = 5,
             PricebookEntryId = testPricebookEntry.Id,
             TotalPrice = 5 * testPricebookEntry.UnitPrice
        );
        insert oli;     
        
        // Create test charges
        Time_Entry__c testCharge = new Time_Entry__c(
            Entry_date__c = Date.today(),
            Client__c = testContact.Id,
            Description__c = 'Test Charge',
            Service_Enrollment__c = testServiceEnrollment.Id,
            Quantity__c = 1,
            Service_Code__c = testProduct.Id,
            Unit_Price__c = 100.0,
            Period__c = testPeriod.Id,
            Approved__c = true,
            Status__c = 'APPROVED',
            Opportunity_Product__c = oli.Id
        );
        insert testCharge;
    }

    @isTest
    static void testInvoicingBatch() {
        Periods__c testPeriod = [SELECT Id FROM Periods__c LIMIT 1];
        Test.startTest();
        InvoicingBatch batch = new InvoicingBatch(testPeriod.Id);
        Database.executeBatch(batch);
        Test.stopTest();

        /*// Verify Opportunities
        List<Opportunity> opportunities = [SELECT Id, Name, AccountId, Service_Enrollment__c, StageName, Period__c, Pricebook2Id, RecordTypeId FROM Opportunity];
        //System.assertEquals(1, opportunities.size(), 'There should be 1 opportunity created');
        Opportunity opp = opportunities[0];
        //System.assertEquals('Test Contact-Te', opp.Name.substring(0, 15), 'Opportunity name should start with the service enrollment name');
        System.assertEquals('Invoiced', opp.StageName, 'Opportunity stage should be Invoiced');
        System.assertEquals(testPeriod.Id, opp.Period__c, 'Opportunity period should match the test period');
        System.assertEquals([SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id, opp.Pricebook2Id, 'Opportunity pricebook should be active pricebook');
        System.assertEquals([SELECT Id FROM RecordType WHERE Name = 'Client Invoice' LIMIT 1].Id, opp.RecordTypeId, 'Opportunity record type should be Client Invoice');

        // Verify Opportunity Line Items
        List<OpportunityLineItem> opportunityLineItems = [SELECT Id, OpportunityId, Quantity, Description, UnitPrice, Product2Id FROM OpportunityLineItem];
        System.assertEquals(1, opportunityLineItems.size(), 'There should be 1 opportunity line item created');
        OpportunityLineItem oppItem = opportunityLineItems[0];
        System.assertEquals(opp.Id, oppItem.OpportunityId, 'Opportunity Line Item should be linked to the correct Opportunity');
        System.assertEquals(1, oppItem.Quantity, 'Opportunity Line Item quantity should be 1');
        System.assertEquals('Test Charge', oppItem.Description, 'Opportunity Line Item description should match the test charge description');
        System.assertEquals(100.0, oppItem.UnitPrice, 'Opportunity Line Item unit price should match the test charge unit price');
        System.assertEquals([SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1].Id, oppItem.Product2Id, 'Opportunity Line Item product should be the test product');

        // Verify Charges
        List<Time_Entry__c> charges = [SELECT Id, Status__c FROM Time_Entry__c WHERE Status__c = 'INVOICED'];
        System.assertEquals(1, charges.size(), 'There should be 1 charge updated to INVOICED status');*/
    }
}