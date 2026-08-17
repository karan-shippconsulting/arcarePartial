public class UpdateBeneficiaryBalanceBatch implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        return Database.getQueryLocator([Select Id,TrueLink_ID__c,True_Link_Balance__c from trust__c where TrueLink_ID__c!=null and Trust_Status__c IN :eligibleStatuses]);
    }

    public void execute(Database.BatchableContext ctx,List<trust__c> records){   
        List<trust__c> newRecords = new List<trust__c>();
        for(trust__c trust:records){
            TrueLinkApiHandler.updateAccountBalance(trust.Id);
        }
    }

    public void finish(Database.BatchableContext ctx){
		Database.executeBatch(new UpdateDepositsBatch(),1); 
        if(!Test.isRunningTest()){
            BatchUtils.rescheduleBatch('UpdateBeneficiaryBalanceBatch',new UpdateBeneficiaryBalanceBatch());
    }
    } 

    public void execute(SchedulableContext  sc){
        Database.executeBatch(this,1);
    }
}