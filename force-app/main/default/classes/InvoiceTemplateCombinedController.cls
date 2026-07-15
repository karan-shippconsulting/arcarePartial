/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class InvoiceTemplateCombinedController{
   
    public List<Opportunity> opportunities{get;set;}

    public InvoiceTemplateCombinedController(){
        String OpportunitiesIDs = ApexPages.CurrentPage().getParameters().get('id');
        List<String> opportunityList = OpportunitiesIDs.split(';');
        List<Opportunity> opportunityLists = new List<Opportunity>();

        for(Opportunity op : [SELECT Id,
            Service_Enrollment__r.Billing_Attention_To__c,
            Service_Enrollment__r.Billing_Street_1__c,
            Service_Enrollment__r.Billing_Street_2__c,
            Service_Enrollment__r.Billing_City__c,
            Service_Enrollment__r.Billing_State__c,
            Service_Enrollment__r.Billing_Zip_Code__c,
            Service_Enrollment__r.Name,
            Service_enrollment__r.Account_Number__c,
            CloseDate,
            Invoice_Number__c,
            Service_Enrollment__r.Mail_To_Attention__c,
            Service_Enrollment__r.Mail_To_Street_1__c,
            Service_Enrollment__r.Mail_To_Street_2__c,
            Service_Enrollment__r.Mail_To_City__c,
            Service_Enrollment__r.Mail_To_State__c,
            Service_Enrollment__r.Mail_To_Zip_Code__c,
            Service_Enrollment__r.Copy1_Attention_To__c,
            Service_Enrollment__r.Copy1_Street_1__c,
            Service_Enrollment__r.Copy1_Street_2__c,
            Service_Enrollment__r.Copy1_City__c,
            Service_Enrollment__r.Copy1_State__c,
            Service_Enrollment__r.Copy1_Zip_Code__c,
            Service_Enrollment__r.Copy2_Attention_To__c,Service_Enrollment__r.Copy2_Street_1__c,
            Service_Enrollment__r.Copy2_Street_2__c,Service_Enrollment__r.Copy2_City__c,
            Service_Enrollment__r.Copy2_State__c,Service_Enrollment__r.Copy2_Zip_Code__c,
            Account.Name,
                (SELECT ID,Opportunity.Owner.Initials__c,Description,Quantity,UnitPrice,TotalPrice,
                Product2.Charge_Type__c,Time_Entry__r.Entry_Date__c
                FROM OpportunityLineItems)
            FROM opportunity
            WHERE ID in: opportunityList]){
                opportunityLists.add(op);
        }
        opportunities = opportunityLists;
    }
}