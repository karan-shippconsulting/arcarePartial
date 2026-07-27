public without sharing class SchemaUtil {
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Map<String,String>> getAllFieldsByObject(String objectApiName){
        Map<String,String> fields = new Map<String,String>();
        Map<String,String> typeWithfields = new Map<String,String>();
        try{
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult targetDescribe = targetType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = targetDescribe.fields.getMap();
            for(String fieldName : fieldMap.keySet()){
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                if(!fieldDescribe.isAccessible())
                    continue;
                if(fieldDescribe.getType() == Schema.DisplayType.REFERENCE){
                    Schema.SObjectType lookupType = fieldDescribe.getReferenceTo()[0];
                    Schema.DescribeSObjectResult lookupTypeDescribe = lookupType.getDescribe();
                    Map<String, Schema.SObjectField> lookupFieldMap = lookupTypeDescribe.fields.getMap();
                    for(String lookupFieldName : lookupFieldMap.keySet()){
                        if(lookupFieldMap.get(lookupFieldName).getDescribe().getType() != Schema.DisplayType.REFERENCE){
                            fields.put(fieldDescribe.getRelationshipName()+'->'+lookupFieldMap.get(lookupFieldName).getDescribe().getLabel(),fieldDescribe.getRelationshipName()+'.'+lookupFieldName);
                        }
                        typeWithfields.put(fieldDescribe.getRelationshipName()+'.'+lookupFieldName,String.valueOf(lookupFieldMap.get(lookupFieldName).getDescribe().getType()));
                    }
                }
                else{
                    typeWithfields.put(fieldName,String.valueOf(fieldDescribe.getType()));
                    fields.put(fieldDescribe.getLabel(),fieldName);
                }
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage());
        }
        return new Map<String,Map<String,String>>{'fields'=>fields,'types' => typeWithfields};
            }
    
    @AuraEnabled
    public static boolean checkEditPermission(String recordId){
        UserRecordAccess accessRec = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId =: recordId limit 1];
        return accessRec.HasEditAccess;
    }
    
    @AuraEnabled
    public static List<ContentDocumentLink> getAttachments(String recordId) {
        return [SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId ORDER BY ContentDocument.CreatedDate DESC];
    }

    @AuraEnabled
    public static List<ContentDocumentLink> getAttachmentsBulk(list<String> selectedRecords) {
        system.debug('selectedRecords: '+selectedRecords);
        return [SELECT ContentDocument.Id, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :selectedRecords ORDER BY ContentDocument.CreatedDate DESC];
    }
    
    
    @AuraEnabled
    public static void deleteAttachment(String contentDocumentId) {
        // Get the ContentDocumentLink record associated with the Contact and ContentDocument
        List<ContentDocumentLink> linksToDelete = [SELECT Id FROM ContentDocumentLink WHERE Id = :contentDocumentId];
        
        // Delete the links, which effectively removes the file from the Contact record
        delete linksToDelete;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactLookupValues(String recordId, String sObjectName) {
        // Dynamically describe the object
        SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        Schema.DescribeSObjectResult describeSObject = sObjectType.getDescribe();
  
        Map<String, Schema.SObjectField> fieldsMap = describeSObject.fields.getMap();
        // Initialize map to store lookup field values
        Set<String> lookupValues = new Set<String> ();
        Set<String> personFieldNames = new Set<String> ();
        Set<Id> personaccountIds = new Set<Id> ();

        // Dynamically query the record using the recordId
        String query = 'SELECT ';
        List<String> lookupFields = new List<String>();
        Boolean isPersonAccount = Account.SObjectType.getDescribe().fields.getMap().containsKey('IsPersonAccount');
        for (String fieldName : fieldsMap.keySet()) {
            Schema.SObjectField field = fieldsMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if(!fieldDescribe.isAccessible())
                continue;
            // Check if the field is a lookup and points to Contact
            system.debug('fieldName '+fieldName);
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE && 
                ( fieldDescribe.getReferenceTo().contains(Contact.SObjectType) ||
                (fieldDescribe.getReferenceTo().contains(Account.SObjectType) && isPersonAccount) ) ) {
                lookupFields.add(fieldName);
                if(fieldDescribe.getReferenceTo().contains(Account.SObjectType))
                    personFieldNames.add(fieldName);
            }
        }

        // If there are any lookup fields, construct the SOQL query
        if (lookupFields.size() > 0) {
            query += String.join(lookupFields, ', ') + ' FROM ' + sObjectName + ' WHERE Id = :recordId';
            List<SObject> records = Database.query(query);
            sObject record;
            if(records?.size()>0)
                record = records[0];
            if(record == null)
                return new List<Contact>();
            // Populate the lookup field values into the map
            for (String field : lookupFields) {
                if (!lookupValues.contains(field)) {
                    lookupValues.add((String) record.get(field));
                }
                if(personFieldNames.contains(field))
                    personaccountIds.add((Id) record.get(field));
            }
            if(!personaccountIds.isEmpty()){
                list<account> personAccounts = [select id,personContactId from account where id In :personaccountIds];
                for(account acc : personAccounts){
                    lookupValues.add((String)acc.personContactId);
                }
            }
            
            if(lookupValues.size() > 0){
                return [Select Id,Name,Email from Contact where Id IN:lookupValues];
            }
        }

        return new List<Contact>();
    }
    
    
    @AuraEnabled
    public static List<Map<String,String>> getUpdatableFieldsByObject(String objectApiName){
        List<Map<String,String>> fields = new List<Map<String,String>>();
        try{
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult targetDescribe = targetType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = targetDescribe.fields.getMap();
            for(String fieldName : fieldMap.keySet()){
                system.debug('fieldName '+fieldName);
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                system.debug('fieldDescribe '+fieldDescribe);
                system.debug('fieldDescribe '+fieldDescribe.isAccessible());
                if(!fieldDescribe.isAccessible())
                    continue;
                if(fieldDescribe.isUpdateable() && fieldDescribe.getType() != Schema.DisplayType.REFERENCE ){
                    Map<String,String> obj = new Map<String,String>();
                    obj.put('label',fieldDescribe.getLabel());
                    obj.put('name',fieldDescribe.getName());
                    obj.put('type',String.valueOf(fieldDescribe.getType()));
                    fields.add(obj);
                }
                
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage());
        }
        return fields;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplate> getAllEmailTemps(){
        return [Select Id,Name,TemplateType,Subject from EmailTemplate where IsActive = true AND TemplateType != 'text' ORDER BY Name];
    }
    
    @AuraEnabled
    public static String generateStringBody(String recordId,String tempId){
        String htmlBody = Messaging.renderStoredEmailTemplate(tempId,null,recordId).getHTMLBody();
        return String.isBlank(htmlBody)? Messaging.renderStoredEmailTemplate(tempId,null,recordId).getPlainTextBody():htmlBody;
    }
    
    @AuraEnabled
    public static List<SObject> queryData(List<String> fieldList, String objectApiName,String recordId){
        Set<String> fieldSet = new Set<String>();
        Set<String> fieldSetCurrentUser = new Set<String>();
        List<SObject> toRet = new List<SObject>();
        for(String fieldName : fieldList){
            if(fieldName.startsWithIgnoreCase('currentuser')){
                fieldSetCurrentUser.add(fieldName.replace('currentuser.',''));
            }else{
                fieldSet.add(fieldName);
            }
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        if (fieldMap.containsKey('RecordTypeId')) {
            fieldSet.add('RecordTypeId');
        }
        
        String query = 'Select ' + String.join(new List<String>(fieldSet),',') + ' from '+ objectApiName + ' where Id=\''+ recordId + '\' limit 1';
        
        System.debug(query);
        toRet.add(Database.query(query));
        if(fieldSetCurrentUser.size()>0){
            String userQuery = 'Select ' + String.join(new List<String>(fieldSetCurrentUser),',') + ' from User where Id=\''+ UserInfo.getUserId() + '\' limit 1';
            toRet.add(Database.query(userQuery));
        }
        
        return toRet;
    }
    
    @AuraEnabled
    public static String generatePDF(String recordId,String vfPageId){
        PageReference pdfPage;
        if(String.isNotEmpty(vfPageId) && vfPageId!='default'){
            ApexPage apexPage =  [SELECT Name, NamespacePrefix FROM ApexPage WHERE Id =:vfPageId];
            pdfPage = new PageReference('/apex/'+apexPage.Name);            
        }
        if(pdfPage == null)
            pdfPage = Page.renderPDF;
        
        pdfPage.getParameters().put('recId', recordId);
        if(Test.isRunningTest())
            return 'Test';
        return EncodingUtil.base64Encode(pdfPage.getContentasPDF());            
    }
    
    
    @AuraEnabled
    public static String generatePDFBulk(String recordId,String vfPageId){
        PageReference pdfPage;
        if(String.isNotEmpty(vfPageId) && vfPageId!='default'){
            ApexPage apexPage =  [SELECT Name, NamespacePrefix FROM ApexPage WHERE Id =:vfPageId];
            pdfPage = new PageReference('/apex/'+apexPage.Name);            
        }
        if(pdfPage == null)
            pdfPage = Page.renderPDFBulk;
        
        pdfPage.getParameters().put('recId', recordId);
        System.debug('pdfPage at 222 ---' + pdfPage);
        if(Test.isRunningTest())
            return 'Test';

        Blob pdfBlob = pdfPage.getContentAsPDF();
        System.debug('EncodingUtil.base64Encode(pdfBlob) --' + EncodingUtil.base64Encode(pdfBlob));
        return EncodingUtil.base64Encode(pdfBlob);


        //return fullUrl;
        /*ContentVersion cv = new ContentVersion();
        cv.Title = 'Generated_File.pdf';
        cv.PathOnClient = 'Generated_File.pdf';
        cv.VersionData = pdfPage.getContentasPDF();
        cv.IsMajorVersion = true;
        cv.FirstPublishLocationId = UserInfo.getUserId();
        if(!Test.isRunningTest())
            insert cv;

        // Get the file's public URL
        ContentVersion link = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        ContentDistribution cd = new ContentDistribution(
            Name = 'Generated_File.pdf',
            ContentVersionId = cv.Id,
            PreferencesAllowViewInBrowser = true,
            PreferencesAllowOriginalDownload = true
        );
        insert cd;
        cd = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];

        System.debug(cd.DistributionPublicUrl);
            return cd.DistributionPublicUrl;      
//        https://cfpd--partial--c.sandbox.vf.force.com/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=069Ov00000A10ReIAJ
     //   return '/sfc/servlet.shepherd/document/download/' + link.ContentDocumentId;*/
    }
    @AuraEnabled
    public static void generatePDFOnRecord(String recordId,String vfPageId,String currentRecord,Blob pdfContent){
        PageReference pdfPage;
        if(pdfContent == null){
            
            if(String.isNotEmpty(vfPageId) && vfPageId!='default'){
                ApexPage apexPage =  [SELECT Name, NamespacePrefix FROM ApexPage WHERE Id =:vfPageId];
                pdfPage = new PageReference('/apex/'+apexPage.Name);            
            }
            if(pdfPage == null)
                pdfPage = Page.renderPDF;
            
            pdfPage.getParameters().put('recId', recordId);
        }
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfContent ?? pdfPage.getContentAsPDF();
        
        Custom_Email_Template__c template = [Select Id,Name,PDF_File_Name__c,Parent_Object__c, Document_Checklist_Category__c, Document_Checklist_Item_Status__c from Custom_Email_Template__c where Id =:recordId];
        
        /*
ContentVersion contentVersion = new ContentVersion();
contentVersion.Title = temp.Name +'.pdf';
contentVersion.PathOnClient = 'Record_' + recordId + '.pdf';
contentVersion.VersionData = pdfBlob;
contentVersion.Origin = 'H'; // 'H' indicates the file was uploaded via Salesforce UI or API
insert contentVersion;

ContentDocumentLink documentLink = new ContentDocumentLink();
documentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
documentLink.LinkedEntityId = currentRecord;
documentLink.ShareType = 'V'; // Viewer permission
documentLink.Visibility = 'AllUsers'; // Adjust visibility as required
insert documentLink; */
        
        Map<String, Id> docCategoryMap = new Map<String, Id>();
        if (template.Document_Checklist_Category__c != null) {
            for (DocumentCategory dc : [
                SELECT Id, MasterLabel
                FROM DocumentCategory
                WHERE MasterLabel = :template.Document_Checklist_Category__c
            ]) {
                docCategoryMap.put(dc.MasterLabel, dc.Id);
            }
        }

        if (template.Parent_Object__c != null && 
            template.Document_Checklist_Category__c != null && 
            template.Document_Checklist_Item_Status__c != null &&
            docCategoryMap.containsKey(template.Document_Checklist_Category__c)) {
                 
                // Create a DocumentChecklistItem
                DocumentChecklistItem doclist = new DocumentChecklistItem();
                doclist.ParentRecordId = currentRecord;
                doclist.WhoId = UserInfo.getUserId();
                doclist.Name = template.Name +'.pdf'; // Flow trigger sets the name
                doclist.DocumentCategoryId = docCategoryMap.get(template.Document_Checklist_Category__c);
                doclist.Status = template.Document_Checklist_Item_Status__c;
                
                Map<String, Dynamic_Email_Template_Parent_Object__mdt> parentObjects = Dynamic_Email_Template_Parent_Object__mdt.getAll();
                for (String recordDeveloperName : parentObjects.keySet()) {
                    Dynamic_Email_Template_Parent_Object__mdt record = parentObjects.get(recordDeveloperName);
                    System.debug('Record Name: ' + record.MasterLabel + ', Field Value: ' + record.Doc_Checklist_Item_Lookup_Field_API__c);
                    if (template.Parent_Object__c == record.MasterLabel) 
                        doclist.put(record.Doc_Checklist_Item_Lookup_Field_API__c,currentRecord );
                }
                
                /*if (template.Parent_Object__c == 'Trust__c') doclist.Trust__c = currentRecord;
                //else if (template.Parent_Object__c == 'Account') doclist.AccountId = currentRecord;
                else if (template.Parent_Object__c == 'Intake__c') doclist.Intake__c = currentRecord;
                else if (template.Parent_Object__c == 'Benefit__c') doclist.Benefit__c = currentRecord;
                else if (template.Parent_Object__c == 'Trust_Asset__c') doclist.Trust_Asset__c = currentRecord;
                else if (template.Parent_Object__c == 'Trust_Accounting__c') doclist.Trust_Accounting__c = currentRecord;
                else if (template.Parent_Object__c == 'Spending_Plan__c') doclist.Spending_Plan__c = currentRecord;
                else if (template.Parent_Object__c == 'Disbursement_Request__c') doclist.Disbursement_Request__c = currentRecord;
                else if (template.Parent_Object__c == 'Closing__c') doclist.Closing__c = currentRecord;
                else if (template.Parent_Object__c == 'Service_Enrollment__c') doclist.Service_Enrollment__c = currentRecord;
                else if (template.Parent_Object__c == 'Incident__c') doclist.Incident__c = currentRecord;
                else if (template.Parent_Object__c == 'Transaction__c') doclist.Transaction_Item__c = currentRecord;
                else if (template.Parent_Object__c == 'Check_Log__c') doclist.Check_Log__c = currentRecord;
                */
                system.debug('doclist'+doclist);
                insert doclist;
                
                
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = (String.isNotBlank(template.PDF_File_Name__c) ? template.PDF_File_Name__c : template.Name) + '.pdf';
                contentVersion.PathOnClient = 'Record_' + currentRecord + '.pdf';
                contentVersion.VersionData = pdfBlob;
                //contentVersion.FirstPublishLocationId = doclist.Id;
                contentVersion.Origin = 'H';
                if(!Test.isRunningTest()){
                    insert contentVersion;
                }
                
                /*list<ContentVersion> docChildList = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :contentVersion.Id
                ];
                ContentDocumentLink documentLink = new ContentDocumentLink();
                documentLink.ContentDocumentId = !docChildList.isEmpty() ? docChildList[0].ContentDocumentId : null;
                documentLink.LinkedEntityId = doclist.Id;
                documentLink.ShareType = 'V';
                documentLink.Visibility = 'AllUsers';
                if(!Test.isRunningTest()){
                    insert documentLink;
                }*/
                
                
            } else {
                // Fall back to existing ContentVersion logic
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = template.Name +'.pdf';
                contentVersion.PathOnClient = 'Record_' + currentRecord + '.pdf';
                contentVersion.VersionData = pdfBlob;

                contentVersion.FirstPublishLocationId = currentRecord;
                contentVersion.Origin = 'H';
                if(!Test.isRunningTest()){
                    insert contentVersion;
                }
                
                /*list<ContentVersion> docParentList = [
                    SELECT ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :contentVersion.Id
                ];
                // Link the file to the Parent record
                ContentDocumentLink documentLink = new ContentDocumentLink();
                documentLink.ContentDocumentId = !docParentList.isEmpty() ? docParentList[0].ContentDocumentId : null;
                documentLink.LinkedEntityId = currentRecord;
                documentLink.ShareType = 'V';
                documentLink.Visibility = 'AllUsers';
                if(!Test.isRunningTest()){
                    insert documentLink;
                }*/
            }
    }
    
    @AuraEnabled
    public static void generatePDFOnRecordBulk(String cerecordId, String vfPageId, List<String> selectedRecords, Blob pdfContent) {
        if (selectedRecords == null || selectedRecords.isEmpty()) {
            return; // No records to process
        }
        
        PageReference pdfPage;
        if (pdfContent == null) {
            if (String.isNotEmpty(vfPageId) && vfPageId != 'default') {
                ApexPage apexPage = [SELECT Name FROM ApexPage WHERE Id =: vfPageId LIMIT 1];
                pdfPage = new PageReference('/apex/' + apexPage.Name);
            }
            if (pdfPage == null) {
                pdfPage = Page.renderPDFBulk;
            }
            pdfPage.getParameters().put('recId', cerecordId);
        }
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfContent ?? pdfPage.getContentAsPDF();
        
        // Fetch Email Template
        Custom_Email_Template__c template = [
            SELECT Id, Name, Parent_Object__c, Document_Checklist_Category__c, Document_Checklist_Item_Status__c 
            FROM Custom_Email_Template__c 
            WHERE Id =: cerecordId 
            LIMIT 1
        ];
        
        if (template == null) {
            return; // No valid template found
        }
        
        // Fetch Document Category Ids in one query
        Map<String, Id> docCategoryMap = new Map<String, Id>();
        if (template.Document_Checklist_Category__c != null) {
            for (DocumentCategory dc : [SELECT Id, MasterLabel FROM DocumentCategory WHERE MasterLabel =: template.Document_Checklist_Category__c]) {
                docCategoryMap.put(dc.MasterLabel, dc.Id);
            }
        }
        
        // Prepare records for bulk insertion
        List<DocumentChecklistItem> docListItems = new List<DocumentChecklistItem>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        Map<Id, Id> contentDocumentMap = new Map<Id, Id>();
        
        for (String recordId : selectedRecords) {
            DocumentChecklistItem docItem = new DocumentChecklistItem();
            docItem.ParentRecordId = recordId;
            docItem.WhoId = UserInfo.getUserId();
            docItem.Name = template.Name +'.pdf'; // Flow trigger sets the name
            docItem.DocumentCategoryId = docCategoryMap.get(template.Document_Checklist_Category__c);
            docItem.Status = template.Document_Checklist_Item_Status__c;
            
            // Dynamically assign the related object field
            if (template.Parent_Object__c != null) {
                String fieldName = template.Parent_Object__c + '__c';
                SObjectType objType = Schema.getGlobalDescribe().get('DocumentChecklistItem');
                if (objType.getDescribe().fields.getMap().containsKey(fieldName)) {
                    docItem.put(fieldName, recordId);
                }
            }
            
            docListItems.add(docItem);
            
            // Prepare ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = template.Name + '_bulk' + '.pdf';
            contentVersion.PathOnClient = 'Record_' + recordId + '.pdf';
            contentVersion.VersionData = pdfBlob;
            contentVersion.Origin = 'H';
            contentVersion.FirstPublishLocationId = UserInfo.getUserId();
            contentVersions.add(contentVersion);
        }
        
        // Bulk insert DocumentChecklistItems
        if (!docListItems.isEmpty()) {
            insert docListItems;
        }
        
        // Bulk insert ContentVersions
        if (!Test.isRunningTest() && !contentVersions.isEmpty()) {
            insert contentVersions;
            
            // Fetch inserted ContentVersions and map their ContentDocumentId
            /*for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
                contentDocumentMap.put(cv.Id, cv.ContentDocumentId);
            }*/
        }
        
        // Prepare ContentDocumentLinks
        /*List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        for (Integer i = 0; i < contentVersions.size(); i++) {
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.ContentDocumentId = contentDocumentMap.get(contentVersions[i].Id);
            docLink.LinkedEntityId = docListItems[i].Id;
            docLink.ShareType = 'V';
            docLink.Visibility = 'AllUsers';
            documentLinks.add(docLink);
        }
        
        // Bulk insert ContentDocumentLinks
        if (!Test.isRunningTest() && !documentLinks.isEmpty()) {
            insert documentLinks;
        }*/
    }
    
    
    @AuraEnabled
    public static void updateFinalBody(String htmlString,String recordId){
        Custom_Email_Template__c ce = new Custom_Email_Template__c(Id=recordId,Final_Body__c=htmlString);
        update ce;
    }
    
    @AuraEnabled
    public static void massUpdateFinalBody(String customEmailTempId,Map<String,String> bodyMap){
        List<Bulk_Custom_Email_Template__c> toInsert = new List<Bulk_Custom_Email_Template__c>();
        String currentUserName = UserInfo.getUserName();
        for(String recordId:bodyMap.keySet()){
            Bulk_Custom_Email_Template__c bulkTemp = new Bulk_Custom_Email_Template__c(Custom_Email_Template__c = customEmailTempId,Final_Email_Body__c = bodyMap.get(recordId), Record_Id__c = recordId); 
            bulkTemp.Name = currentUserName.substring(0, 20) + recordId;
            toInsert.add(bulkTemp);
        }
        insert toInsert;
    }

    @AuraEnabled
    public static void massUpdateFinalBodyOnBulkCustomTemplateRecords(String customEmailTempId,Map<String,String> bodyMap){
        Map<String, Bulk_Custom_Email_Template__c> mapOfRecordIdToBulkCustomTemplateId = new Map<String, Bulk_Custom_Email_Template__c>();
        List<Bulk_Custom_Email_Template__c> listOfRecordsToUpdate = new List<Bulk_Custom_Email_Template__c>();
        String currentUserId = UserInfo.getUserId();
        List<Bulk_Custom_Email_Template__c> existingRecords = [Select Id, Record_Id__c, Final_Email_Body__c, CreatedById FROM Bulk_Custom_Email_Template__c 
                                                                WHERE Custom_Email_Template__c =: customEmailTempId
                                                                    AND CreatedById =:currentUserId];
        for(Bulk_Custom_Email_Template__c bulkCustomTemplate : existingRecords) {
            mapOfRecordIdToBulkCustomTemplateId.put(bulkCustomTemplate.Record_Id__c + '_' + bulkCustomTemplate.CreatedById , bulkCustomTemplate);
        }
        for(String recordId:bodyMap.keySet()){
            String key = recordId + '_'  + currentUserId;
            Bulk_Custom_Email_Template__c bulkCustomTemplate = mapOfRecordIdToBulkCustomTemplateId.get(key);
            bulkCustomTemplate.Final_Email_Body__c = bodyMap.get(recordId);
            listOfRecordsToUpdate.add(bulkCustomTemplate);
        }
        update listOfRecordsToUpdate;
    }
    
    @AuraEnabled
    public static void deleteBulkCustomTemplateRecords(String customEmailTempId){
        System.debug('in deleteBulkCustomTemplateRecords');
        System.debug('customEmailTempId ---- ' + customEmailTempId);
        Id currentUserId = UserInfo.getUserId();
        delete [Select Id from Bulk_Custom_Email_Template__c where Custom_Email_Template__c=:customEmailTempId AND CreatedById =: currentUserId];
    }
    
    @AuraEnabled
    public static String getObjectNameFromId(Id recordId) {
        Schema.SObjectType sObjType = recordId.getSObjectType();
        return sObjType.getDescribe().getName();
    }

    @AuraEnabled(cacheable=true)
    public static List<Custom_Email_Template__c> getAllEmailTempsCustom(String folder,String objectApiName){
        if(String.isNotBlank(folder) && String.isNotEmpty(folder))
            return [Select Id,Body__c,Email_Body__c,Subject__c,Name,Default_Field_Name_1__c,Default_Field_Name_2__c,Default_Field_Name_3__c,Default_Field_Value_1__c,Default_Field_Value_2__c,Default_Field_Value_3__c,Pdf_Template__c, Default_Currency_Format__c, Default_Date_Format__c, Default_Decimal_Format__c, Default_Boolean_Format__c,Recipient_Address_Field__c,Organization_Wide_Email__c from Custom_Email_Template__c where Active__c = true AND Folder__c =:folder AND Parent_Object__c =:objectApiName ORDER BY Name];
        return [Select Id,Body__c,Email_Body__c,Subject__c,Name,Default_Field_Name_1__c,Default_Field_Name_2__c,Default_Field_Name_3__c,Default_Field_Value_1__c,Default_Field_Value_2__c,Default_Field_Value_3__c,Pdf_Template__c, Default_Currency_Format__c, Default_Date_Format__c, Default_Decimal_Format__c, Default_Boolean_Format__c,Recipient_Address_Field__c,Organization_Wide_Email__c from Custom_Email_Template__c where Active__c = true AND Parent_Object__c =:objectApiName ORDER BY Name];
    }
    
    @AuraEnabled 
    public static Custom_Email_Template__c getCustomEmailById(String Id){ 
        return [Select Id,Body__c,Email_Body__c,Subject__c,Name,Default_Field_Name_1__c,Default_Field_Name_2__c,Default_Field_Name_3__c,Default_Field_Value_1__c,Default_Field_Value_2__c,Default_Field_Value_3__c ,Parent_Object__c, Pdf_Template__c, Default_Currency_Format__c, Default_Date_Format__c, Default_Decimal_Format__c, Default_Boolean_Format__c from Custom_Email_Template__c where Active__c = true AND Id =:Id limit 1];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldValues(String objectName, String fieldName) {
        Set<String> picklistValuesSet = new Set<String>();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult typeDesc = objType.getDescribe();
        Schema.DescribeFieldResult fieldDesc = typeDesc.fields.getMap().get(fieldName).getDescribe();
        
        if (fieldDesc.getType() == Schema.DisplayType.PICKLIST) {
            List<Schema.PicklistEntry> picklistEntries = fieldDesc.getPicklistValues();
            for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                picklistValuesSet.add(picklistEntry.getValue());
            }
        }/* else if (fieldDesc.getType() == Schema.DisplayType.EMAIL) {
//add email type
} else if (fieldDesc.getType() == Schema.DisplayType.PHONE) {
//add phone type
} else if (fieldDesc.getType() == Schema.DisplayType.URL) {
//add url type
} else if (fieldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) {
//add multipicklist type
} else if (fieldDesc.getType() == Schema.DisplayType.TEXTAREA) {
//add textarea type
} else if (fieldDesc.getType() == Schema.DisplayType.REFERENCE) {
//add reference type
}*/
        
        return new List<String>(picklistValuesSet);
    }
    
    @AuraEnabled(cacheable=true)
    public static String getFieldType(String objectName,String fieldName){
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult typeDesc = objType.getDescribe();
        Schema.DescribeFieldResult fieldDesc = typeDesc.fields.getMap().get(fieldName).getDescribe();
        return String.valueOf(fieldDesc.getType());
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<OrgWideEmailAddress> getAllOrgWideEmailAddress(){
        return [Select Id,DisplayName,Address from OrgWideEmailAddress ];
    }
    
    @AuraEnabled
    public static List<Map<String,String>> getAllObjects(){
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        List<Map<String,String>> toRet = new List<Map<String,String>>();
        for(Schema.SObjectType d : gd.values()){
            Schema.DescribeSObjectResult ds = d.getDescribe();
            if(!ds.isCreateable() || !ds.isAccessible() || ds.isCustomSetting() || !ds.isQueryable() || !ds.isSearchable())
                continue;
            Map<String,String> toRetMap = new Map<String,String>();
            toRetMap.put('label',ds.getLabel());
            toRetMap.put('value',ds.getName());
            toRet.add(toRetMap);
        }
        return toRet;
    }
    
    @AuraEnabled
    public static Boolean sendEmail(List<String> toList,List<String> ccList,String subject,String emailBody,String orgWideId,
                                    Boolean attachAsPdf,String recordId,String vfPageId,List<String> contendDocIds,
                                    String recordId2,List<String> selectedRecords,Boolean createActivity,Boolean isBulk ){
        
        Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
        
        List<ContentVersion> versions = [SELECT Id, Title, VersionData, ContentDocumentId , FileType
                                         FROM ContentVersion 
                                         WHERE ContentDocumentId IN :contendDocIds];
        
        List<ContentDocumentLink> toCreateLink = new List<ContentDocumentLink>();
        
        
        // Create email attachment objects from the ContentVersion records
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        
        mymail.setToAddresses(toList);
        if(ccList != null && ccList.size() > 0)
            mymail.setCcAddresses(ccList);
        // mymail.setSenderDisplayName('Salesforce Support');
        mymail.setSubject(subject);
        mymail.setHtmlBody(emailBody);
        
        if(orgWideId != '0')
            mymail.setOrgWideEmailAddressId(orgWideId);
        
        
        EmailMessage emailMessage = new EmailMessage();
        if(createActivity){
            
            emailMessage.Subject = mymail.getSubject();
            emailMessage.HtmlBody = mymail.getHtmlBody();
            emailMessage.TextBody = mymail.getPlainTextBody();
            //emailMessage.FromName = 'Your Name';
            emailMessage.ToAddress = String.join(toList, ',');
            emailMessage.Status = '3'; // Status "3" typically represents "Sent"
            emailMessage.Incoming = false; // Indicates that this is an outgoing email
            emailMessage.RelatedToId = recordId2; // The ID of the record to link it to (e.g., an Account or Opportunity)
            //emailMessage.SaveAsActivity = true;
            
            insert emailMessage;
        }
        
        if(attachAsPdf){
            Custom_Email_Template__c temp = [Select Id,Name,PDF_File_Name__c from Custom_Email_Template__c where Id =:recordId];
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();     
            PageReference pdfPage;
            if(String.isNotEmpty(vfPageId) && vfPageId!='default'){
                ApexPage apexPage =  [SELECT Name, NamespacePrefix FROM ApexPage WHERE Id =:vfPageId];
                pdfPage = new PageReference('/apex/'+apexPage.Name);            
            }
            system.debug('pdfPage:'+ pdfPage);
            system.debug('isBulk:'+ isBulk);
            system.debug('Page.renderPDFBulk:'+ Page.renderPDFBulk);
            system.debug('Page.renderPDF:'+ Page.renderPDF);
            if(pdfPage == null)
                pdfPage = isBulk ? Page.renderPDFBulk : Page.renderPDF;
            pdfPage.getParameters().put('recId', recordId);
            if(Test.isRunningTest()){
                efa.setBody(Blob.valueOf('Test'));
            }else{
                efa.setBody(pdfPage.getContentaspdf());   
            }
            if(isBulk){
                SchemaUtil.generatePDFOnRecordBulk(recordId, vfPageId, selectedRecords,Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentaspdf());
            }else{
                SchemaUtil.generatePDFOnRecord(recordId,null,recordId2,Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentaspdf());
            }
            
            efa.setFileName((String.isNotBlank(temp.PDF_File_Name__c) ? temp.PDF_File_Name__c : temp.Name) + '.pdf');
            efa.setContentType('application/pdf');
            emailAttachments.add(efa);
        }
        
        for (ContentVersion version : versions) {
            Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
            emailAttachment.setFileName(version.Title+'.'+version.FileType.toLowerCase());
            emailAttachment.setContentType('application/'+version.FileType.toLowerCase());
            emailAttachment.setBody(version.VersionData);
            emailAttachments.add(emailAttachment);
            
            if(createActivity){
                ContentDocumentLink emailAttachmentLink = new ContentDocumentLink();
                emailAttachmentLink.ContentDocumentId = version.ContentDocumentId;
                emailAttachmentLink.LinkedEntityId = emailMessage.Id; // Link to the EmailMessage record
                emailAttachmentLink.ShareType = 'V'; // Viewer access
                
                toCreateLink.add(emailAttachmentLink);
            }
            
        }
        if(createActivity)
            insert toCreateLink;
        mymail.setFileAttachments(emailAttachments);

        if (Test.isRunningTest()) {
            return true;
        }
        
        for(Messaging.SendEmailResult emailResult :  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mymail })){
            return emailResult.isSuccess();
        }
        
        return false;
    }
    
   
    
    @AuraEnabled
    public static void upsertEmailTemp(String tempId,String emailBody,String subject,String objectName, String pdfTemplate, String Default_Field1,String Default_Field2,String Default_Field3,
        String Default_FieldValue1,String Default_FieldValue2,String Default_FieldValue3,
        String Default_CurrencyFormat, String Default_DateFormat, String Default_DecimalFormat, String Default_BooleanFormat, String separateEmailBody, String pdfFileName){
        Custom_Email_Template__c temp = new Custom_Email_Template__c(Id=tempId,Body__c = emailBody,Subject__c = subject,Active__c = true,Parent_Object__c = objectName);
        if(separateEmailBody != null) {
            temp.Email_Body__c = separateEmailBody;
        }
        if(String.isNotEmpty(Default_Field1)){
            temp.put('Default_Field_Name_1__c',Default_Field1);
        }
        if(String.isNotEmpty(Default_Field2)){
            temp.put('Default_Field_Name_2__c',Default_Field2);
        }
        if(String.isNotEmpty(Default_Field1)){
            temp.put('Default_Field_Name_3__c',Default_Field3);
        }
        if(String.isNotEmpty(pdfTemplate)){
            temp.put('Pdf_Template__c',pdfTemplate);
        }
        
        temp.put('Default_Field_Value_1__c',Default_FieldValue1);    
        temp.put('Default_Field_Value_2__c',Default_FieldValue2);
        temp.put('Default_Field_Value_3__c',Default_FieldValue3);
        temp.put('Default_Currency_Format__c',Default_CurrencyFormat);
        temp.put('Default_Date_Format__c',Default_DateFormat);
        temp.put('Default_Decimal_Format__c',Default_DecimalFormat);
        temp.put('Default_Boolean_Format__c',Default_BooleanFormat);
        if(String.isNotEmpty(pdfFileName)){
            temp.put('PDF_File_Name__c',pdfFileName);
        }

        upsert temp;
    }
    
    @AuraEnabled
    public static void updateCurrentObject(String objectName,Map<String,String> fieldObject){
        
        System.debug(fieldObject);
        SObject obj = (SObject) Type.forName('Schema', objectName).newInstance();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult targetDescribe = targetType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = targetDescribe.fields.getMap();
        
        for(String key:fieldObject.keySet()){
            if(fieldMap.get(key).getDescribe().getType() == Schema.DisplayType.DATE || fieldMap.get(key).getDescribe().getType() == Schema.DisplayType.DATETIME){
                obj.put(key,Date.valueOf(fieldObject.get(key)));
            }
            else{
                obj.put(key,fieldObject.get(key));
            }
        }
        update obj;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ApexPage> getPdfOptions(String objectApiName){
        return [Select Id,Name from ApexPage where Description = 'Pdf Template'];
    }

    @AuraEnabled(cacheable=true)
    public static List<ApexPage> getPdfOptionsBulk(String objectApiName){
        return [Select Id,Name from ApexPage where Description = 'Pdf Template Bulk'];
    }

    @AuraEnabled
    public static Boolean checkIsImageTextArea(String fieldApiName, String recordId, String objectApiName){
        String query;
        if(fieldApiName.startsWithIgnoreCase('currentuser')) {
            fieldApiName = fieldApiName.replace('CurrentUser.','');
            query = 'SELECT Id, '+ fieldApiName + ' from User where Id=\''+ UserInfo.getUserId() + '\' limit 1';
            User user = (User)Database.query(query);
            
            Object fieldValue = user.get(fieldApiName);
            if (fieldValue != null && String.isNotBlank(String.valueOf(fieldValue)) && String.valueOf(fieldValue).contains('img')) {
                return true;
            }
        } else {
            query = 'SELECT Id, '+ fieldApiName + ' FROM '  + objectApiName + ' where Id=\''+ recordId + '\' limit 1'; 
            System.debug('query ----' + query);
            SObject current = Database.query(query);
            String[] parts = fieldApiName.split('\\.');
            System.debug('parts: ' + parts);
            for (Integer i = 0; i < parts.size() - 1; i++) {
                current = current.getSObject(parts[i]);
                if (current == null) {
                    // handle null relationship to avoid null pointer exception
                    System.debug('Null relationship at: ' + parts[i]);
                    break;
                }
            }

            Object value = current.get(parts[parts.size() - 1]);
            String fieldValue = (String) value;
            if (String.isNotBlank(fieldValue) && fieldValue.contains('img')) {
                return true;
            }
        }
        System.debug('query ----- ' + query);
        //Role__c role = (Role__c) Database.query(query);
        /**/
     return false;
    }

    @AuraEnabled
    public static void createQueueAndStartBatch(String customEmailTemplateId, List<String> parentRecordIds, 
        Map<String, String> mergedBodyByRecord) {

        System.debug('customEmailTemplateId -- ' + customEmailTemplateId);
        System.debug('parentRecordIds -- ' + parentRecordIds);
        System.debug('parentRecordIds.isEmpty -- ' + (parentRecordIds == null ? null : parentRecordIds.isEmpty()));

        if (String.isBlank(customEmailTemplateId) || parentRecordIds == null || parentRecordIds.isEmpty()) {
            throw new AuraHandledException('Missing template id or parent record ids.');
        }

        List<Process_Bulk_Custom_Emails__c> toInsert = new List<Process_Bulk_Custom_Emails__c>();

        for (String prId : parentRecordIds) {
            Process_Bulk_Custom_Emails__c p = new Process_Bulk_Custom_Emails__c();
            p.Custom_Email_Template_Id__c = customEmailTemplateId;
            p.Parent_Record_Id__c = prId;
            p.Merged_Body__c = mergedBodyByRecord != null ? mergedBodyByRecord.get(prId) : null;
            p.Status__c = 'Pending';
            toInsert.add(p);
        }
        insert toInsert;

        Database.executeBatch(new ProcessBulkCustomEmailsBatch(), 1);
    }

}