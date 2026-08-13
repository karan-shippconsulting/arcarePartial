public class UpdateDisbursementsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    @TestVisible private Boolean hadErrors = false;
    @TestVisible private List<Id> trustIds;

    public UpdateDisbursementsBatch(){
    }

    public UpdateDisbursementsBatch(List<Id> trustIds){
        this.trustIds = trustIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        if(trustIds != null && !trustIds.isEmpty()){
            return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses AND Id IN :trustIds');
        }
        return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses');
    }

    public void execute(Database.BatchableContext ctx,List<trust__c> records){
        List<trust__c> newRecords = new List<trust__c>();
        for(trust__c trust:records){
            try{
                TrueLinkApiHandler.updateDisbursement(trust.Id);
            } catch(Exception e){
                hadErrors = true;
                insert new Track_API_Call__c(
                    Parent_Record_Id__c = trust.Id,
                    Status__c = 'Error',
                    Error_Message__c = 'Error While Updating Disbursements. => ' + e.getMessage() + '=>' + e.getStackTraceString()
                );
            }
        }
    }

    public void finish(Database.BatchableContext ctx){
        if(!hadErrors){
            Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
            feature.Disbursement_Last_Run_Datetime__c = system.now();
            if(!Test.isRunningTest())
                update feature;
        }
    }
}