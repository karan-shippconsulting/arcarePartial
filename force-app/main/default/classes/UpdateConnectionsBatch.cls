public class UpdateConnectionsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select Id from Connections__c where Update_True_Link__c = true]);
    }

    public void execute(Database.BatchableContext ctx, List<Connections__c> records){
        for(Connections__c con : records){
            try{
                TrueLinkApiHandler.updateConnection(con.Id);
            } catch(Exception e){
                insert new Track_API_Call__c(
                    Parent_Record_Id__c = con.Id,
                    Status__c = 'Error',
                    Error_Message__c = 'Error While Updating Connection. => ' + e.getMessage() + '=>' + e.getStackTraceString()
                );
            }
        }
    }

    public void finish(Database.BatchableContext ctx){
    }
}