@isTest
public class summaryTemplateControllerTest {
	@isTest
    static void testController() {
        // Step 1: Create test data
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        trust__c trust = new trust__c(Name='Test Trust Account', beneficiary__c=con.id, Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, TrueLink_Id__c='TestTrustId', Trust_Status__c='Inactive');
        insert trust;
        
        Account acc = new Account(Name = 'Test Account', BillingStreet = '123 Test St', BillingCity = 'Test City', BillingState = 'Test State');
        insert acc;

        Contact contact = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert contact;

        transaction__c opp = new transaction__c(
            Name = 'Test Opportunity',
            Amount__c = 1000,
            Merchant_Name__c  = 'test',
            Payee_Description__c = 'Test Opportunity Description',
            Cleared_Date__c = Date.today().addDays(10),
            Trust__c = trust.id
        );
        insert opp;

        // Step 2: Set the ApexPages parameters
        Test.startTest();
        ApexPages.currentPage().getParameters().put('bulkIds', opp.Id);

        // Step 3: Instantiate the controller
        summaryTemplateController controller = new summaryTemplateController();
        Test.stopTest();
    }
}