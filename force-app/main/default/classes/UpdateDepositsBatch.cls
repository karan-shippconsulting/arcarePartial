public class UpdateDepositsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select Id,TrueLink_ID__c,True_Link_Balance__c from trust__c where TrueLink_ID__c!=null]);
    }

    public void execute(Database.BatchableContext ctx,List<trust__c> records){   
        List<trust__c> newRecords = new List<trust__c>();
        for(trust__c trust:records){
            TrueLinkApiHandler.updateDeposit(trust.Id);
        }
    }

    public void finish(Database.BatchableContext ctx){
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Deposit_Last_Run_Datetime__c = system.now();
        if(!Test.isRunningTest())
        	update feature;
        
        Database.executeBatch(new UpdateDisbursementsBatch(),1);

    }
}