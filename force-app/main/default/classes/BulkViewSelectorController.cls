/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

// change class name to BulkViewSelectorController
public class BulkViewSelectorController {
    public List<Opportunity> opportunities;
    public String opportunityIds{get;set;}

    public final static String CONTENT_FOLDER_NAME = 'Generated Invoices' ;
    public final static String EMAIL_TEMPLATE_NAME = getBulkSelector('Bulk_Print_Selector').Email_Template_Name__c;//'InvoiceTemplate' ;
    public final static String SENDER_EMAIL = getBulkSelector('Bulk_Print_Selector').Org_wide_address__c;//'Arcare_EMAIL' ; // OWD Name
    public final static String VF_PAGE_DOMAIN = System.Label.BulkPrintVFPageURL; //'https://cfpd--partial--c.sandbox.vf.force.com/apex/' ; // OWD Name
    public final static String TargeObjceAccountID = System.Label.BulkPrintTargetObjectId; //'003Ot00000SVXCWIA5';

    public final static Map<String,Object> keywordWithValues = new Map<String,Object> {
        'Now' => System.now(),
        'Today' => System.Today(),
        'NOW' => System.now(),
        'TODAY' => System.Today()
    }; 

    public final static Map<String,String> userActionsWithRecord = new Map<String,String> {
        'Print Preview' => 'Print',
        'Print and Update' => 'Print',
        'Email and Update' => 'Email'
    }; 
    
    public BulkViewSelectorController(ApexPages.StandardSetController cntlr){
        opportunities = cntlr.getSelected(); //get selected records from account list view
        List<String> oppIds = new List<String>();
        for(Opportunity op : opportunities){
            oppIds.add(op.Id);                      
        }
        opportunityIds = String.join(oppIds,';');
    } 

    @AuraEnabled
    public static String vfPageSelector(List<String> selectedRecords,String userActions){
        try {
            String objectName = BulkViewSelectorController.findObjectNameFromRecordIdPrefix(selectedRecords[0]);
            String query = 'SELECT id,Object_API_Name__c,Fields_Values_to_Update_For_Email__c,Fields_Values_to_Update_For_Print__c,'+
            'Visual_Force_Page_Name__c,Fields_to_Update_For_Email__c,Fields_to_Update_For_Print__c,Print_Type__c,'+
            'Sub_Type__c,Recipient_Address_Field__c,File_Name__c,Service_Enrollment_Master_Field__c'+
            ' FROM Visualforce_PDF__c WHERE ';

            if( String.isNotBlank(objectName) ){
                query = query + ' Object_API_Name__c=: objectName';
            }
            if( String.isNotBlank(userActions) ){
                String actions = userActionsWithRecord.get(userActions);
                query = query + ' AND Sub_Type__c=: actions ';
            }
            
            Map<String,List<String>> opportunityWithFiles = new Map<String,List<String>>();
            Map<Id, Visualforce_PDF__c> vfpages = new Map<Id,Visualforce_PDF__c>((List<Visualforce_PDF__c>)Database.query(query));

           
            for(String vf_Page : vfpages.keySet()){
                for(String  selectedRecord : selectedRecords) {
                    if(opportunityWithFiles.containsKey(vf_Page)){
                        opportunityWithFiles.get(vf_Page).add(selectedRecord);
                    } else {
                        opportunityWithFiles.put(vf_Page, new List<String>{selectedRecord});
                    }
                }
            }

            if( userActions == 'Print Preview' ){
                Map<ID, Opportunity> opportunityWithID = new Map<ID, Opportunity>([SELECT Id,Service_Enrollment__r.Billing_Email__c,
                    Service_Enrollment__c,Bill_Date__c,
                    Service_Enrollment__r.Copy_1_Email__c, Service_Enrollment__r.Copy_2_Email__c, 
                    Service_Enrollment__r.Mail_To_Email__c,
                    Service_Enrollment__r.Billing_Attention_To__c,
                    Service_Enrollment__r.Copy1_Attention_To__c, 
                    Service_Enrollment__r.Copy2_Attention_To__c, 
                    Service_Enrollment__r.Mail_To_Attention__c,
                    Service_Enrollment__r.Billing_Invoice_Options__c,
                    Service_Enrollment__r.Copy_1_Invoice_Options__c,
                    Service_Enrollment__r.Copy_2_Invoice_Options__c,
                    Service_Enrollment__r.Mail_To_Invoice_Options__c FROM 
                    Opportunity WHERE Id in: selectedRecords]);

                return printPreview(opportunityWithFiles, opportunityWithID, vfpages);
            } else if ( userActions == 'Email and Update' ){
                //updateOpportunityForEmail(opportunityWithFiles, objectName, selectedRecords, vfpages);
                updateOpportunityWithAction('Email', opportunityWithFiles, objectName, selectedRecords, vfpages);
            } else if( userActions == 'Print and Update') {
                //updateOpportunityForPrint(opportunityWithFiles, objectName, selectedRecords, vfpages);
                updateOpportunityWithAction('Print', opportunityWithFiles, objectName, selectedRecords, vfpages);
            }
            return null;
       	} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }




    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            for(Schema.SObjectType stype : gd.values()){

                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                 
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }

