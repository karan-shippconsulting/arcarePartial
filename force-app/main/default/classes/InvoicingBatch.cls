public class InvoicingBatch implements Database.Batchable<SObject>,Database.Stateful {
    
    Periods__c periodRec;
    Id recordTypeId;
    Id activePriceBookId;
    Map<String,Integer> statusMap = new Map<String,Integer>{'Success' => 0,'Failed' => 0};
        public InvoicingBatch(String periodId){
            this.periodRec = [Select Id,Name,Period_Start_Date__c,Period_End_Date__c from Periods__c where Id=:periodId limit 1];
            this.activePriceBookId = [Select Id,Name,IsActive from Pricebook2 where Current_Price_Book__c = true limit 1]?.Id;
            this.recordTypeId = [Select Id,Name from RecordType where Name='Client Invoice' limit 1]?.Id;
        }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select ID,Entry_date__c ,Client__c, Client__r.AccountId,Description__c, Service_Enrollment__c,Service_Enrollment__r.Date_Closed__c, Service_Enrollment__r.Name,Quantity__c, Service_Code__c,Date_Invoiced__c,
                                         Unit_Price__c, Period__c, Period__r.Name, Period__r.Period_Start_Date__c,
                                         Period__r.Period_End_Date__c  from Time_Entry__c where  Status__c='APPROVED' and Service_Code__c!=null]);
    }
    public void execute(Database.BatchableContext context, List<Time_Entry__c> charges){
        try{
            Map<String,List<Time_Entry__c>> groupByData = new Map<String,List<Time_Entry__c>>();
            List<Opportunity> toCreate = new List<Opportunity>();
            List<OpportunityLineItem> oppItemToCreate = new List<OpportunityLineItem>();
            for(Time_Entry__c charge:charges){
                String key = charge.Client__c +''+ charge.Service_Enrollment__c;
                if(groupByData.containsKey(key)){
                    groupByData.get(key).add(charge);
                }else{
                    groupByData.put(key,new List<Time_Entry__c>{charge});
                }            
            }
            
            for(List<Time_Entry__c> chargesList : groupByData.values()){
                Opportunity opp = new Opportunity();
                opp.Name = chargesList[0].Service_Enrollment__r.Name + dateToString(chargesList[0].Service_Enrollment__r.Date_Closed__c);
                opp.AccountId = chargesList[0].Client__r.AccountId;
                opp.Service_Enrollment__c = chargesList[0].Service_Enrollment__c;
                opp.StageName = 'Invoiced';   
                opp.Period__c = this.periodRec.Id;
                opp.Pricebook2Id = this.activePriceBookId;
                opp.CloseDate = this.periodRec.Period_End_Date__c;
                opp.RecordTypeId = this.recordTypeId;
                toCreate.add(opp);
            }
            
            insert toCreate;
            
            Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
            for(Opportunity opp : toCreate) {
                String key = opp.Service_Enrollment__c + '' + opp.AccountId;
                oppMap.put(key, opp);
            }
            system.debug('this.activePriceBookId: '+this.activePriceBookId);
            map<String,PricebookEntry> serviceCodeVsPriceBookEntry = new map<String,PricebookEntry>();
            for(PricebookEntry pe : [SELECT Id,Product2Id,Product2.Description FROM PricebookEntry WHERE Pricebook2Id = :this.activePriceBookId AND Product2Id !=null]){
                serviceCodeVsPriceBookEntry.put(pe.Product2Id,pe);
            }
            system.debug('this.serviceCodeVsPriceBookEntry: '+serviceCodeVsPriceBookEntry);
            
            map<Id,OpportunityLineItem> oppoChargeVsProdItems = new map<Id,OpportunityLineItem>();
            for(List<Time_Entry__c> chargesList : groupByData.values()){
                Opportunity opp = oppMap.get(chargesList[0].Service_Enrollment__c + '' + chargesList[0].Client__r.AccountId);
                for(Time_Entry__c charge : chargesList){
                    //charge.Status__c = 'INVOICED';
                    system.debug('Code: '+charge.Service_Code__c);
                    OpportunityLineItem item = new OpportunityLineItem();
                    item.OpportunityId = opp.Id;
                    item.Quantity = charge.Quantity__c;
                    if( String.isNotBlank(charge.Description__c))
                        item.Description = charge.Description__c;
                    else if(serviceCodeVsPriceBookEntry.containskey(charge.Service_Code__c))
                        item.Description = serviceCodeVsPriceBookEntry.get(charge.Service_Code__c).Product2.Description;
                    item.UnitPrice = charge.Unit_Price__c;
                    item.PriceBookEntryID = serviceCodeVsPriceBookEntry.size() > 0 ? serviceCodeVsPriceBookEntry.get(charge.Service_Code__c).Id : null;
                    item.ServiceDate = charge.Entry_date__c;
                    system.debug('item: '+item);
                    //oppItemToCreate.add(item);
                    oppoChargeVsProdItems.put(charge.Id,item);
                }
                //update chargesList;
            }
            insert oppoChargeVsProdItems.values();
            list<Time_Entry__c> timeEmtryToUpdate = new list<Time_Entry__c>();
            for(Id ChargeId : oppoChargeVsProdItems.keyset()){
                Time_Entry__c charge = new Time_Entry__c(Id=ChargeId);
                charge.Status__c = 'INVOICED';
                charge.Opportunity_Product__c = oppoChargeVsProdItems.get(ChargeId).Id;
                timeEmtryToUpdate.add(charge);
            }
            update timeEmtryToUpdate;
            statusMap.put('Success',statusMap.get('Success')+charges.size());
        }catch(Exception e){
            statusMap.put('Failed',statusMap.get('Failed')+charges.size());
        }
        
    }
    
    public void finish(Database.BatchableContext context){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {UserInfo.getUserEmail()};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Invoicing batch status');
        String body = 'Batch Job Proccess is completed. \n Success: '+statusMap.get('Success') + ' \n Failed : '+statusMap.get('Failed');
        mail.setPlainTextBody(body);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    private static String dateToString(Date toConvert){
        return '';
    }
}