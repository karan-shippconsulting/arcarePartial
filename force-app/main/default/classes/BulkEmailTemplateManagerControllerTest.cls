@isTest
public class BulkEmailTemplateManagerControllerTest {
    
    @testSetup
    static void setupData() {
        // Insert sample Accounts (or Leads/Contacts depending on your VF page)
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accts;
    }
    
    @isTest
    static void testSelectedIdsPopulation() {
        // Query the test data
        List<Account> accts = [SELECT Id, Name FROM Account LIMIT 2];
        
        // Create a StandardSetController
        ApexPages.StandardSetController stdController = 
            new ApexPages.StandardSetController(accts);
        
        // Simulate selecting records
        stdController.setSelected(accts);
        
        // Instantiate your custom controller
        BulkEmailTemplateManagerController controller = 
            new BulkEmailTemplateManagerController(stdController);
        
        // Assertions
        System.assertEquals(2, controller.selectedIds.size(), 
            'Controller should capture 2 selected Ids');
        System.assertEquals(accts[0].Id, controller.selectedIds[0], 
            'First selected Id should match');
        System.assertEquals(accts[1].Id, controller.selectedIds[1], 
            'Second selected Id should match');
    }
    
    @isTest
    static void testNoSelection() {
        // Query one record
        List<Account> accts = [SELECT Id, Name FROM Account LIMIT 1];
        
        ApexPages.StandardSetController stdController = 
            new ApexPages.StandardSetController(accts);
        
        // No selection made
        stdController.setSelected(new List<SObject>());
        
        BulkEmailTemplateManagerController controller = 
            new BulkEmailTemplateManagerController(stdController);
        
        System.assertEquals(0, controller.selectedIds.size(), 
            'Controller should have empty selectedIds when nothing is selected');
    }
}