public class BatchUtils {
        
    public static void rescheduleBatch(String jobName,Schedulable obj){

        List<Batch_Class_Configuration__mdt> setting;
        setting = [
            SELECT Frequency_in_Days__c,Frequency_in_Minutes__c
            FROM Batch_Class_Configuration__mdt 
            WHERE DeveloperName = :jobName 
            LIMIT 1
        ];
        Set<Id> crnJobDtSet = new Set<Id>();
        jobName += '_%';
        List<CronJobDetail> cjDetailList = [SELECT Id, Name, JobType FROM CronJobDetail WHERE Name like :jobName];
        for(CronJobDetail cjd : cjDetailList){
            crnJobDtSet.add(cjd.Id);
        }
        Set<Id> cronTriggerId = new Set<Id>();
        List<CronTrigger> cronTriggerList = [SELECT Id FROM CronTrigger WHERE CronJobDetailId IN :crnJobDtSet];
        Set<Id> cronJobIds = (new Map<Id, CronTrigger>(cronTriggerList)).keyset();
        for(Id cronId : cronJobIds){
            System.abortJob(cronId);
        }

        String cronExpr;
        DateTime currentTime = DateTime.now();
        if (!setting.isEmpty() && setting[0].Frequency_in_days__c != null) {
            Integer totalDays = Integer.valueOf(setting[0].Frequency_in_days__c);
            currentTime = currentTime.addDays(totalDays);
        } else if (!setting.isEmpty() && setting[0].Frequency_in_Minutes__c != null) {
            Integer totalMinutes = Integer.valueOf(setting[0].Frequency_in_Minutes__c);
            currentTime = currentTime.addMinutes(totalMinutes);
        } 
        string day = String.valueOf(currentTime.day());
        string month = String.valueOf(currentTime.month());
        string year = String.valueOf(currentTime.year());
        string hours = String.valueOf(currentTime.hour());
        string minute = String.valueOf(currentTime.Minute());
           
        cronExpr = '00 ' + minute + ' ' + hours + ' ' + day + ' ' + month + ' ? ' + year;
        
        if(Test.isRunningTest()){
            cronExpr = '0 0 0 15 3 ? *';
        }

        // Use System.schedule to schedule the next execution
        System.schedule(jobName + '_' + DateTime.now().getTime(), cronExpr, obj);
    }
}