    public static String printPreview(  Map<String,List<String>> opportunityWithFiles ,Map<ID, Opportunity> opportunityWithID, Map<Id,Visualforce_PDF__c> vfpages  ){
        PageReference reportPage;
        for(String vf : opportunityWithFiles.keySet()){
            List<String> newSelectedOpportunity = new List<String>();
            
            ContentVersion cv;
            for(String opp : opportunityWithFiles.get(vf)){

                Map<String, Object> fieldsToValue = opportunityWithID.get(opp).getPopulatedFieldsAsMap();
                Service_Enrollment__c serviceEnrollment = (Service_Enrollment__c)fieldsToValue.get('Service_Enrollment__r');
                if(serviceEnrollment != null){
                    
                    Map<String, Object> serviceEnrollmentValues =  serviceEnrollment.getPopulatedFieldsAsMap();
                    List<String> optionalsFields = vfpages.get(vf).Service_Enrollment_Master_Field__c.split(',');

                    Boolean isEmail = false;
                    for(String str : optionalsFields){
                        String fieldValue = (String) serviceEnrollmentValues.get(str.trim());
                        if(fieldValue!=null && (fieldValue.contains('print') || fieldValue.contains('Print'))){
                            isEmail = true;
                            if(vfpages.get(vf).Print_Type__c == 'Bulk'){
                                newSelectedOpportunity.add(opp);
                            }
                        }
                    }

                    if(isEmail){
                        if( vfpages.get(vf).Print_Type__c == 'Individual Record' ){
                            reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+opp);
                        } 
                    }
                }
            }
            if (vfpages.get(vf).Print_Type__c =='Bulk') {
                if(!newSelectedOpportunity.isEmpty()){
                    reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+String.join(newSelectedOpportunity,';'));
                }
            }
        }   
        return reportPage !=null ? reportPage.getUrl() : 'File not found';
    }
    public static void generatePdf(  Map<String,List<String>> opportunityWithFiles ,Map<ID, Opportunity> opportunityWithID, Map<Id,Visualforce_PDF__c> vfpages ){

        //Map<String,List<ContentVersion>> recordWithFiles = new Map<String,List<ContentVersion>>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();

        for(String vf : opportunityWithFiles.keySet()){
            List<String> newSelectedOpportunity = new List<String>();
            PageReference reportPage;
            ContentVersion cv;
            for(String opp : opportunityWithFiles.get(vf)){

                Map<String, Object> fieldsToValue = opportunityWithID.get(opp).getPopulatedFieldsAsMap();
                Service_Enrollment__c serviceEnrollment = (Service_Enrollment__c)fieldsToValue.get('Service_Enrollment__r');
                if(serviceEnrollment != null){
                    
                    Map<String, Object> serviceEnrollmentValues =  serviceEnrollment.getPopulatedFieldsAsMap();
                    List<String> optionalsFields = vfpages.get(vf).Service_Enrollment_Master_Field__c.split(',');

                    Boolean isEmail = false;
                    for(String str : optionalsFields){
                        String fieldValue = (String) serviceEnrollmentValues.get(str.trim());
                        if(fieldValue!=null && (fieldValue.contains('print') || fieldValue.contains('Print'))){
                            isEmail = true;
                            if(vfpages.get(vf).Print_Type__c == 'Bulk'){
                                newSelectedOpportunity.add(opp);
                            }
                        }
                    }

                    if(isEmail){
                        if( vfpages.get(vf).Print_Type__c == 'Individual Record' ){
                            reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+opp);
                            if(Test.isRunningTest()){
                                cv = getContentVersion(vfpages.get(vf).File_Name__c,blob.valueOf('Unit.Test'));
                            } else {
                            cv = getContentVersion(vfpages.get(vf).File_Name__c,reportPage.getContentAsPDF());
                            }
                            contentVersionList.add(cv);
                        } 
                    }
                }
            }
            if (vfpages.get(vf).Print_Type__c =='Bulk') {
                if(!newSelectedOpportunity.isEmpty()){
                    reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+String.join(newSelectedOpportunity,';'));
                    if(Test.isRunningTest()){
                        cv = getContentVersion(vfpages.get(vf).File_Name__c,blob.valueOf('Unit.Test'));
                    } else {
                        cv = getContentVersion(vfpages.get(vf).File_Name__c,reportPage.getContentAsPDF());
                    }
                    contentVersionList.add(cv);
                }
            }
        }   
        if(!contentVersionList.isEmpty()){
            insert contentVersionList;
        } 
        if(!contentVersionList.isEmpty()){
            Map<Id,ContentVersion> contentDocumentIdsList = new Map<Id,ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionList]);
            ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name =: CONTENT_FOLDER_NAME LIMIT 1];
            
            for(Id contentVersion : contentDocumentIdsList.keySet()) {
                String documentID = contentDocumentIdsList.get(contentVersion).ContentDocumentId;
                ContentDocumentLink cdlFolder = getContentDocumentLink(documentID,ws.Id);
                contentDocumentLinkList.add(cdlFolder);
            }
            
            if(!contentDocumentLinkList.isEmpty()){
                insert contentDocumentLinkList;
            }
        }
    }

    public static void sendEmailAction(  Map<String,List<String>> opportunityWithFiles, Map<ID, Opportunity> opportunityWithID, Map<Id, Visualforce_PDF__c> vfpages ){
        Map<String,List<ContentVersion>> recordWithFiles = new Map<String,List<ContentVersion>>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();

        List<EmailTemplate> emailTemp = [SELECT id,Name FROM EmailTemplate WHERE Name=: EMAIL_TEMPLATE_NAME];
        List<OrgWideEmailAddress> owd = [SELECT id,Address FROM OrgWideEmailAddress WHERE Address=: SENDER_EMAIL];

        List<Messaging.SingleEmailMessage> mailMessages = new List<Messaging.SingleEmailMessage>();

        for(String vf : opportunityWithFiles.keySet()){
            PageReference reportPage;
            if (vfpages.get(vf).Print_Type__c =='Bulk') {
                reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+String.join(opportunityWithFiles.get(vf),';'));
            }

            for(String records : opportunityWithFiles.get(vf))
            {
                Map<String, Object> fieldsToValue = opportunityWithID.get(records).getPopulatedFieldsAsMap();
                Service_Enrollment__c serviceEnrollment = (Service_Enrollment__c)fieldsToValue.get('Service_Enrollment__r');
                if(serviceEnrollment != null){
                    Map<String, Object> serviceEnrollmentValues =  serviceEnrollment.getPopulatedFieldsAsMap();
                    List<String> optionalsFields = vfpages.get(vf).Service_Enrollment_Master_Field__c.split(',');

                    Boolean isEmail = false;
                    for(String str : optionalsFields){
                        String fieldValue = (String) serviceEnrollmentValues.get(str.trim());
                        if(fieldValue!=null && (fieldValue.contains('email') || fieldValue.contains('Email'))){
                            isEmail = true;
                        }
                    }
                    
                    if(isEmail){
                        if( vfpages.get(vf).Print_Type__c == 'Individual Record' ){
                            reportPage = new PageReference(VF_PAGE_DOMAIN+vfpages.get(vf).Visual_Force_Page_Name__c+'?id='+records);
                        }
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        
                        efa.setFileName(vfpages.get(vf).File_Name__c+System.now()+'.pdf');
                        if(Test.isRunningTest()){
                            efa.setBody(blob.valueOf('Unit.Test'));
                        } else {
                            efa.setBody(reportPage.getContentAsPDF());
                        }
                        
        
                        message.setFileAttachments(new List<Messaging.EmailFileAttachment>{efa});
                        if(emailTemp!=null && !emailTemp.isEmpty())
                        	message.setTemplateID(emailTemp[0].Id);
        
                        List<String> addressList = new List<String>();
        
                        if(String.isNotBlank(vfpages.get(vf).Recipient_Address_Field__c)){
        
                            for(String toAddress : vfpages.get(vf).Recipient_Address_Field__c?.split(',')){
                                if( opportunityWithID.get(records).getSObject('Service_Enrollment__r') != null){        
                                    if( opportunityWithID.get(records).getSObject('Service_Enrollment__r').get(toAddress.trim()) != null){
                                        addressList.add(opportunityWithID.get(records).getSObject('Service_Enrollment__r').get(toAddress.trim()).toString());
                                    }
                                }
        
                            }
                            if(addressList.size() > 0){
                                message.setToAddresses(addressList);
                                if(owd!=null && !owd.isEmpty())
                                	message.setOrgWideEmailAddressId(owd[0].ID);
                                message.setTargetObjectId(TargeObjceAccountID);
                                message.setTreatTargetObjectAsRecipient(false);
                                
                                mailMessages.add(message);
                            }
                            
                        }
                        
                    }
                }
                
            }           

        }        
        if(!mailMessages.isEmpty() && !Test.isRunningTest()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mailMessages);
        }
       
    }
   
    public static ContentVersion getContentVersion(String fileName,Blob fileContent){
        ContentVersion cv = new ContentVersion();
        cv.VersionData = fileContent;
        cv.Title = fileName+System.now();
        cv.PathOnClient = fileName+System.now()+'.pdf';
        return cv;
    }

    public static ContentDocumentLink getContentDocumentLink(String documentId, String linkEntity ){
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = documentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        cdl.LinkedEntityId = linkEntity; //Magic happens here
        return cdl;
    }

    public static void updateOpportunityWithAction(String action, Map<String,List<String>> opportunityWithFiles,String objectName, List<String> selectedOppotunities, Map<Id, Visualforce_PDF__c> vfpages) {
        List<sObject> sObjectList=new List<sObject>();
        Map<Id,sObject> uniqueOpportunity = new Map<Id,sObject>();

        Map<ID, Opportunity> opportunityWithID = new Map<ID, Opportunity>([SELECT Id,Service_Enrollment__r.Billing_Email__c,
         Service_Enrollment__c,Bill_Date__c,
         Service_Enrollment__r.Copy_1_Email__c, Service_Enrollment__r.Copy_2_Email__c, 
         Service_Enrollment__r.Mail_To_Email__c,
         Service_Enrollment__r.Billing_Attention_To__c,
         Service_Enrollment__r.Copy1_Attention_To__c, 
         Service_Enrollment__r.Copy2_Attention_To__c, 
         Service_Enrollment__r.Mail_To_Attention__c,
         Service_Enrollment__r.Billing_Invoice_Options__c,
         Service_Enrollment__r.Copy_1_Invoice_Options__c,
         Service_Enrollment__r.Copy_2_Invoice_Options__c,
         Service_Enrollment__r.Mail_To_Invoice_Options__c FROM 
         Opportunity WHERE Id in: selectedOppotunities]);
         
        for(String vf_Page: opportunityWithFiles.keySet()){
            
            for(String oppId  : opportunityWithFiles.get(vf_Page)){
                Sobject obj;

                if(uniqueOpportunity.containsKey(oppId)){
                    obj = uniqueOpportunity.get(oppId);
                } else {
                    obj = Schema.getGlobalDescribe().get(objectName).newSObject();
                    obj.put('Id', oppId);
                }
                

                Map<String, Object> fieldsToValue = opportunityWithID.get(oppId).getPopulatedFieldsAsMap();
                Service_Enrollment__c serviceEnrollment = (Service_Enrollment__c)fieldsToValue.get('Service_Enrollment__r');

                if( serviceEnrollment != null ){
                    
                    fieldsToValue = serviceEnrollment.getPopulatedFieldsAsMap();
                    Set<String> setOfAttentionFields = new Set<String>();

                    if(fieldsToValue.size() > 0){
                        for(String str : fieldsToValue.keySet()) {
                            if(str.containsAny('attention')){
                                setOfAttentionFields.add(str.split('_')[0].trim());
                            }
                        }
                    }

                    if(action == 'Email'){
                        if(String.isNotBlank(vfpages.get(vf_Page).Fields_to_Update_For_Email__c) && String.isNotBlank(vfpages.get(vf_Page).Fields_Values_to_Update_For_Email__c)){
                            List<String> selectField = vfpages.get(vf_Page).Fields_to_Update_For_Email__c.split(',');
                            List<String> selectFieldValue = vfpages.get(vf_Page).Fields_Values_to_Update_For_Email__c.split(',');

                            for(integer i = 0 ; i < selectField.size() ; i++){
                                if(setOfAttentionFields.contains(selectField[i].split('_')[0])){
                                    obj.put(selectField[i].trim(), keywordWithValues.get(selectFieldValue[i].trim()) );
                                }
                            }
                            uniqueOpportunity.put(oppId,obj);
                        } 
                    } else if(action == 'Print'){

                        if(String.isNotBlank(vfpages.get(vf_Page).Fields_to_Update_For_Print__c) && String.isNotBlank(vfpages.get(vf_Page).Fields_Values_to_Update_For_Print__c)){
                            List<String> selectField = vfpages.get(vf_Page).Fields_to_Update_For_Print__c.split(',');
                            List<String> selectFieldValue = vfpages.get(vf_Page).Fields_Values_to_Update_For_Print__c.split(',');
                                
                            for(integer i = 0 ; i < selectField.size() ; i++){
                                if(setOfAttentionFields.contains(selectField[i].split('_')[0])){
                                    obj.put(selectField[i].trim(), keywordWithValues.get(selectFieldValue[i].trim()) );
                                }
                            }
                            uniqueOpportunity.put(oppId,obj);
    
                        } 
                    }                    
                }

            }
        }
        if(action == 'Email'){
            // sending email 
            sendEmailAction(opportunityWithFiles, opportunityWithID, vfPages);

        } else if(action == 'Print'){
            // Generating the PDF and attaching to the record as well as storing the specific folder
            if(!Test.isRunningTest())
                generatePdf(opportunityWithFiles, opportunityWithID, vfpages);
        }

        // updating the opportunity record
        if(!uniqueOpportunity.isEmpty()){
            update uniqueOpportunity.values();
        }
    }

    public static Feature_Configurations__mdt getBulkSelector(String name){
        return [SELECT ID,Org_wide_address__c,Email_Template_Name__c
        FROM Feature_Configurations__mdt
        WHERE DEVELOPERNAME=:name];
    }

}