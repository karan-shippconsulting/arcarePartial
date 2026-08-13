public class TrueLinkApiHandler {
    public static void createTrustBeneficiary(String partyId, String trustPartyId){
        String trustid = getTrustId(trustPartyId);
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndpoint('/trusts/'+trustid+'/trust_beneficiaries')
                .setMethod('POST')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().build(partyId, trustPartyId, null, false),true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = TrueLinkResponseWrapper.parse(exec.send().getBody());      
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = partyId;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                try{
                    String beneficiaryId = (String)response?.data?.id;
                    String addressId = (String)response?.data?.relationships?.address?.data?.id;
                    String trustBeneficiaryInternalId = (String)response?.data?.attributes?.trustBeneficiaryInternalId;
                    if( (beneficiaryId != null && String.isNotEmpty(beneficiaryId)) || Test.isRunningtest() ){
                        Trust__c toUpdate = new Trust__c(Id=trustPartyId,TrueLink_ID__c=beneficiaryId);
                        toUpdate.Truelink_Address_Id__c = addressId;
                        toUpdate.True_Link_ID_from_TL_Profile__c = trustBeneficiaryInternalId;
                        toUpdate.True_Link_Status__c = response?.data?.attributes?.status;
                        update toUpdate;
                    }
                }
                catch(Exception e){
                    exec.logData('Error While Parsing Response. => '+ e.getMessage() + '=>' + e.getStackTraceString());
                }
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());
        }
        
    }
    
    public static void updateTrustBeneficiaryAddress(String partyId, String addressId){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndPoint('/addresses/'+addressId)
                .setMethod('PATCH')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().buildAddress(partyId, addressId),true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = new TrueLinkResponseWrapper();
           // if(!Test.isRunningTest())
                response = TrueLinkResponseWrapper.parse(exec.send().getBody());
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = partyId;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Contact con = new Contact(Id=partyId,Update_True_Link__c=false);
                update con;   
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());            
        }
    }
    
    public static void updateConnection(String connectionId){
        Connections__c con = [Select Id, True_Link_Id__c, First_Name__c, Last_Name__c, Mobile__c, Email__c,
                               Company_Name__c, Notes__c, Street_1__c, Street_2__c, City__c, State__c, Zip__c,
                               Relationship_Types__c, Is_Statement_Recipient__c,
                               Trust__c, Trust__r.TrueLink_ID__c
                               from Connections__c where Id =: connectionId limit 1];
        if(String.isBlank(con.True_Link_Id__c) || con.Trust__c == null || String.isBlank(con.Trust__r.TrueLink_ID__c)){
            throw new ApiException('Missing True_Link_Id__c or Trust TrueLink_ID__c for Connection: ' + connectionId);
        }
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            TrueLinkConnectionUpdateRequestWrapper reqWrapper = new TrueLinkConnectionUpdateRequestWrapper();
            reqWrapper.data.id = con.True_Link_Id__c;
            reqWrapper.data.attributes.firstName = con.First_Name__c;
            reqWrapper.data.attributes.lastName = con.Last_Name__c;
            reqWrapper.data.attributes.mobile = con.Mobile__c;
            reqWrapper.data.attributes.email = con.Email__c;
            reqWrapper.data.attributes.companyName = con.Company_Name__c;
            reqWrapper.data.attributes.notes = con.Notes__c;
            reqWrapper.data.attributes.street1 = con.Street_1__c;
            reqWrapper.data.attributes.street2 = con.Street_2__c;
            reqWrapper.data.attributes.city = con.City__c;
            reqWrapper.data.attributes.state = con.State__c;
            reqWrapper.data.attributes.zip = con.Zip__c;

            if(String.isNotBlank(con.Relationship_Types__c)){
                reqWrapper.data.relationships.connectionRelationship.data.attributes.relationshipTypes = con.Relationship_Types__c.split(';');
            }
            reqWrapper.data.relationships.connectionRelationship.data.attributes.isStatementRecipient = con.Is_Statement_Recipient__c;

            exec.setEndPoint('/trust_beneficiaries/' + con.Trust__r.TrueLink_ID__c + '/connections/' + con.True_Link_Id__c)
                .setMethod('PATCH')
                .setBody(JSON.serialize(reqWrapper, true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            exec.send();
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = con.Id;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Connections__c toUpdate = new Connections__c(Id=con.Id, Update_True_Link__c=false);
                update toUpdate;
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());
        }
    }

    public static void updateTrustBeneficiary(String partyId, String trustPartyId, String beneficaryId){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndPoint('/trust_beneficiaries/'+beneficaryId)
                .setMethod('PATCH')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().build(partyId, trustPartyId, beneficaryId, true), true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = TrueLinkResponseWrapper.parse(exec.send().getBody());     
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = partyId;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Contact con = new Contact(Id=partyId,Update_True_Link__c=false);
                update con;               
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());            
        }
        
    }
    public static void createTrustBeneficiaryAddress(String partyId,String trueLinkID){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndPoint('/trust_beneficiaries/'+trueLinkID+'/addresses/')
                .setMethod('POST')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().buildAddress(partyId, null),true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = new TrueLinkResponseWrapper();
           // if(!Test.isRunningTest())
                response = TrueLinkResponseWrapper.parse(exec.send().getBody());
                String addressId = (String)response.data.relationships?.address?.data?.id;
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = partyId;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Contact toUpdate = new Contact(Id=partyId,Truelink_Address_Id__c = addressId,Update_True_Link__c = false);
                update toUpdate;          
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());            
        }
    }
    
    public static void updateTrust(String trustPartyId, String trustTruelinkId){        
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndPoint('/trust_beneficiaries/'+trustTruelinkId)
                .setMethod('PATCH')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().buildRequestForTrustDisbursement(trustPartyId),true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = new TrueLinkResponseWrapper();
                response = TrueLinkResponseWrapper.parse(exec.send().getBody());
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = trustPartyId;
            update trackObj;
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());            
        }
        
    }
    
    public static void updateTrustForEinAndBid(String trustPartyId, String trustTruelinkId){        
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            exec.setEndPoint('/trust_beneficiaries/'+trustTruelinkId)
                .setMethod('PATCH')
                .setBody(JSON.serialize(new TruelinkBeneficiaryRequestBuilder().buildRequestForEinBidUpdate(trustPartyId),true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            TrueLinkResponseWrapper response = new TrueLinkResponseWrapper();
                response = TrueLinkResponseWrapper.parse(exec.send().getBody());
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = trustPartyId;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Trust__c trust = new Trust__c(Id=trustPartyId, Update_EIN_and_BID__c = false);
                update trust;
                TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());            
        }
        
    }
    
    @AuraEnabled @future(callout=true)
    public static void updateAccountBalanceAsync(String trustId){
        //try{
            updateAccountBalance(trustId);    
        //}catch(AuraHandledException e){}
        
    }
    
    @AuraEnabled @future(callout=true)
    public static void updateDepositAsync(String trustId){
        //try{
            updateDeposit(trustId);    
        //}catch(AuraHandledException e){}
        
    }
    
    @AuraEnabled @future(callout=true)
    public static void updateDisbursementAsync(String trustId){
        //try{
            updateDisbursement(trustId);    
        //}catch(AuraHandledException e){}
        
    }
    
    @AuraEnabled
    public static void updateAccountBalance(String trustId){
        map<string,Beneficiary_Card__c> cardReferenceVsObjectMap = new map<string,Beneficiary_Card__c>();
        trust__c trust = [Select Id,TrueLink_ID__c,Beneficiary__c,True_Link_Balance__c,Trust_Status__c,Trust_Portfolio__c, Trust_Portfolio__r.True_Link_Portfolio_ID__c from trust__c where Id =: trustId limit 1];
        Set<String> allowedTrustStatus = getEligibleTrustStatuses();
            if(!allowedTrustStatus.contains(trust.Trust_Status__c)){
                throw new ApiException('Trust Status should be one of: ' + String.join(new List<String>(allowedTrustStatus), ', '));
            }/*else if(trust.RecordType.Name != 'Trust'){
                throw new AuraHandledException('Record Type is not Trust');
            }*/
        if(String.isNotEmpty(trust.TrueLink_ID__c)){
            TruelinkBeneficiaryRequestWrapper response = new TruelinkBeneficiaryRequestWrapper();
            //try{
                response = fetchAccountBalance(trust.Id,trust.TrueLink_ID__c);
            //}catch(Exception e){}
            
            Decimal balance = response?.data?.meta?.totalAccountBalance;
            Decimal availableCashSum = response?.data?.meta?.availableCashSum?.amount;
            string portfolioId = response?.data?.relationships?.activePortfolio?.data?.id;
            String addressId = response?.data?.relationships?.address?.data?.id;
            String truelinkAccountId = response?.data?.relationships?.accounts?.data.size()>0 ? response?.data?.relationships?.accounts?.data[0].id : '';
            system.debug('truelinkAccountId:'+truelinkAccountId);
            if(response!=null && response.data!=null){
                if(response.included!=null){
                    System.debug('response.included -- ' + response.included);
                    for(TruelinkBeneficiaryRequestWrapper.cls_included include : response.included){
                        if(include!=null && !String.isEmpty(include.id) && include.attributes!=null){
                            if(include.attributes.cardReference == null) {
                                continue;
                            }
                            system.debug('truelinkAccountId:'+truelinkAccountId);
                            Beneficiary_Card__c	beneCard = new Beneficiary_Card__c	();
                            beneCard.Beneficiary__c	= trust.Beneficiary__c;
                            beneCard.Trust__c = trust.Id;
                            beneCard.Program__c = include.attributes.program;
                            beneCard.Last_4_Digits__c = include.attributes.lastFour;
                            beneCard.Card_Reference__c = include.attributes.cardReference;
                            beneCard.Status__c = include.attributes.status;
                            beneCard.Expiry_Date__c = include.attributes.expiryDate != null ? Date.valueof(include.attributes.expiryDate) : null;
                            beneCard.Balance__c = include.attributes.balance?.amount;
                            beneCard.Is_Breached__c = include.attributes.isBreached;
                            beneCard.Breach__c = include.attributes.breach;
                            beneCard.Fraud_Block_Type__c = include.attributes.fraudBlockType;
                            beneCard.Card_Id__c = include.id;
                            beneCard.Type__c = include.type;
                            beneCard.Name = include.attributes.cardReference;
                            String cleaned = include.attributes.balance?.timestamp.replace('T',' ').replace('Z','');
                            if (cleaned != null && cleaned.contains('.')) {
                                cleaned = cleaned.substring(0, cleaned.indexOf('.'));
                            }
                            beneCard.last_balance_update__c = cleaned != null ? datetime.valueof(cleaned) : null;
                            cardReferenceVsObjectMap.put(include.attributes.cardReference,beneCard);
                        }
                    }
                }   
            }
            system.debug('cardReferenceVsObjectMap: '+ cardReferenceVsObjectMap);
 
            List<Trust_Portfolio__c> newPortfolio = [select id from Trust_Portfolio__c where True_Link_Portfolio_ID__c=:portfolioId];
            if(newPortfolio!=null && newPortfolio.size() > 0){
                trust.Trust_Portfolio__c = newPortfolio[0].Id;
            }
            if(!String.isBlank(addressId))
                trust.Truelink_Address_Id__c = addressId;
            
            trust.True_Link_Balance__c=balance; 
            trust.Effective_Balance__c = availableCashSum;
            trust.Truelink_Account_Id__c = truelinkAccountId;
           if(response?.data?.attributes?.chargeSetupFee!=null){
                trust.Charge_Initial_Set_up_Fee_300__c = response?.data?.attributes?.chargeSetupFee;
            }
            if(response?.data?.attributes?.disallowDisbursementRequests!=null){
                trust.Disbursement_Creation_Enabled__c = !response.data.attributes.disallowDisbursementRequests;
            }
            trust.taxDocRecipientConnectionId__c = response?.data?.attributes?.taxDocRecipientConnectionId;
            if(trust!=null){
                if(!Test.isRunningTest())
                    update trust;
                if(cardReferenceVsObjectMap!=null && cardReferenceVsObjectMap.size()>0){
                    upsert cardReferenceVsObjectMap.values() Card_Reference__c;
                }
                TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;
            }
        }  
    }
    
    public static TruelinkBeneficiaryRequestWrapper fetchAccountBalance(String trustId,String beneficaryId){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c)
            .setEndPoint('/trust_beneficiaries/'+beneficaryId)
            .setMethod('GET')
            .setHeader('Authorization', tldata.ApiKey__c)
            .setHeader('Content-Type','application/json');
        
        Map<String,String> params = new Map<String,String>();
        params.put('fields[trust_beneficiary.analysis]','accounts,totalAccountBalance,availableCashSum');
        params.put('include','primaryCard,organizationCard');
        
        exec.setParams(params);
