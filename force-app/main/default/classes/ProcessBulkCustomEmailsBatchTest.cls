@IsTest
private class ProcessBulkCustomEmailsBatchTest {

private static Id createFileAndLink(Id linkedEntityId, String title) {
    // Insert the version and publish it to the target record
    ContentVersion cv = new ContentVersion(
        Title = title,
        PathOnClient = title + '.pdf',
        VersionData = Blob.valueOf('dummy file body'),
        IsMajorVersion = true,
        FirstPublishLocationId = linkedEntityId
    );
    insert cv;

    cv = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
    ];

    Integer linkCount = [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE ContentDocumentId = :cv.ContentDocumentId
          AND LinkedEntityId    = :linkedEntityId
    ];
    System.assert(linkCount > 0, 'ContentDocumentLink should be created by FirstPublishLocationId.');

    ContentDocument cd = [
        SELECT Id, LatestPublishedVersionId
        FROM ContentDocument
        WHERE Id = :cv.ContentDocumentId
        LIMIT 1
    ];
    System.assertNotEquals(null, cd.LatestPublishedVersionId,
        'LatestPublishedVersionId must be populated after publishing ContentVersion.');

    return cd.LatestPublishedVersionId;
}

    private static Custom_Email_Template__c createTemplate(String name, String parentObj, String fieldPath, String subject) {
        Custom_Email_Template__c tpl = new Custom_Email_Template__c(
            Name = name,
            Subject__c = subject,
            Parent_Object__c = parentObj,
            Recipient_Address_Field__c = fieldPath
        );
        insert tpl;
        return tpl;
    }

    private static Process_Bulk_Custom_Emails__c createBulkItem(Id parentId, Id tplId, String body, String status) {
        Process_Bulk_Custom_Emails__c item = new Process_Bulk_Custom_Emails__c(
            Merged_Body__c = body,
            Parent_Record_Id__c = parentId,
            Custom_Email_Template_Id__c = tplId,
            Status__c = status
        );
        insert item;
        return item;
    }

    
@IsTest
static void testSuccess_withEntityAttachments_andDelete() {
    Account acc = new Account(Name = 'Test Account'); insert acc;
    Contact con = new Contact(LastName = 'Aggarwal', Email = 'contact@example.com', AccountId = acc.Id); insert con;

    // Keep the Case (not used for recipient resolution in this option)
    Case c = new Case(Subject = 'Email Case', Origin = 'Phone', ContactId = con.Id); insert c;

    // Template points to Contact, not Case
    Custom_Email_Template__c tpl = createTemplate('Template Success', 'Contact', 'Email', 'Your Subject');

    // The batch will now resolve recipient from Contact
    Process_Bulk_Custom_Emails__c item = createBulkItem(con.Id, tpl.Id, '<p>Hello, this is a test.</p>', 'Pending');

    // Link files to the actual parent (Contact) and the template
    Id contactFileVersionId = createFileAndLink(con.Id, 'ContactFile');
    Id tplFileVersionId     = createFileAndLink(tpl.Id, 'TemplateFile');

    // Non-pending record (status value doesn’t matter for coverage)
    Process_Bulk_Custom_Emails__c nonPending = createBulkItem(c.Id, tpl.Id, '<p>Should not be processed</p>', 'Success');

    Test.startTest();
    Database.executeBatch(new ProcessBulkCustomEmailsBatch(), 1);
    Test.stopTest();

    // The pending item should be removed now (sendEmail succeeded)
    System.assertEquals(0, [SELECT COUNT() FROM Process_Bulk_Custom_Emails__c WHERE Id = :item.Id],
        'Successful send should delete the pending item.');

    // Sanity: links exist
    System.assert([SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id] > 0);
    System.assert([SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :tpl.Id] > 0);

    }

    @IsTest
    static void testRecipientNotResolved_setsFail() {
        Account acc = new Account(Name = 'No Email Account');
        insert acc;
        Contact conNoEmail = new Contact(LastName = 'Aggarwal', AccountId = acc.Id);
        insert conNoEmail;

        Custom_Email_Template__c tpl = createTemplate(
            'Template No Recipient',
            'Contact',
            'Email',
            'Missing Recipient'
        );

        Process_Bulk_Custom_Emails__c item = createBulkItem(
            conNoEmail.Id, tpl.Id, '<p>Body</p>', 'Pending'
        );

        Test.startTest();
        Database.executeBatch(new ProcessBulkCustomEmailsBatch(), 1);
        Test.stopTest();

        item = [SELECT Id, Status__c, Error_Message__c FROM Process_Bulk_Custom_Emails__c WHERE Id = :item.Id];
        System.assertEquals('Fail', item.Status__c, 'Should mark as Fail when recipient cannot be resolved.');
        System.assertEquals('Recipient email could not be resolved.', item.Error_Message__c, 'Expected specific failure message.');
    }

    @IsTest
    static void testExceptionDuringRecipientResolution_setsFail() {
        Account acc = new Account(Name = 'Exception Account');
        insert acc;

        Case c = new Case(Subject = 'Exception Case', Origin = 'Email');
        insert c;

        Custom_Email_Template__c tplBadParentObj = createTemplate(
            'Template Bad Parent',
            'InvalidObject__c', 
            'SomeField',
            'Exception Subject'
        );

        Process_Bulk_Custom_Emails__c item = createBulkItem(
            c.Id, tplBadParentObj.Id, '<p>Body</p>', 'Pending'
        );

        Test.startTest();
        Database.executeBatch(new ProcessBulkCustomEmailsBatch(), 1);
        Test.stopTest();

        item = [SELECT Id, Status__c, Error_Message__c FROM Process_Bulk_Custom_Emails__c WHERE Id = :item.Id];
        System.assertEquals('Fail', item.Status__c, 'Should mark as Fail when an exception occurs.');
        System.assertNotEquals(null, item.Error_Message__c, 'Exception message should be captured.');
        System.assert(item.Error_Message__c.containsIgnoreCase('sobject') || item.Error_Message__c.containsIgnoreCase('Invalid'),
            'Error message should reflect invalid object type (implementation-specific wording).');
    }

    @IsTest
    static void testResolvePrimitiveEarlyReturn_path_andFail() {
        Account acc = new Account(Name = 'Primitive Account');
        insert acc;

        Case c = new Case(Subject = 'Primitive Case', Origin = 'Web');
        insert c;

               Custom_Email_Template__c tpl = createTemplate(
            'Template Primitive Path',
            'Case',
            'CaseNumber.Something',
            'Primitive Subject'
        );

        Process_Bulk_Custom_Emails__c item = createBulkItem(
            c.Id, tpl.Id, '<p>Body</p>', 'Pending'
        );

        Test.startTest();
        Database.executeBatch(new ProcessBulkCustomEmailsBatch(), 1);
        Test.stopTest();

        item = [SELECT Id, Status__c, Error_Message__c FROM Process_Bulk_Custom_Emails__c WHERE Id = :item.Id];
        System.assertEquals('Fail', item.Status__c, 'Invalid recipient should result in Fail.');
        System.assertNotEquals(null, item.Error_Message__c, 'Should capture an error message for invalid email send attempt.');
    }
}