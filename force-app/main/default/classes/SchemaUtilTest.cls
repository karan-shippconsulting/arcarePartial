@isTest
public class SchemaUtilTest {
    @testSetup
    static void setup() {
        // Setup test data for EmailTemplate
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
        Id folderId = [Select Id from Folder limit 1].Id;
        emailTemplates.add(new EmailTemplate(Name = 'Test Template',FolderId=folderId,DeveloperName='TEST_Template', TemplateType = 'custom', Subject = 'Test Subject', IsActive = true));
        emailTemplates.add(new EmailTemplate(Name = 'Inactive Template',FolderId=folderId,DeveloperName='INACTIVE_TEMPLATE', TemplateType = 'custom', Subject = 'Inactive Subject', IsActive = false));
      //  insert emailTemplates;

        // Setup test data for Custom_Email_Template__c
        List<Custom_Email_Template__c> customEmailTemplates = new List<Custom_Email_Template__c>();
        customEmailTemplates.add(new Custom_Email_Template__c(Name = 'Test Custom Template',Parent_Object__c = 'Test', Body__c = 'Test Body', Subject__c = 'Test Subject', Active__c = true, Folder__c = 'Client'));
        customEmailTemplates.add(new Custom_Email_Template__c(Name = 'Test Custom Template 1',Parent_Object__c = 'Test', Body__c = 'Test Body', Subject__c = 'Test Subject', Active__c = true, Folder__c = 'Client',
                                                             Document_Checklist_Category__c='Trust documents' , Document_Checklist_Item_Status__c='New'));
        insert customEmailTemplates;
        
        // Setup test data for Contact
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test.contact@example.com');
        insert contact;

        List<Bulk_Custom_Email_Template__c> bulkCustomEmailTemplates = new List<Bulk_Custom_Email_Template__c>();
        bulkcustomEmailTemplates.add(new Bulk_Custom_Email_Template__c(Name = 'Test Bulk Custom Template', Custom_Email_Template__c = customEmailTemplates[0].Id, Record_Id__c = contact.Id));
        insert bulkcustomEmailTemplates;
    }
    
    @isTest
    static void testGetPdfOptions(){
        Test.startTest();
        List<ApexPage> pages = SchemaUtil.getPdfOptions('Account');
        Test.stopTest();
    }

    @isTest
    static void testGetAllFieldsByObject() {
        Test.startTest();
        Map<String,Map<String,String>> fields = SchemaUtil.getAllFieldsByObject('Contact');
        System.assertNotEquals(null, fields);
        System.assert(fields.containsKey('fields'));
        Test.stopTest();
    }
    
    @isTest
    static void testgetFieldValues(){
        Test.startTest();
        SchemaUtil.getFieldType('Account', 'Type');
        List<String> fields = SchemaUtil.getFieldValues('Account','Type');
        Test.stopTest();
    }
    
    @isTest
    static void testgetUpdatableFieldsByObject(){
        Test.startTest();
        List<Map<String,String>> fields = SchemaUtil.getUpdatableFieldsByObject('Contact');
        System.assertNotEquals(null, fields);
        Test.stopTest();
    }

    @isTest
    static void testGetAllEmailTemps() {
        Test.startTest();
        List<EmailTemplate> templates = SchemaUtil.getAllEmailTemps();
        Test.stopTest();
    }