//      Map<String,Object> resMap = (Map<String,Object> )JSON.deserializeUntyped(exec.send().getBody());        
        String resBody = exec.send().getBody();
        Track_API_Call__c trackObj = exec.getTrackObj();
        trackObj.Parent_Record_Id__c = trustId;
        update trackObj;
        

        if(trackObj.Status__c == 'Success' || Test.isRunningTest()){
            try{
                //return (Decimal)((Map<String,Object>)((Map<String,Object>)resMap.get('data')).get('meta')).get('totalAccountBalance');
                return (TruelinkBeneficiaryRequestWrapper)JSON.deserialize(resBody,TruelinkBeneficiaryRequestWrapper.class);
            }
            catch(Exception e){
                exec.logData('Error While Parsing Response. => '+ e.getMessage() + '=>' + e.getStackTraceString());
                return null;
            }
            
        }else{                
            return null;
        }
        
    }
    
    @AuraEnabled
    public static void updateDeposit(String trustId){
        system.debug('trustId'+trustId);
        trust__c trust = [Select Id,TrueLink_ID__c,True_Link_Balance__c,Trust_Status__c,Trust_Portfolio__c, Trust_Portfolio__r.True_Link_Portfolio_ID__c from trust__c where Id =: trustId limit 1];
        Set<String> allowedTrustStatus = getEligibleTrustStatuses();
        if(!allowedTrustStatus.contains(trust.Trust_Status__c)){
            throw new ApiException('Trust Status should be one of: ' + String.join(new List<String>(allowedTrustStatus), ', '));
        }
        if(String.isNotEmpty(trust.TrueLink_ID__c)){
            TruelinkTransactionResponseWrapper response = new TruelinkTransactionResponseWrapper();
            //try{
                response = fetchDeposits(trust.Id,trust.TrueLink_ID__c);
            //} catch(Exception e){}
            system.debug('Deposit response'+response);
            list<Transaction__c> tranxList = new list<Transaction__c>();
            if(response!=null && response.data!=null){
                for(TruelinkTransactionResponseWrapper.cls_data dta : response.data){
                    Transaction__c tranx = new Transaction__c();
                    tranx.Trust__c = trust.Id;
                    tranx.True_Link_Transaction_ID__c = dta.Id;
                    tranx.Status__c = dta.attributes.status;
                    tranx.Type__c = dta.type;
                    tranx.Cleared_Date__c = dta.attributes.clearedDate!=null && String.isEmpty(dta.attributes.clearedDate)!=null ? Date.valueof(dta.attributes.clearedDate) : null;
                    tranx.Delivery_Date__c = dta.attributes.deliveryDate!=null && !String.isEmpty(dta.attributes.deliveryDate) ? Date.valueof(dta.attributes.deliveryDate) : null;
                    tranx.Merchant_Name__c = dta.attributes.merchant;
                    tranx.PaymentID__c = dta.attributes.paymentId!=null ? dta.attributes.paymentId : '';
                    /*tranx.Name = dta.attributes.merchant;*/
                     tranx.Name = dta.attributes.merchant != null
                    ? (dta.attributes.merchant.length() > 80 
                        ? dta.attributes.merchant.substring(0, 80) 
                        : dta.attributes.merchant)
                    : null;

                    tranx.Currency__c = dta.attributes.amount!=null ? dta.attributes.amount.field_currency : '';
                    tranx.Amount__c = dta.attributes.amount!=null ? dta.attributes.amount.amount : null;
                    tranx.Payment_Method__c = dta.attributes?.paymentMethod;
                    tranxList.add(tranx);
                }
                system.debug('Deposit tranxList'+tranxList);
               if(!tranxList.isEmpty())
                    upsert tranxList True_Link_Transaction_ID__c;
            }
        }  
    }
    
    public static TruelinkTransactionResponseWrapper fetchDeposits(String trustId,String beneficaryId){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c)
            .setEndPoint('/trust_beneficiaries/'+beneficaryId+'/deposits/')
            .setMethod('GET')
            .setHeader('Authorization', tldata.ApiKey__c)
            .setHeader('Content-Type','application/json');
        
        Map<String,String> params = new Map<String,String>();
        if(feature.Deposit_Last_Run_Datetime__c!=null){
            datetime lastRunDateWithLookback = feature.Deposit_Last_Run_Datetime__c.addMinutes((Integer)(-1*feature.Lookback_Period_In_Minutes__c));
            String formatedDt = lastRunDateWithLookback.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            params.put('filter[updatedAt][gte]',formatedDt);
        }
        params.put('page[number]','1');
        params.put('page[size]','2500');
        
        exec.setParams(params);
