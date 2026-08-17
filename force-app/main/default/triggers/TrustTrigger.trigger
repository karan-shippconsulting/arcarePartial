//Created by NeuraFlash LLC on 08-21-2018//

trigger TrustTrigger on Trust__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
         if(Trigger.new.size() == 1){
             Trust__c trust = Trigger.new[0];
             True_Link_Trigger_Switch__c apiSwitch = True_Link_Trigger_Switch__c.getOrgDefaults();
             Set<String> allowedTrustStatus = TrueLinkApiHandler.getEligibleTrustStatuses();
             if((String.isEmpty(trust.TrueLink_ID__c) || String.isBlank(trust.TrueLink_ID__c))  
				&& allowedTrustStatus.contains(trust.Trust_Status__c) 
				&& trust.Trust_Status__c != Trigger.oldMap.get(trust.Id).Trust_Status__c
               	&& trust.Beneficiary__c !=null 
                && apiSwitch.Create_Beneficiary__c){
                TrueLinkPartyTriggerHandler.createTrustBeneficiary(trust.Beneficiary__c,trust.Id);
             }
             if(!String.isBlank(trust.TrueLink_ID__c) && !TruelinkStaticUtils.stopRecursionOnTrustUpdate &&
                ( trust.Disbursement_Creation_Enabled__c != Trigger.oldMap.get(trust.Id).Disbursement_Creation_Enabled__c ||
                trust.Mail_Statements__c != Trigger.oldMap.get(trust.Id).Mail_Statements__c ||
                trust.Internal_Account_Number__c != Trigger.oldMap.get(trust.Id).Internal_Account_Number__c)
               ){
             	TrueLinkPartyTriggerHandler.updateTrust(trust.Id,trust.TrueLink_ID__c);
             }
             if(!String.isBlank(trust.TrueLink_ID__c) && !TruelinkStaticUtils.stopRecursionOnTrustUpdate &&
                trust.Update_EIN_and_BID__c == true && Trigger.oldMap.get(trust.Id).Update_EIN_and_BID__c == false
               ){
             	TrueLinkPartyTriggerHandler.updateTrustForEinAndBid(trust.Id,trust.TrueLink_ID__c);
             }
             
         }
    }
}