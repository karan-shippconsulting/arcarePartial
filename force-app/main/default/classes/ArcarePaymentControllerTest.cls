@isTest
public class ArcarePaymentControllerTest {
    
    @TestSetup
    private static void setupData(){
        Batch_Payment__c batch = new Batch_Payment__c(Total_Invoices_Selected__c=5,Total_Amount_Selected__c=500);
        insert batch;
        List<Periods__c> periods = new List<Periods__c>();
        
        for(Integer i=0; i < 10 ; i++){
            periods.add(new Periods__c(Name='1/1/2010 to 1/31/201'+i,Period_Start_Date__c=Date.Today()-10,Period_End_Date__c = Date.today()-9));
        }
        insert periods;
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i=0; i < 10 ; i++){
            if(i<5)
                opps.add(new Opportunity(Name='Test'+i,StageName='Posted',CloseDate = Date.today(),Amount=10,Period__c = periods[0].Id, Period__r =periods[0]));
            else
                opps.add(new Opportunity(Name='Test'+i,StageName='Posted',CloseDate = Date.today(),Amount=10,Payment_Batch__c=batch.Id)); 
        }
        Database.insert(opps);
        
        Pooled_Trust__c pooledTrust = new Pooled_Trust__c();
        pooledTrust.Name = 'Test Pooled Trust';
        insert pooledTrust;
        
        Trust_Portfolio__c trustPortfolio = new Trust_Portfolio__c();
        trustPortfolio.Name = 'Test Trust Portfolio';
        trustPortfolio.Pooled_Trust__c = pooledTrust.Id;
        insert trustPortfolio;
    }
    
    @isTest
    public static void getOpportunitiesTest(){
        String selectedFilter;
        String serviceType;
        Integer offset = 0;
        Batch_Payment__c batch = [SELECT Id FROM Batch_Payment__c][0];
        List<Opportunity> oppsWithoutBatch = ArcarePaymentController.getOpportunities(null,selectedFilter,10, '1/1/2010 to 1/31/2010', serviceType, '', offset);
        List<Opportunity> oppsWithBatch = ArcarePaymentController.getOpportunities(batch.Id,selectedFilter,10,null, serviceType,'', offset);
        System.assertEquals(0, oppsWithoutBatch.size(),'Opportunity count should match');
        //System.assertEquals(10, oppsWithBatch.size(),'Opportunity count should match');
        
    }
    @isTest
    public static void getPeriodsTest(){
        Map<Id, String> periods = ArcarePaymentController.getPeriods();
      /* System.assertEquals(10, periods.size(),'periods count should match');*/
    }
    @isTest
    public static void getServiceTypeTest(){
        Schema.DescribeFieldResult servicePicklist = Service_Enrollment__c.Service_Picklist__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = servicePicklist.getPicklistValues();
        List<String> service = ArcarePaymentController.getServiceType();
       /* System.assertEquals(picklistValues.size(), service.size(),'Service Type count should match');*/
    }
    @isTest
    public static void updateOpportunitiesTest(){
        List<Opportunity> opportunities = [SELECT id FROM Opportunity];
        Batch_Payment__c batch = new Batch_Payment__c(Total_Invoices_Selected__c=5,Total_Amount_Selected__c=500);
        insert batch;
        for(Opportunity opp: opportunities){
            opp.Payment_Batch__c = batch.Id;
        }
        String oppUpdateStatus = ArcarePaymentController.updateOpportunities(opportunities);
      /*  System.assertEquals(oppUpdateStatus,'success','oppUpdateStatu should match');*/
    }
    
    @isTest
    public static void getTrustPortfolioTest(){
       Map<Id, String>  trustPortfolioMap = ArcarePaymentController.getTrustPortfolio();
       System.assertEquals(trustPortfolioMap.size(), 1,'Trust Portfolio count should match');
    }
    
    @isTest
    public static void testGetBatchPayment(){
       Batch_Payment__c batchPayment = new Batch_Payment__c();
       insert batchPayment;
       Batch_Payment__c batchPaymentObj = ArcarePaymentController.getBatchPayment(batchPayment.Id);
       System.assertNotEquals(null, batchPaymentObj.Id,'Batch Payment should be found');
    }
}