//        Map<String,Object> resMap = (Map<String,Object> )JSON.deserializeUntyped(exec.send().getBody());        
        String resBody = exec.send().getBody();
        system.debug('Deposit resBody'+resBody);
        Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = trustId;
            update trackObj;
        

        if(trackObj.Status__c == 'Success' || Test.isRunningTest()){
            try{
                //return (Decimal)((Map<String,Object>)((Map<String,Object>)resMap.get('data')).get('meta')).get('totalAccountBalance');
                return (TruelinkTransactionResponseWrapper)JSON.deserialize(resBody,TruelinkTransactionResponseWrapper.class);
            }
            catch(Exception e){
                exec.logData('Error While Parsing Response. => '+ e.getMessage() + '=>' + e.getStackTraceString());
                return null;
            }
            
        }else{                
            return null;
        }
        
    }
    
    @AuraEnabled
    public static void updateDisbursement(String trustId){
        trust__c trust = [Select Id,TrueLink_ID__c,True_Link_Balance__c,Trust_Status__c,Trust_Portfolio__c, Trust_Portfolio__r.True_Link_Portfolio_ID__c from trust__c where Id =: trustId limit 1];
        Set<String> allowedTrustStatus = getEligibleTrustStatuses();
        Set<String> disbursementTruelinkTransactionIdsSet = new Set<String>();
        Map<String, String> disbursementIdToAttachmentIdMap = new Map<String, String>();
        if(!allowedTrustStatus.contains(trust.Trust_Status__c)){
            throw new ApiException('Trust Status should be one of: ' + String.join(new List<String>(allowedTrustStatus), ', '));
        }
        if(String.isNotEmpty(trust.TrueLink_ID__c)){
            TruelinkTransactionResponseWrapper response = new TruelinkTransactionResponseWrapper();
            //try{
                response = fetchDisbursements(trust.Id,trust.TrueLink_ID__c);
            //} catch(Exception e){}
            system.debug('Disbursement response'+response);
            list<Transaction__c> tranxList = new list<Transaction__c>();
            if(response!=null && response.data!=null){
                map<string,string> categoryIdVsNotesMap = new map<string,string>();
                map<string,string> categoryIdVsRecurringTypeMap = new map<string,string>();
                map<string,string> categoryIdVsFrequencyMap = new map<string,string>();
                if(response.included!=null){
                    for(TruelinkTransactionResponseWrapper.cls_included include : response.included){
                        if(include!=null && !String.isEmpty(include.id) && include.attributes!=null && !String.isEmpty(include.attributes.notes))
                            categoryIdVsNotesMap.put(include.id,include.attributes.notes);
                        if(include!=null && !String.isEmpty(include.id) && include.attributes!=null){
                            if(!String.isEmpty(include.attributes.recurringType))
                                categoryIdVsRecurringTypeMap.put(include.id,include.attributes.recurringType);
                            if(include.attributes.frequency!=null)
                                categoryIdVsFrequencyMap.put(include.id,String.valueof(include.attributes.frequency));
                        }
                    }
                }   
                system.debug('categoryIdVsRecurringTypeMap: '+categoryIdVsRecurringTypeMap );
                system.debug('categoryIdVsFrequencyMap: '+categoryIdVsFrequencyMap );
                for(TruelinkTransactionResponseWrapper.cls_data dta : response.data) {
                    disbursementTruelinkTransactionIdsSet.add(dta.Id);
                }         
                List<Transaction__c> disbursementList = [SELECT id, True_Link_Transaction_ID__c, Attachment_Id__c, Attachment_URL__c from Transaction__c 
                                                            Where True_Link_Transaction_ID__c IN: disbursementTruelinkTransactionIdsSet];
                for(Transaction__c tranx : disbursementList) {
                    disbursementIdToAttachmentIdMap.put(tranx.True_Link_Transaction_ID__c, tranx.Attachment_Id__c);
                }
                for(TruelinkTransactionResponseWrapper.cls_data dta : response.data){
                    Transaction__c tranx = new Transaction__c();
                    tranx.Trust__c = trust.Id;
                    tranx.True_Link_Transaction_ID__c = dta.Id;
                    tranx.Type__c = dta.type;
                    tranx.Delivery_Date__c = dta.attributes.clearedDate!=null && String.isEmpty(dta.attributes.deliveryDate)!=null ? Date.valueof(dta.attributes.deliveryDate) : null;
                    tranx.Cleared_Date__c = dta.attributes.clearedDate!=null && String.isEmpty(dta.attributes.clearedDate)!=null ? Date.valueof(dta.attributes.clearedDate) : null;
                    tranx.Processed_Date__c = dta.attributes.processedDate!=null && String.isEmpty(dta.attributes.processedDate)!=null ? Date.valueof(dta.attributes.processedDate) : null;
                    if(dta.relationships!=null && dta.relationships.categoryAmounts!=null && dta.relationships.categoryAmounts.data!=null 
                       && dta.relationships.categoryAmounts.data.size() > 0 && dta.relationships.categoryAmounts.data[0].type == 'disbursement_category_amount'
                       && !String.isEmpty(dta.relationships.categoryAmounts.data[0].id) && categoryIdVsNotesMap!=null){
                           String key = dta.relationships.categoryAmounts.data[0].id;
                           tranx.Internal_Notes__c = categoryIdVsNotesMap.containskey(key) && categoryIdVsNotesMap.get(key).length() > 255 ? categoryIdVsNotesMap.get(key).substring(0,255) : categoryIdVsNotesMap.get(key);
                    }
                    system.debug('dta.relationships: '+dta.relationships );

                    if(dta.relationships!=null && dta.relationships.recurringDisbursement!=null && dta.relationships.recurringDisbursement.data!=null 
                       && dta.relationships.recurringDisbursement.data.type == 'recurring_disbursement' && !String.isEmpty(dta.relationships.recurringDisbursement.data.id)){
                            system.debug('dta.relationships.recurringDisbursement.data.id: '+dta.relationships.recurringDisbursement.data.id );
                            String key = dta.relationships.recurringDisbursement.data.id;
                            if(categoryIdVsRecurringTypeMap.size() > 0){
                                tranx.Recurring_Type__c = categoryIdVsRecurringTypeMap.containskey(key) ? categoryIdVsRecurringTypeMap.get(key) : '';
                            }
                            if(categoryIdVsFrequencyMap.size() > 0){
                                tranx.Frequency__c = categoryIdVsFrequencyMap.containskey(key) ? categoryIdVsFrequencyMap.get(key) : '';
                            }                           
                       }
                    system.debug('tranx frequency: '+tranx.Recurring_Type__c + ' ' +  tranx.Frequency__c);
                    if(dta.meta!=null && !String.isBlank(dta.meta.displayCategory) ){
                           tranx.Display_Category__c = dta.meta.displayCategory;
                       }
                    
                    
                    tranx.Currency__c = dta.attributes.amount!=null ? dta.attributes.amount.field_currency : '';
                    tranx.Amount__c = dta.attributes.amount!=null ? dta.attributes.amount.amount : null;
                    tranx.Payment_Method__c = dta.attributes.paymentMethod;
                    tranx.status__c = dta.attributes.status;
                    tranx.Requestor_Description__c = dta.attributes.requestorDescription!=null ? dta.attributes.requestorDescription : '';
                    tranx.Requested_By_Signature__c = dta.attributes.requestedBySignature!=null ? dta.attributes.requestedBySignature : '';
                    tranx.Payee_Name__c = dta.attributes.payeeName;
                    tranx.fromRecurring__c = dta.attributes.fromRecurring!=null ? dta.attributes.fromRecurring : false;
                  /*  tranx.Name = dta.attributes.payeeName;*/
                    tranx.Name = dta.attributes.payeeName != null
                        ? (dta.attributes.payeeName.length() > 80 
                            ? dta.attributes.payeeName.substring(0, 80) 
                            : dta.attributes.payeeName)
                        : null;

                    tranx.Payee_Description__c = dta.attributes.payeeDescription;
                    tranx.Payee_Disposition__c = dta.attributes.payeeDisposition;
                    tranx.Postage_Code__c = dta.attributes.postageCode;
                    tranx.Postage_Type__c = dta.attributes.postageType;
                    tranx.Check_Num__c = dta.attributes.checkNum!=null && !String.isEmpty(dta.attributes.checkNum) ? Decimal.valueof(dta.attributes.checkNum) : null;
                    tranx.Check_Memo_Line__c = dta.attributes.checkMemoLine;
                    tranx.Payee_Memo__c = dta.attributes.payeeMemo;
                    tranx.Payee_swift_code__c = dta.attributes.payeeSwiftCode;
                    if(dta.attributes.payeeSpecialInstructions!=null && dta.attributes.payeeSpecialInstructions!='' && dta.attributes.payeeSpecialInstructions.length() > 255){ 
                        tranx.Payee_Special_Instructions__c = dta.attributes.payeeSpecialInstructions.substring(0, 255);
                    }else{
                        tranx.Payee_Special_Instructions__c = dta.attributes.payeeSpecialInstructions;
                    }
                    
                    tranx.Payee_Street_1__c = dta.attributes.payeeAddress!=null && dta.attributes.payeeAddress.street1!=null ? dta.attributes.payeeAddress.street1 : '';
                    tranx.Payee_Street_2__c = dta.attributes.payeeAddress!=null && dta.attributes.payeeAddress.street2!=null ? dta.attributes.payeeAddress.street2 : '';
                    tranx.Payee_City__c = dta.attributes.payeeAddress!=null && dta.attributes.payeeAddress.city!=null ? dta.attributes.payeeAddress.city : '';
                    tranx.Payee_State__c = dta.attributes.payeeAddress!=null && dta.attributes.payeeAddress.state!=null ? dta.attributes.payeeAddress.state : '';
                    tranx.Payee_Zip__c = dta.attributes.payeeAddress!=null && dta.attributes.payeeAddress.zip!=null ? dta.attributes.payeeAddress.zip : '';
                    
                    tranx.Routing_Number__c = dta.attributes.payeeBankAccount!=null ? dta.attributes.payeeBankAccount.routingNumber : '';
                    tranx.Bank_Account_Number__c = dta.attributes.payeeBankAccount!=null ? dta.attributes.payeeBankAccount.accountNumber : '';

                    if(disbursementIdToAttachmentIdMap.containsKey(tranx.True_Link_Transaction_ID__c)
                        && disbursementIdToAttachmentIdMap.get(tranx.True_Link_Transaction_ID__c) == null
                        && dta.relationships != null && dta.relationships.attachments != null
                        && dta.relationships.attachments.data != null
                        && !dta.relationships.attachments.data.isEmpty()) {
                        tranx.Attachment_Id__c = dta.relationships.attachments.data[0].id;
                        disbursementIdToAttachmentIdMap.put(tranx.True_Link_Transaction_ID__c, tranx.Attachment_Id__c);
                    }
                    tranxList.add(tranx);
                }
                system.debug('Disbursement tranxList'+tranxList);
                if(!tranxList.isEmpty()){
                    List<Database.UpsertResult> upsertResults = Database.upsert(tranxList, Transaction__c.True_Link_Transaction_ID__c, false);
                    List<Track_API_Call__c> failureLogs = new List<Track_API_Call__c>();
                    for(Integer i = 0; i < upsertResults.size(); i++){
                        if(!upsertResults[i].isSuccess()){
                            List<String> errorMessages = new List<String>();
                            for(Database.Error err : upsertResults[i].getErrors()){
                                errorMessages.add(err.getStatusCode() + ': ' + err.getMessage());
                            }
                            failureLogs.add(new Track_API_Call__c(
                                Parent_Record_Id__c = trust.Id,
                                Status__c = 'Error',
                                Error_Message__c = 'Error While Upserting Disbursement Transaction (True_Link_Transaction_ID__c=' + tranxList[i].True_Link_Transaction_ID__c + '). => ' + String.join(errorMessages, ' | ')
                            ));
                        }
                    }
                    if(!failureLogs.isEmpty()){
                        insert failureLogs;
                    }
                }
                System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trust.Id));
            }
        }  
    }
    
    public static TruelinkTransactionResponseWrapper fetchDisbursements(String trustId,String beneficaryId){
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c)
            .setEndPoint('/trust_beneficiaries/'+beneficaryId+'/disbursements/')
            .setMethod('GET')
            .setHeader('Authorization', tldata.ApiKey__c)
            .setHeader('Content-Type','application/json');
        
        Map<String,String> params = new Map<String,String>();
        if(feature.Disbursement_Last_Run_Datetime__c!=null){
            datetime lastRunDateWithLookback = feature.Disbursement_Last_Run_Datetime__c.addMinutes((Integer)(-1*feature.Lookback_Period_In_Minutes__c));
            String formatedDt = lastRunDateWithLookback.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            params.put('filter[updatedAt][gte]',formatedDt);
        }
        params.put('page[number]','1');
        params.put('page[size]','2500');
        params.put('include','categoryAmounts,recurringDisbursement');
        params.put('fields[disbursement.analysis]','displayCategory');
        
        exec.setParams(params);
