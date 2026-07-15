public class summaryTemplateController {
    public list<Transaction__c> tranxList {get;set;}
    public Boolean noLetterHead {get;set;}
    public summaryTemplateController(){
        tranxList = new list<Transaction__c>();
        noLetterHead = ApexPages.currentPage().getParameters().get('noLetterHead')!=null ? 
            Boolean.valueof(ApexPages.currentPage().getParameters().get('noLetterHead')) : false;
        String param = ApexPages.currentPage().getParameters().get('bulkIds');
        list<Id> paramIds = new list<Id>();
        if(String.isNotBlank(param) && param.contains(',')){
            paramIds.addALL(param.split(','));
        } else {
            paramIds.add(param);
        }
        if(!paramIds.isEmpty()){
            String query= 'select Name,Payee_Street_1__c,Payee_Street_2__c,Payee_State__c,Payee_Name__c,Payee_City__c,Payee_Zip__c,Amount__c,'+
             		'Cleared_Date__c,Merchant_Name__c,Payee_Description__c, Beneficiary__r.Email';
                    for(Schema.FieldSetMember fld :SObjectType.Transaction__c.FieldSets.Bulk_Print_and_Email.getFields()) {
                        if(!query.contains(fld.getFieldPath())){
                            query += ', ' + fld.getFieldPath();
                        }
                    }

             query += ' from Transaction__c where id IN :paramIds';
             tranxList = Database.query(query);
        }
    }
}