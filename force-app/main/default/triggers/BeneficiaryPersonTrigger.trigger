trigger BeneficiaryPersonTrigger on account (after update) {
    if(Trigger.isAfter && Trigger.isUpdate){
        if(Trigger.new.size() == 1){
            account acc = Trigger.new[0];
            True_Link_Trigger_Switch__c apiSwitch = True_Link_Trigger_Switch__c.getOrgDefaults();
            if(acc.Update_True_Link__pc && (apiSwitch.Update_Beneficiary__c || apiSwitch.Update_Beneficiary_Address__c)){
                    Set<String> allowedTrustStatus = new Set<String>{'Pending-Active','Active','Closing'};
                    Set<String> addressFields = new Set<String>{'Living_Street_1__pc','Living_Street_2__pc', 'Living_City__pc', 'Living_State__pc', 'Living_Zip_Code__pc', 'Living_Country__pc'};
                        for( trust__c trust : [select id,TrueLink_ID__c,Truelink_Address_Id__c from trust__c where Beneficiary__c=:acc.PersonContactId and Trust_Status__c IN :allowedTrustStatus]){
                            system.debug('trust: '+trust);
                            Boolean isAddressChanged = false;
                            if(apiSwitch.Update_Beneficiary_Address__c){
                                account oldRecord = Trigger.oldMap.get(acc.Id );
                                account newRecord = Trigger.newMap.get(acc.Id );
                                for(String addressField:addressFields){
                                    isAddressChanged = oldRecord.get(addressField) != newRecord.get(addressField);
                                    if(isAddressChanged)
                                        break;
                                }
                            }
                            if(isAddressChanged){
                                if(String.isNotBlank(trust.Truelink_Address_Id__c))
                                    TrueLinkPartyTriggerHandler.updateAddress(acc.PersonContactId ,trust.Truelink_Address_Id__c);
                                else
                                    TrueLinkPartyTriggerHandler.createAddress(acc.PersonContactId ,trust.TrueLink_ID__c);
                            }
                            if(apiSwitch.Update_Beneficiary__c){
                                TrueLinkPartyTriggerHandler.updateTrustBeneficiary(acc.PersonContactId ,trust.Id, trust.TrueLink_ID__c);                          
                            }
                        }
                }
        }
    }
}