    @isTest
    static void testGenerateStringBody() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE IsActive = true LIMIT 1];
        Test.startTest();
        String body = SchemaUtil.generateStringBody(contact.Id, template.Id);
        boolean hasPermission = SchemaUtil.checkEditPermission(contact.id);
        List<Contact> conList = SchemaUtil.getContactLookupValues(contact.id, 'Contact');
        System.assertNotEquals(null, body);
        Test.stopTest();
    }

    @isTest
    static void testQueryData() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        List<String> fields = new List<String>{'FirstName', 'LastName'};
        Test.startTest();
        List<SObject> result = SchemaUtil.queryData(fields, 'Contact', contact.Id);
        System.assertNotEquals(null, result[0]);
        Test.stopTest();
    }

    @isTest
    static void testGeneratePDF() {
        Custom_Email_Template__c customEmailTemplate = [Select Id from Custom_Email_Template__c limit 1];
        Test.startTest();
        String pdf = SchemaUtil.generatePDF(customEmailTemplate.Id,'default');
        System.assertNotEquals(null, pdf);
        Test.stopTest();
    }

    @isTest
    static void testGetAllEmailTempsCustom() {
        Test.startTest();
        List<Custom_Email_Template__c> templates = SchemaUtil.getAllEmailTempsCustom('Client','Test');
        System.assertEquals(2, templates.size());
        System.assertEquals('Test Custom Template', templates[0].Name);
        Test.stopTest();
    }

    @isTest
    static void testGetCustomEmailById() {
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Test.startTest();
        Custom_Email_Template__c result = SchemaUtil.getCustomEmailById(template.Id);
        System.assertEquals('Test Custom Template', result.Name);
        Test.stopTest();
    }

    @isTest
    static void testGetAllObjects() {
        Test.startTest();
        List<Map<String, String>> objects = SchemaUtil.getAllObjects();
        System.assert(objects.size() > 0);
        Test.stopTest();
    }
    
    @isTest
    static void testgeneratePDFBulk(){
        Account acc = new Account(name='test');
        insert acc;
        SchemaUtil.generatePDFBulk(acc.Id,null);
    }

    @isTest
    static void testSendEmail() {
        Account acc = new Account(name='test');
        insert acc;
        SchemaUtil.getAllOrgWideEmailAddress();
        /*Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test.contact@example.com');
        insert contact;*/
        List<String> toList = new List<String>{'test1@example.com'};
        List<String> ccList = new List<String>{'test2@example.com'};
        String subject = 'Test Subject';
        String emailBody = '<html><body>Test Body</body></html>';
                Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Test.startTest();
        Boolean result = SchemaUtil.sendEmail(toList, ccList, subject, emailBody, null, true,template.Id,'default',new list<String>(), acc.Id,null, true,false);
        Boolean result2 = SchemaUtil.sendEmail(toList, ccList, subject, emailBody, null, true,template.Id,'default',new list<String>{acc.Id}, null,null, true,true);
        System.assert(result);
        Test.stopTest();
    }

    @isTest
    static void testSendEmailForDocumentCheckList() {
        Account acc = new Account(name='test');
        insert acc;
        SchemaUtil.getAttachments(acc.Id);
        List<String> toList = new List<String>{'test1@example.com'};
        List<String> ccList = new List<String>{'test2@example.com'};
        String subject = 'Test Subject';
        String emailBody = '<html><body>Test Body</body></html>';
                Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c where name='Test Custom Template 1' LIMIT 1];
        Test.startTest();
         Boolean result = SchemaUtil.sendEmail(toList, ccList, subject, emailBody, null, true,template.Id,'default',new list<String>(), acc.Id,null, true,false);
        System.assert(result);
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailForDocumentCheckListBulk() {
        Account acc = new Account(name='test');
        insert acc;
        SchemaUtil.getAttachments(acc.Id);
        List<String> toList = new List<String>{'test1@example.com'};
        List<String> ccList = new List<String>{'test2@example.com'};
        String subject = 'Test Subject';
        String emailBody = '<html><body>Test Body</body></html>';
                Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c where name='Test Custom Template 1' LIMIT 1];
        Test.startTest();
        Boolean result = SchemaUtil.sendEmail(toList, ccList, subject, emailBody, null, true,template.Id,'default',new list<String>(), null,new list<String>{acc.Id}, true,true);
        System.assert(result);
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertEmailTemp() {
        Test.startTest();
        SchemaUtil.upsertEmailTemp(null, 'Test Body', 'Test Subject', 'Contact','default','Test','Test','Test','Test','Test','Test', 'Test','Test','Test','Test', null, null);
        List<Custom_Email_Template__c> templates = [SELECT Id, Body__c, Subject__c FROM Custom_Email_Template__c WHERE Subject__c = 'Test Subject'];
        System.assertEquals(3, templates.size());
        System.assertEquals('Test Body', templates[0].Body__c);
        Test.stopTest();
    }

    @isTest
    static void testUpsertEmailTempWithSeparateEmailBody() {
        Test.startTest();
        SchemaUtil.upsertEmailTemp(null, 'Attachment Body', 'Separate Email Body Test', 'Contact', 'default', null, null, null, null, null, null, null, null, null, null, 'Email Body Content', null);
        Test.stopTest();

        Custom_Email_Template__c result = [SELECT Body__c, Email_Body__c FROM Custom_Email_Template__c WHERE Subject__c = 'Separate Email Body Test' LIMIT 1];
        System.assertEquals('Attachment Body', result.Body__c);
        System.assertEquals('Email Body Content', result.Email_Body__c);
    }

    @isTest
    static void testUpsertEmailTempNullSeparateEmailBodyDoesNotClear() {
        Custom_Email_Template__c template = new Custom_Email_Template__c(
            Name = 'Template',
            Parent_Object__c = 'Contact',
            Body__c = 'Old Body',
            Email_Body__c = 'Existing Email Body',
            Subject__c = 'Subject',
            Active__c = true
        );
        insert template;

        Test.startTest();
        SchemaUtil.upsertEmailTemp(template.Id, 'Updated Body', 'Subject', 'Contact', 'default', null, null, null, null, null, null, null, null, null, null, null, null);
        Test.stopTest();

        Custom_Email_Template__c result = [SELECT Body__c, Email_Body__c FROM Custom_Email_Template__c WHERE Id = :template.Id];
        System.assertEquals('Updated Body', result.Body__c);
        System.assertEquals('Existing Email Body', result.Email_Body__c);
    }

    @isTest
    static void testCheckIsImageTextArea() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        String field = 'CreatedBy.FirstName';
        Boolean result;

        Test.startTest();
            result = SchemaUtil.checkIsImageTextArea(field, contact.Id, 'Contact');
        Test.stopTest();

        System.assertEquals(false, result, 'FirstName is not a rich textarea field.');
    }

    @isTest
    static void testMassUpdateFinalBodyOnBulkCustomTemplateRecords() {
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Map<String,String> bodyMap = new Map<String,String>{
            contact.Id => 'Test Body'
        };

        Test.startTest();
            SchemaUtil.massUpdateFinalBodyOnBulkCustomTemplateRecords(template.Id, bodyMap);
        Test.stopTest();
    }

    @isTest
    static void testGetAttachmentsBulk() {
        Account acc1 = new Account(Name = 'Bulk Attach 1');
        Account acc2 = new Account(Name = 'Bulk Attach 2');
        insert new List<Account>{acc1, acc2};
        Test.startTest();
        List<ContentDocumentLink> links = SchemaUtil.getAttachmentsBulk(new List<String>{acc1.Id, acc2.Id});
        Test.stopTest();
        System.assertNotEquals(null, links);
    }

    @isTest
    static void testDeleteAttachment() {
        Account acc = new Account(Name = 'Delete Attach Test');
        insert acc;
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content'),
            FirstPublishLocationId = acc.Id
        );
        insert cv;
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id LIMIT 1];
        Test.startTest();
        SchemaUtil.deleteAttachment(cdl.Id);
        Test.stopTest();
        List<ContentDocumentLink> remaining = [SELECT Id FROM ContentDocumentLink WHERE Id = :cdl.Id];
        System.assertEquals(0, remaining.size());
    }

    @isTest
    static void testUpdateFinalBody() {
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Test.startTest();
        SchemaUtil.updateFinalBody('<p>Final Body</p>', template.Id);
        Test.stopTest();
        Custom_Email_Template__c updated = [SELECT Final_Body__c FROM Custom_Email_Template__c WHERE Id = :template.Id];
        System.assertEquals('<p>Final Body</p>', updated.Final_Body__c);
    }

    @isTest
    static void testMassUpdateFinalBody() {
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Map<String,String> bodyMap = new Map<String,String>{contact.Id => 'Mass Body'};
        Test.startTest();
        SchemaUtil.massUpdateFinalBody(template.Id, bodyMap);
        Test.stopTest();
        List<Bulk_Custom_Email_Template__c> inserted = [SELECT Id FROM Bulk_Custom_Email_Template__c WHERE Custom_Email_Template__c = :template.Id AND Record_Id__c = :contact.Id];
        System.assert(inserted.size() > 0);
    }

    @isTest
    static void testDeleteBulkCustomTemplateRecords() {
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        Test.startTest();
        SchemaUtil.deleteBulkCustomTemplateRecords(template.Id);
        Test.stopTest();
        List<Bulk_Custom_Email_Template__c> remaining = [SELECT Id FROM Bulk_Custom_Email_Template__c WHERE Custom_Email_Template__c = :template.Id];
        System.assertEquals(0, remaining.size());
    }

    @isTest
    static void testGetObjectNameFromId() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        String objectName = SchemaUtil.getObjectNameFromId(contact.Id);
        Test.stopTest();
        System.assertEquals('Contact', objectName);
    }

    @isTest
    static void testGetAllEmailTempsCustomNoFolder() {
        Test.startTest();
        List<Custom_Email_Template__c> templates = SchemaUtil.getAllEmailTempsCustom('', 'Test');
        Test.stopTest();
        System.assertEquals(2, templates.size());
    }

    @isTest
    static void testGetPdfOptionsBulk() {
        Test.startTest();
        List<ApexPage> pages = SchemaUtil.getPdfOptionsBulk('Account');
        Test.stopTest();
        System.assertNotEquals(null, pages);
    }

    @isTest
    static void testCheckIsImageTextAreaCurrentUser() {
        Test.startTest();
        Boolean result = SchemaUtil.checkIsImageTextArea('CurrentUser.FirstName', null, null);
        Test.stopTest();
        System.assertEquals(false, result);
    }

    @isTest
    static void testQueryDataWithCurrentUser() {
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        List<String> fields = new List<String>{'Id', 'currentuser.FirstName'};
        Test.startTest();
        List<SObject> result = SchemaUtil.queryData(fields, 'Contact', contact.Id);
        Test.stopTest();
        System.assertEquals(2, result.size());
    }

    @isTest
    static void testSendEmailNoAttach() {
        Account acc = new Account(Name = 'No Attach Test');
        insert acc;
        Custom_Email_Template__c template = [SELECT Id FROM Custom_Email_Template__c LIMIT 1];
        List<String> toList = new List<String>{'noattach@example.com'};
        Test.startTest();
        Boolean result = SchemaUtil.sendEmail(toList, null, 'Subject', '<p>Body</p>', '0', false, template.Id, 'default', new List<String>(), acc.Id, null, false, false);
        Test.stopTest();
        System.assert(result);
    }
}