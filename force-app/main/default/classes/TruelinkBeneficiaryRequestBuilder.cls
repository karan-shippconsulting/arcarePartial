public class TruelinkBeneficiaryRequestBuilder { 
    public TruelinkBeneficiaryRequestWrapper build(String partyId, String trustPartyId, String trustBeneficiaryid, Boolean isUpdate){
        map<string,string> labelVsTargetMap = new map<string,string>();
        map<id,Truelink_Disability_Designation__c> disabilities = new map<id,Truelink_Disability_Designation__c>();
        for(Salutation_Translation__mdt st : Salutation_Translation__mdt.getAll().values()){
            labelVsTargetMap.put(st.label,st.target_value__c);
        }
        for(Truelink_Disability_Designation__c tdd : [select Id, Name, Truelink_Internal_ID__c from Truelink_Disability_Designation__c ]){
            disabilities.put(tdd.Id,tdd);
        }
        Contact party = [Select Id, Salutation__c,firstname,Middle_Name__c,lastname,
                         Suffix_individual__c,email,EIN__c,Social_Security_Number__c,Birthdate,
                         MobilePhone,GenderIdentity,Living_Street_1__c,Living_Street_2__c,Living_City__c,Living_State__c,Living_Zip_Code__c,
                         Marital_Status__c, Truelink_Disability_Designation__c, Living_Situation__c
                         from contact where Id =: partyId];

        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();

        trust__c trustParty = new trust__c();
        if(trustPartyId!=null && trustPartyId!=''){
            trustParty = [Select Id, Trust_Portfolio__r.True_Link_Portfolio_ID__c,Trust_Portfolio__r.Type__c,Service_Enrollment__r.Account_Number__c,Case_Manager__c,
                          Tax_Id_Number_Type__c,EIN__c,Service_Enrollment__r.Case_Manager__c,Service_Enrollment__r.Case_Manager__r.Case_Manager_ID__c,
                          Disbursement_Creation_Enabled__c,Charge_Initial_Set_up_Fee__c,Trust_Type__c,TL_EID__c, TL_BID__c,
 						  mail_statements__c, True_Link_First_Name_Suffix__c from trust__c where Id =: trustPartyId];
        }
        
        String sufix = '';
        if(party.Suffix_individual__c!=null && party.Suffix_individual__c!='' && party.Suffix_individual__c.contains('.')){
            sufix = party.Suffix_individual__c.replace('.','');
        }else{
            sufix = party.Suffix_individual__c;
        }
        
        String prefix = '';
        if(party.Salutation__c!=null && party.Salutation__c!='' && party.Salutation__c.contains('.')){
            prefix = party.Salutation__c.replace('.','');
        }else{
            prefix = party.Salutation__c;
        }
        
        TruelinkBeneficiaryRequestWrapper reqWrapper = new TruelinkBeneficiaryRequestWrapper(isUpdate);
        if(isUpdate)
            reqWrapper.data.id = trustBeneficiaryid;    
        reqWrapper.data.attributes.email = party.email;
        reqWrapper.data.attributes.mobile = party.MobilePhone;
        reqWrapper.data.attributes.dob = party.Birthdate!=null?TruelinkRestUtil.formatDate(party.Birthdate):null;
        reqWrapper.data.attributes.gender = party.GenderIdentity;
        if(feature.Sync_Marital_Status__c == true){
            reqWrapper.data.attributes.maritalStatus = party.Marital_Status__c;
        }
        if(feature.Sync_Living_Situation__c == true){
            reqWrapper.data.attributes.livingSituation = party.Living_Situation__c;
        }
        reqWrapper.data.attributes.firstName = party.firstname;
        if(!String.isBlank(trustParty.True_Link_First_Name_Suffix__c)){
            reqWrapper.data.attributes.firstName = reqWrapper.data.attributes.firstName + ' (' + trustParty.True_Link_First_Name_Suffix__c+ ')';
        }
        reqWrapper.data.attributes.middleName = party.Middle_Name__c;
        reqWrapper.data.attributes.lastName = party.lastname;
        if(trustParty.Service_Enrollment__r.Case_Manager__c!=null && !String.isBlank(trustParty.Service_Enrollment__r.Case_Manager__r.Case_Manager_ID__c)){
            reqWrapper.data.attributes.lastName = reqWrapper.data.attributes.lastName + ' ' + trustParty.Service_Enrollment__r.Case_Manager__r.Case_Manager_ID__c;
        }

        reqWrapper.data.attributes.ein = trustParty.EIN__c;//Internal_Account_Number__c,Case_Manager__c,
        //reqWrapper.data.attributes.ssn = party.Social_Security_Number__c ;
        reqWrapper.data.attributes.taxIdNumberType = trustParty.Tax_Id_Number_Type__c;
        
        reqWrapper.data.attributes.disallowDisbursementRequests = !trustParty.Disbursement_Creation_Enabled__c;
        reqWrapper.data.attributes.chargeSetupFee = trustParty.Charge_Initial_Set_up_Fee__c;
        //revert the logic
        reqWrapper.data.attributes.externalId = trustParty.TL_EID__c;
        reqWrapper.data.attributes.beneficiaryId = trustParty.TL_BID__c;
        
        if(!isUpdate){
 			
            if(!String.isBlank(party.Living_Street_1__c))
            	reqWrapper.data.relationships.address.data.attributes.street1 = party.Living_Street_1__c;
            if(!String.isBlank(party.Living_Street_2__c))
            	reqWrapper.data.relationships.address.data.attributes.street2 = party.Living_Street_2__c;
            if(!String.isBlank(party.Living_City__c))
            	reqWrapper.data.relationships.address.data.attributes.city = party.Living_City__c;
            if(!String.isBlank(party.Living_State__c))
            	reqWrapper.data.relationships.address.data.attributes.state = party.Living_State__c;
            if(!String.isBlank(party.Living_Zip_Code__c))
            	reqWrapper.data.relationships.address.data.attributes.zip = party.Living_Zip_Code__c;
            
            reqWrapper.data.relationships.activePortfolio.data.type = 'portfolio'; //trustParty.Trust_Portfolio__r.Type__c;
            reqWrapper.data.relationships.activePortfolio.data.id = trustParty.Trust_Portfolio__r.True_Link_Portfolio_ID__c;
            
            reqWrapper.data.attributes.prefix = labelVsTargetMap.containskey(prefix) ? labelVsTargetMap.get(prefix) : null;
            reqWrapper.data.attributes.suffix = labelVsTargetMap.containskey(sufix) ? labelVsTargetMap.get(sufix) : null;
            reqWrapper.data.attributes.externalId = trustParty.TL_Eid__c;

            reqWrapper.data.attributes.mailStatement = trustParty.Mail_statements__c;
        }

        // relationships is only auto-initialized for creates (see TruelinkBeneficiaryRequestWrapper's
        // isUpdate constructor) - for updates, set up just enough to carry disabilityDesignation without
        // pulling address/activePortfolio (still empty) into the update payload.
        if(reqWrapper.data.relationships == null){
            reqWrapper.data.relationships = new TruelinkBeneficiaryRequestWrapper.Relationships();
            reqWrapper.data.relationships.address = null;
            reqWrapper.data.relationships.activePortfolio = null;
        }

        if(feature.Sync_Disability_Designation__c == true){
            if(!String.isBlank(party.Truelink_Disability_Designation__c) && !disabilities.isEmpty() && disabilities.containskey(party.Truelink_Disability_Designation__c)){
                reqWrapper.data.relationships.disabilityDesignation.data.type = 'disability_designation';
                reqWrapper.data.relationships.disabilityDesignation.data.id = disabilities.get(party.Truelink_Disability_Designation__c).Truelink_Internal_ID__c;
            }
            else {
                reqWrapper.data.relationships.disabilityDesignation = null;
            }
        }
        else {
            reqWrapper.data.relationships.disabilityDesignation = null;
        }

        return reqWrapper;
    }
    
    public TruelinkBeneficiaryAddressRequestWrapper buildAddress(String partyId, String addressId){
        Contact party = [Select Id, Salutation__c,firstname,Middle_Name__c,lastname,
                         Suffix_individual__c,email,EIN__c,Social_Security_Number__c,Birthdate,
                         MobilePhone,GenderIdentity,Living_Street_1__c,Living_Street_2__c,Living_City__c,Living_State__c,Living_Zip_Code__c,
                         Marital_Status__c, Truelink_Disability_Designation__c //,Living_Situation__c
                         from contact where Id =: partyId];
        
        
        TruelinkBeneficiaryAddressRequestWrapper reqWrapper = new TruelinkBeneficiaryAddressRequestWrapper();
        if(!String.isBlank(party.Living_Street_1__c))
        	reqWrapper.data.attributes.street1 = party.Living_Street_1__c;
        if(!String.isBlank(party.Living_Street_2__c))
        	reqWrapper.data.attributes.street2 = party.Living_Street_2__c;
        reqWrapper.data.type = 'address';
        //reqWrapper.data.id = addressId;
        if(!String.isBlank(party.Living_City__c))
        	reqWrapper.data.attributes.city = party.Living_City__c;
        if(!String.isBlank(party.Living_State__c))
        	reqWrapper.data.attributes.state = party.Living_State__c;
        if(!String.isBlank(party.Living_Zip_Code__c))
        	reqWrapper.data.attributes.zip = party.Living_Zip_Code__c;
        
        return reqWrapper;
    }
    
    public TruelinkBeneficiaryRequestWrapper buildRequestForTrustDisbursement(String trustId){
        trust__c trust = new trust__c();
        if(trustId!=null && trustId!=''){
            trust = [Select Disbursement_Creation_Enabled__c,Mail_statements__c from trust__c where Id =: trustId];
        }
        
        TruelinkBeneficiaryRequestWrapper reqWrapper = new TruelinkBeneficiaryRequestWrapper(true);
        reqWrapper.data.attributes.disallowDisbursementRequests = !Boolean.valueof(trust.Disbursement_Creation_Enabled__c);
        reqWrapper.data.attributes.mailStatement = trust.Mail_statements__c;

        return reqWrapper;
    }
    
    public TruelinkBeneficiaryRequestWrapper buildRequestForEinBidUpdate(String trustId){
        trust__c trust = new trust__c();
        if(trustId!=null && trustId!=''){
            trust = [Select Internal_Account_Number__c,Trust_Type__c,TL_EID__c,TL_BID__c from trust__c where Id =: trustId];
        }
        
        TruelinkBeneficiaryRequestWrapper reqWrapper = new TruelinkBeneficiaryRequestWrapper(true);
		reqWrapper.data.attributes.externalId = trust.TL_EID__c;
        reqWrapper.data.attributes.beneficiaryId = trust.TL_BID__c;

        return reqWrapper;
    }
}