//        Map<String,Object> resMap = (Map<String,Object> )JSON.deserializeUntyped(exec.send().getBody());        
        String resBody = exec.send().getBody();
        system.debug('Disbursement resBody'+resBody);
        Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = trustId;
            if(trackObj!=null && trackObj.id!=null)
                update trackObj;
        

        if(trackObj.Status__c == 'Success' || Test.isRunningTest()){
            try{
                //return (Decimal)((Map<String,Object>)((Map<String,Object>)resMap.get('data')).get('meta')).get('totalAccountBalance');
                return (TruelinkTransactionResponseWrapper)JSON.deserialize(resBody,TruelinkTransactionResponseWrapper.class);
            }
            catch(Exception e){
                exec.logData('Error While Parsing Response. => '+ e.getMessage() + '=>' + e.getStackTraceString());
                return null;
            }
            
        }else{                
            return null;
        }
        
    }
    
    public static Set<String> getEligibleTrustStatuses(){
        Set<String> statuses = new Set<String>();
        for(Truelink_Trust_Status__mdt s : Truelink_Trust_Status__mdt.getAll().values()){
            statuses.add(s.Status_Value__c);
        }
        return statuses;
    }

    private static String getTrustId(String trustPartyId){
        List<Pooled_Trust__c> pc = [Select Id,Trust_Id__c from Pooled_Trust__c where Id IN (Select Pooled_Trust__c from Trust__c where Id=:trustPartyId) limit 1];
        if(pc.isEmpty())
            throw new ApiException('No Pool Trust Records Found for Id : '+ trustPartyId);
        return pc[0].Trust_Id__c;
    }
    
    public class ApiException extends Exception{}
    
}