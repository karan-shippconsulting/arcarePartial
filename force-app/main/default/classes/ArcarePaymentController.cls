public class ArcarePaymentController {
    @AuraEnabled
    public static List<Opportunity> getOpportunities (Id batchId, String selectedFilter, Decimal filterAmount, String period, 
        String serviceType, String trustPortfolio, Integer offset){
        /*if(selectedFilter == 'Unselected'){
            batchId = null;
        }*/
        String query = 'Select ID, Name,Service_Enrollment__r.Name,Amount,Period__r.Name,Payment_Batch__c,CreatedDate,Bill_Date__c from Opportunity';
        if(selectedFilter == 'Unselected'){
            query += ' where Payment_Batch__c = null';
        } else if (selectedFilter == 'Selected') {
            query += ' where Payment_Batch__c = :batchId';
        }
        else{
            query += ' where (Payment_Batch__c = null or Payment_Batch__c = :batchId)';
        }
        if(filterAmount!=null){
            query += ' and Amount = :filterAmount';
        }
        if(!String.isBlank(period)){
            query += ' and Period__c = :period';
        }
        if(!String.isBlank(serviceType)){
            query += ' and Service_Enrollment__r.Service_Picklist__c = :serviceType';
        }
        if(!String.isBlank(trustPortfolio)){
            query += ' and Payment_Batch__r.Trust_Portfolio__c = :trustPortfolio';
        }
        //query += ' limit 20 offset :offset';
        query +=  ' and Integration_Status__c= \'Synced\' and stagename =\'Invoiced\''; //and iswon=false and isclosed=false
        //query += ' limit 20';    
        return Database.query(query);
    }
    @AuraEnabled
    public static String updateOpportunities (List<Opportunity>opportunities ){
         try {
            update opportunities;
            return 'success';
        }catch(DmlException e) {
            return 'server error';
        }        
    }

    @AuraEnabled
    public static Map<Id, String> getPeriods(){
        Map<Id, String> mapOfPeriodsName = new Map<Id, String>();
       List<Periods__c> periods = [select Id, Name from Periods__c where Period_Start_Date__c = LAST_N_MONTHS:4];
       for(Periods__c period : periods){
            mapOfPeriodsName.put(period.Id, period.Name);
       }
       return mapOfPeriodsName;
    }

    @AuraEnabled
    public static List<String> getServiceType(){
        List<String> listOfServiceTypeValues = new List<String>();
        Schema.DescribeFieldResult servicePicklist = Service_Enrollment__c.Service_Picklist__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = servicePicklist.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : picklistValues){
            listOfServiceTypeValues.add(pickListVal.getValue());
        }
        return listOfServiceTypeValues;
    }
    @AuraEnabled
    public static Map<Id, String> getTrustPortfolio(){
        Map<Id, String> mapOfTrustPortfolio = new Map<Id, String>();
        List<Trust_Portfolio__c> listOfTrustPortfolio = [SELECT Id, Name FROM Trust_Portfolio__c];

        for(Trust_Portfolio__c trustPortfolio : listOfTrustPortfolio){
            mapOfTrustPortfolio.put(trustPortfolio.Id, trustPortfolio.Name);
        }
        return mapOfTrustPortfolio;
    }

    @AuraEnabled
    public static Batch_Payment__c getBatchPayment(Id recordId){
        Batch_Payment__c batchPaymentObj = [SELECT Id, Period__c, Trust_Portfolio__c, Service_Type__c FROM Batch_Payment__c WHERE Id =: recordId LIMIT 1];
        return batchPaymentObj;
    }
}