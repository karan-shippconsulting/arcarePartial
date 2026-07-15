@isTest
public class BulkTimeEntryUtilsTest {
	@testSetup
    static void setupTestData() {
        // Create test contacts
        Contact testContact = new Contact(LastName = 'Test Contact');
        insert testContact;
        

        
        // Create test service enrollments
        Service_Enrollment__c testServiceEnrollment = new Service_Enrollment__c(
            Name = 'Test Enrollment',
            Client__c = testContact.Id,
            Status__c = 'Pending',
            Account_Number__c = 'Test'
        );
        insert testServiceEnrollment;
        
        // Create test products
        Product2 testProduct = new Product2(Name = 'Test Product', Time_Entry_Category__c = 'FEES', IsActive = true);
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        insert testProduct;
        
        // Create test pricebook
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            Original_System_ID__c = 'test',
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create test charges
        Time_Entry__c testCharge = new Time_Entry__c(
            Name = 'Test Charge',
            Client__c = testContact.Id,
            Time_Entry_Category__c = 'FEES',
            Hours__c = '2',
            Minutes__c = '30',
            Quantity__c = 1,
            Non_billable__c = false,
            Service_Enrollment__c = testServiceEnrollment.Id,
            Entry_date__c = Date.today(),
            Unit_Price__c = 100.0,
            Status__c = 'Active'
        );
        insert testCharge;
    }
    
    @isTest
    static void testGetClients() {
        Test.startTest();
        List<Contact> clients = BulkTimeEntryUtils.getClients();
        Test.stopTest();
        
        System.assertNotEquals(0, clients.size(), 'Clients should not be empty');
    }
    
    @isTest
    static void testGetServiceEntollment() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        List<Service_Enrollment__c> serviceEnrollments = BulkTimeEntryUtils.getServiceEntollment(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, serviceEnrollments.size(), 'Service Enrollments should not be empty');
    }
    
    @isTest
    static void testGetBillingCode() {
        Test.startTest();
        List<Product2> billingCodes = BulkTimeEntryUtils.getBillingCode('FEES');
        Test.stopTest();
        
        System.assertNotEquals(0, billingCodes.size(), 'Billing Codes should not be empty');
    }
    
    @isTest
    static void testGetUnitPrice() {
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Time_Entry_Category__c = 'FEES' LIMIT 1];
        
        Test.startTest();
        Double unitPrice = BulkTimeEntryUtils.getUnitPrice(testProduct.Id);
        Test.stopTest();
        
        System.assertNotEquals(100, unitPrice, 'Unit Price should not be null');
    }
    
    @isTest
    static void testGetCharges() {
        Test.startTest();
        List<Time_Entry__c> chargesToday = BulkTimeEntryUtils.getCharges('TODAY');
        List<Time_Entry__c> chargesTHIS_WEEK = BulkTimeEntryUtils.getCharges('THIS_WEEK');
        List<Time_Entry__c> chargesTHIS_MONTH = BulkTimeEntryUtils.getCharges('THIS_MONTH');
        List<Time_Entry__c> chargesLAST_MONTH = BulkTimeEntryUtils.getCharges('LAST_MONTH');
        Test.stopTest();
        
        System.assertNotEquals(0, chargesToday.size(), 'Charges for today should not be empty');
    }
}