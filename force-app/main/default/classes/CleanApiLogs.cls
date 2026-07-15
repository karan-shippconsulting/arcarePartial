public class CleanApiLogs implements Database.Batchable<sObject>,Schedulable {
    public Database.QueryLocator start(Database.BatchableContext bc){
        Batch_Class_Configuration__mdt setting;
        setting = [
            SELECT Frequency_in_Days__c
            FROM Batch_Class_Configuration__mdt 
            WHERE DeveloperName = 'CleanApiLogs'
            LIMIT 1
        ];
        Date myDateStart;
        if(Test.isRunningTest()){
            myDateStart = Date.today();
        } else {
            myDateStart = Date.today().addDays(-1*Integer.valueOf(setting.Frequency_in_Days__c));
        }

        return Database.getQueryLocator('SELECT Id FROM Track_API_Call__c WHERE DAY_ONLY(CreatedDate) <=:myDateStart');
    }

      public void execute(Database.BatchableContext BC, List<Track_API_Call__c> trackApiList){
        delete trackApiList;
    }

    //finish method
    public void finish(Database.BatchableContext BC){
        BatchUtils.rescheduleBatch('CleanApiLogs',new CleanApiLogs());
    }

    public void execute(SchedulableContext sc) {
        Database.executebatch(this,200);
    }

}