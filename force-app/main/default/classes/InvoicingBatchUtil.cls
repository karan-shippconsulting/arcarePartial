public class InvoicingBatchUtil {
    @AuraEnabled
    public static Boolean checkAccess(){
        String userId = UserInfo.getUserId();
        return [Select Id,Can_Create_Invoices__c from User where Id=:userId limit 1].Can_Create_Invoices__c;
    }

    @AuraEnabled(cacheable=true)
    public static List<Periods__c> getPeriodValues(){
        List<String> toRet = new List<String>();
        for(Periods__c pr:[Select ID, Name from Periods__c where Is_Closed__c=False Order By Period_Start_Date__c ASC Limit 4]){
            toRet.add(pr.Name);
        }
//        return toRet;
        return [Select ID, Name from Periods__c where Is_Closed__c=False Order By Period_Start_Date__c ASC Limit 4];
    }
    
    @AuraEnabled
    public static void runBatch(String periodId){
        Database.executeBatch(new InvoicingBatch(periodId));
    }
}