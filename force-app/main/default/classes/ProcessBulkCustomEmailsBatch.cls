public with sharing class ProcessBulkCustomEmailsBatch implements Database.Batchable<SObject>,
    Database.Stateful, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Merged_Body__c, Parent_Record_Id__c, Custom_Email_Template_Id__c
            FROM Process_Bulk_Custom_Emails__c
            WHERE Status__c = 'Pending'
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Process_Bulk_Custom_Emails__c> scope) {
        for (Process_Bulk_Custom_Emails__c item : scope) {
            try {
                Custom_Email_Template__c tpl = [
                    SELECT Id, Name, Subject__c, Parent_Object__c,
                           Recipient_Address_Field__c, Organization_Wide_Email__c
                    FROM Custom_Email_Template__c
                    WHERE Id = :item.Custom_Email_Template_Id__c
                    LIMIT 1
                ];

                String recipient = resolveRecipientEmail(
                    tpl.Parent_Object__c, item.Parent_Record_Id__c, tpl.Recipient_Address_Field__c
                );
                if (String.isBlank(recipient)) {
                    item.Status__c = 'Fail';
                    item.Error_Message__c  = 'Recipient email could not be resolved.';
                    update item; continue;
                }

                Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('Test PDF');
                } else {
                    PageReference pdfPage = Page.renderPDF;
                    pdfPage.getParameters().put('recId', item.Custom_Email_Template_Id__c);
                    pdfPage.setRedirect(true);
                    pdfBlob = pdfPage.getContentAsPDF();
                }

                Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
                pdfAttachment.setFileName(tpl.Name + '.pdf');
                pdfAttachment.setContentType('application/pdf');
                pdfAttachment.setBody(pdfBlob);

                // ---- Robust file collection (parent + template) ----
                Set<Id> targetIds = new Set<Id>{ item.Parent_Record_Id__c, tpl.Id };
                List<ContentDocumentLink> links = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :targetIds
                ];
                Set<Id> docIds = new Set<Id>();
                for (ContentDocumentLink l : links) {
                    if (l.ContentDocumentId != null) docIds.add(l.ContentDocumentId);
                }
                Set<Id> versionIds = new Set<Id>();
                if (!docIds.isEmpty()) {
                    for (ContentVersion cv : [
                        SELECT Id, ContentDocumentId, IsLatest
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :docIds
                        AND IsLatest = true
                    ]) {
                        versionIds.add(cv.Id); // <-- pass ContentVersion Ids
                    }
                }

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { recipient });
                // if (tpl.Organization_Wide_Email__c != null) mail.setOrgWideEmailAddressId(tpl.Organization_Wide_Email__c);
                mail.setSubject(tpl.Subject__c);
                mail.setHtmlBody(item.Merged_Body__c);
                mail.setFileAttachments(new Messaging.EmailFileAttachment[] { pdfAttachment });

                if (!versionIds.isEmpty()) {
                    mail.setEntityAttachments(new List<Id>(versionIds));
                }

                // --- test seam for coverage of non-success path ---
                Messaging.SendEmailResult[] results = doSend(new Messaging.SingleEmailMessage[] { mail });
                if (results != null && results[0].isSuccess()) {
                    delete item;
                } else {
                    item.Status__c = 'Fail';
                    item.Error_Message__c = (results != null && results[0].getErrors() != null && results[0].getErrors().size() > 0)
                        ? results[0].getErrors()[0].getMessage()
                        : 'Unknown email failure.';
                    update item;
                }

            } catch (Exception ex) {
                item.Status__c = 'Fail';
                item.Error_Message__c  = ex.getMessage();
                update item;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    @TestVisible
    public Messaging.SendEmailResult[] doSend(Messaging.SingleEmailMessage[] mails) {
        return Messaging.sendEmail(mails);
    }

    // ----- FIXED: relationship-safe recipient resolution -----
    private static String resolveRecipientEmail(String parentObjectApiName, Id parentId, String fieldPath) {
        if (String.isBlank(parentObjectApiName) || String.isBlank(fieldPath) || parentId == null) return null;

        List<String> parts = fieldPath.split('\\.');
        String top = parts[0];

        // Try selecting the full field path (relationship-aware). If that fails, fall back to top-level only.
        SObject parent;
        try {
            String soqlFull = 'SELECT ' + fieldPath + ' FROM ' + parentObjectApiName + ' WHERE Id = :parentId LIMIT 1';
            parent = Database.query(soqlFull);
        } catch (Exception e) {
            String soqlTop = 'SELECT ' + top + ' FROM ' + parentObjectApiName + ' WHERE Id = :parentId LIMIT 1';
            parent = Database.query(soqlTop);
        }

        Object current;
        if (parts.size() == 1) {
            current = parent.get(top); // simple field on parent
        } else {
            // first segment is a relationship (e.g., 'Contact')
            current = parent.getSObject(parts[0]);
            for (Integer i = 1; i < parts.size(); i++) {
                if (current == null) return null;
                if (current instanceof SObject) {
                    current = ((SObject)current).get(parts[i]);
                } else {
                    return String.valueOf(current); // primitive encountered early
                }
            }
        }
               return (current == null) ? null : String.valueOf(current);
    }

}