public class UpdateDepositsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    @TestVisible private Boolean hadErrors = false;

    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses');
    }

    public void execute(Database.BatchableContext ctx,List<trust__c> records){
        for(trust__c trust:records){
            try{
                TrueLinkApiHandler.updateDeposit(trust.Id);
            } catch(Exception e){
                hadErrors = true;
                insert new Track_API_Call__c(
                    Parent_Record_Id__c = trust.Id,
                    Status__c = 'Error',
                    Error_Message__c = 'Error While Updating Deposits. => ' + e.getMessage() + '=>' + e.getStackTraceString()
                );
            }
        }
    }

    public void finish(Database.BatchableContext ctx){
        if(!hadErrors){
            Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
            feature.Deposit_Last_Run_Datetime__c = system.now();
            if(!Test.isRunningTest())
                update feature;
        }

        Database.executeBatch(new UpdateDisbursementsBatch(),1);
    }
}