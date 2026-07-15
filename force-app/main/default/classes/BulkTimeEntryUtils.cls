/**
* @File Name : BulkTimeEntryUtilsWithApproval.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 17, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 17, 2024 |   | Initial Version
**/

public class BulkTimeEntryUtils {
	@AuraEnabled(cacheable=true)
    public static List<Contact> getClients(){
        return [Select Id,Name from Contact where Id IN (Select Client__c from Service_Enrollment__c WHERE Status__c IN ('Enrolled','Closing','Pending')) order by Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<Service_Enrollment__c> getServiceEntollment(String clientId){
        return [Select Id,Name from Service_Enrollment__c where Client__C =:clientId AND Status__c IN ('Enrolled','Closing','Pending')];
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getBillingCode(String category){
        return [Select Id,Name from Product2 where Time_Entry_Category__c =: category AND IsActive = true];
    }

    @AuraEnabled(cacheable=true)
    public static Double getUnitPrice(String billingCode){
        return [Select Id,UnitPrice from PricebookEntry where Product2Id =:billingCode and PriceBook2Id IN (Select Id from Pricebook2 where IsActive = true)]?.UnitPrice;
    }

    @AuraEnabled
    public static List<Time_Entry__c> getCharges(String periodSearch){
        if(periodSearch == 'THIS_WEEK')
            return [Select Id,Name,CreatedBy.Name,Client__r.FirstName,Time_Entry_Category__c,Hours__c,Minutes__c,Quantity__c,Non_billable__c,Client__r.LastName,Service_Enrollment__r.Name,Description__c,Entry_date__c,Service_Code__r.Name,Unit_Price__c,Status__c,Approved__c from Time_Entry__c where Entry_date__c = THIS_WEEK order by createddate desc];
        if(periodSearch == 'THIS_MONTH')
            return [Select Id,Name,CreatedBy.Name,Client__r.FirstName,Time_Entry_Category__c,Hours__c,Minutes__c,Quantity__c,Non_billable__c,Client__r.LastName,Service_Enrollment__r.Name,Description__c,Entry_date__c,Service_Code__r.Name,Unit_Price__c,Status__c,Approved__c from Time_Entry__c where Entry_date__c = THIS_MONTH order by createddate desc];
        if(periodSearch == 'TODAY')
            return [Select Id,Name,CreatedBy.Name,Client__r.FirstName,Time_Entry_Category__c,Hours__c,Minutes__c,Quantity__c,Non_billable__c,Client__r.LastName,Service_Enrollment__r.Name,Description__c,Entry_date__c,Service_Code__r.Name,Unit_Price__c,Status__c,Approved__c from Time_Entry__c where Entry_date__c = TODAY order by createddate desc];
        if(periodSearch == 'LAST_MONTH')
            return [Select Id,Name,CreatedBy.Name,Client__r.FirstName,Time_Entry_Category__c,Hours__c,Minutes__c,Quantity__c,Non_billable__c,Client__r.LastName,Service_Enrollment__r.Name,Description__c,Entry_date__c,Service_Code__r.Name,Unit_Price__c,Status__c,Approved__c from Time_Entry__c where Entry_date__c = LAST_MONTH order by createddate desc];
        return new List<Time_Entry__c>();
    }
}