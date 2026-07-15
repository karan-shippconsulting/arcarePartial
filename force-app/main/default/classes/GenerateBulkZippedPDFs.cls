public class GenerateBulkZippedPDFs implements Queueable, Database.AllowsCallouts {
	 public Visualforce_PDF__c vfPageTemplateRecord;
	 public String CONTENT_FOLDER_NAME;
	 public String VF_PAGE_DOMAIN = System.Label.BulkPrintVFPageURL;
	 public set<String> newSelectedOpportunity = new set<String>();

	 public GenerateBulkZippedPDFs(Visualforce_PDF__c vfPageTemplateRecord, String CONTENT_FOLDER_NAME, List<String> newSelectedOpportunity){
		this.vfPageTemplateRecord = vfPageTemplateRecord;
		this.CONTENT_FOLDER_NAME = CONTENT_FOLDER_NAME;
		this.newSelectedOpportunity.addAll(newSelectedOpportunity);
	 }

	 public void execute(QueueableContext context) {
        List<String> VfPages = new list<String>();
		map<String,ContentVersion> bulkPagesMap = new map<String,ContentVersion>();
		map<id,Opportunity> opportunitymap = new map<id,Opportunity>([select id,name,CloseDate,Service_Enrollment__c,Service_Enrollment__r.Mail_To_Invoice_Options__c,
		 Service_Enrollment__r.Copy_2_Invoice_Options__c, Service_Enrollment__r.Copy_1_Invoice_Options__c, Service_Enrollment__r.Billing_Invoice_Options__c
		 from opportunity where id In :newSelectedOpportunity]);
 		List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();

		ContentWorkspace ws = [SELECT Id, RootContentFolderId FROM ContentWorkspace WHERE Name =: CONTENT_FOLDER_NAME LIMIT 1];
		
         if(!String.isBlank(vfPageTemplateRecord.VF_Pages_for_Zipping__c)){
            if(vfPageTemplateRecord.VF_Pages_for_Zipping__c.contains(',')){
                VfPages = vfPageTemplateRecord.VF_Pages_for_Zipping__c.split(',');
            } else {
                VfPages.add(vfPageTemplateRecord.VF_Pages_for_Zipping__c);
            }
         }
		

		Compression.ZipWriter writer = new Compression.ZipWriter();
        String zipfilename = '';
		for(String oppId : newSelectedOpportunity){
			for(String vfPage : VfPages){
				if( 
                (opportunitymap.get(oppId).Service_Enrollment__r.Mail_To_Invoice_Options__c!=null && opportunitymap.get(oppId).Service_Enrollment__r.Mail_To_Invoice_Options__c.contains('Print') && vfPage=='InvoiceTemplateMailTo') ||
				(opportunitymap.get(oppId).Service_Enrollment__r.Copy_2_Invoice_Options__c!=null && opportunitymap.get(oppId).Service_Enrollment__r.Copy_2_Invoice_Options__c.contains('Print') && vfPage=='InvoiceTemplateCopy2') || 
				(opportunitymap.get(oppId).Service_Enrollment__r.Copy_1_Invoice_Options__c!=null && opportunitymap.get(oppId).Service_Enrollment__r.Copy_1_Invoice_Options__c.contains('Print') && vfPage=='InvoiceTemplateCopy1') || 
				(opportunitymap.get(oppId).Service_Enrollment__r.Billing_Invoice_Options__c!=null && opportunitymap.get(oppId).Service_Enrollment__r.Billing_Invoice_Options__c.contains('Print') && vfPage=='InvoiceTemplateBillTo')
				){
					PageReference reportPage = new PageReference(VF_PAGE_DOMAIN+vfPage+'?id='+oppId);

					Date closeDate = opportunitymap.get(oppId).CloseDate;
					String formattedDate = String.valueOf(closeDate.year()) +
                       String.valueOf(closeDate.month())+
                       String.valueOf(closeDate.day());

					String filename = formattedDate + '_' + opportunitymap.get(oppId).Name + '_' + vfPage.replace('Template','_');
					zipfilename =  formattedDate + '_' + 'InvoiceMailing';
                    blob forArchieveEntry;
                    if(Test.isRunningTest()){
                        forArchieveEntry = null;
                    } else {
                    	forArchieveEntry = reportPage.getContentAsPDF();
                    }
					writer.addEntry(filename + '.pdf',forArchieveEntry );
				}
				
			 }
		 }
		 blob zipAttachment = writer.getArchive();
         
         // Step 1: Insert ContentVersion
        ContentVersion conVer = new ContentVersion();
        conVer.Title = zipfilename;
        conVer.PathOnClient = zipfilename + '.zip';
        conVer.VersionData = zipAttachment;
        conVer.IsMajorVersion = true;
        conVer.FirstPublishLocationId = ws.Id;
        if(!Test.isRunningTest())
        	insert conVer;
        
        /*// Step 2: Get ContentDocumentId
        Id contentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :conVer.Id
        ]?.ContentDocumentId;
        
        // Step 4: Attach to Library
        ContentWorkspaceDoc workspaceDoc = new ContentWorkspaceDoc();
        workspaceDoc.ContentWorkspaceId = ws.Id;
        workspaceDoc.ContentDocumentId = contentDocumentId;
        if(!Test.isRunningTest())
        	insert workspaceDoc;*/
                
    }
}