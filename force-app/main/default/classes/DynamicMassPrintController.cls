/**
* @File Name : DynamicMassPrintController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 26, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 26, 2024 |   | Initial Version
**/

public class DynamicMassPrintController {
	@AuraEnabled
	public static LisT<Visualforce_PDF__c> getPDFTempList(String objectName){
		return [Select Id,Name,Email_Body__c,Preview_Parameters_To_Send__c,Visual_Force_Page_Name__c,Type__c,Organization_WIde_Email__c,Email_Subject__C from Visualforce_PDF__c where Print_Type__c = 'Bulk' and IsActive__c = true and Object_Api_Name__c =:objectName ORDER BY Display_Sort_Order__c];
	}

	@AuraEnabled
	public static List<SObject> fetchRecords(List<String> recordList,List<String> queryFields,String objectApiName){
		String queryString = 'Select Id, ' + String.join(queryFields, ' , ') + ' from ' + objectApiName + ' where Id IN :recordList';
		return Database.query(queryString);
	}

	private static String getFieldValueByType(SObject record, String fieldName) {
		
		if (record == null || String.isEmpty(fieldName)) {
			return 'N/A';
		}

		Object fieldValue = record.get(fieldName);
		if (fieldValue == null) {
			return 'N/A';
		}

		Schema.DisplayType fieldType = record.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
		switch on fieldType {
			when DATE {
				return ((Date) fieldValue).format();
			}
			when DATETIME {
				return ((Datetime) fieldValue).format('MM/DD/YYYY HH:mm:ss');
			}
			when CURRENCY {
				return String.valueOf((Decimal) fieldValue);
			}
			when DOUBLE {
				return String.valueOf((Decimal) fieldValue);
			}
			when INTEGER {
				return String.valueOf((Integer) fieldValue);
			}
			when PHONE {
				return (String) fieldValue;
			}
			when BOOLEAN {
				return ((Boolean) fieldValue) ? 'true' : 'false';
			}
			when else {
				return String.valueOf(fieldValue);
			}
		}
	}

	@AuraEnabled
	public static Boolean sendBulkEmail(List<String> recordList,String templateId,String objectApiName){
		Id id = (Id)recordList[0];
		SObjectType dynamicType = id.getSObjectType();
		List<Messaging.SingleEmailMessage> toSend = new List<Messaging.SingleEmailMessage>();
		Visualforce_PDF__c vfPDF = [Select Id,Name,Preview_Parameters_To_Send__c,Email_Body__c,Recipient_Address_Field__c,Visual_Force_Page_Name__c,File_Name__c,Fields_to_Update_For_Email__c,Fields_Values_to_Update_For_Email__c,Organization_WIde_Email__c,Email_Subject__c,Send_Attachment__c from Visualforce_PDF__c where Id=:templateId];
		Set<String> fields = checkFields(vfPDF.Email_Body__c);
		List<sObject> toUpdateRecords = new List<sObject>();
		fields.add(vfPDF.Recipient_Address_Field__c.toLowerCase());

		List<String> fieldApiNames = new List<String>();
		if(String.isNotEmpty(vfPDF.Fields_to_Update_For_Email__c) && vfPDF.Fields_to_Update_For_Email__c.contains(',') ){
			fieldApiNames = vfPDF.Fields_to_Update_For_Email__c.split(',');
		} else if(String.isNotEmpty(vfPDF.Fields_to_Update_For_Email__c) && !vfPDF.Fields_to_Update_For_Email__c.contains(',') ){
			fieldApiNames.add(vfPDF.Fields_to_Update_For_Email__c);
		}

		List<String> fieldApiValues = new List<String>();
		if(String.isNotEmpty(vfPDF.Fields_Values_to_Update_For_Email__c) && vfPDF.Fields_Values_to_Update_For_Email__c.contains(',') ){
			fieldApiValues = vfPDF.Fields_Values_to_Update_For_Email__c.split(',');
		} else if(String.isNotEmpty(vfPDF.Fields_Values_to_Update_For_Email__c) && !vfPDF.Fields_Values_to_Update_For_Email__c.contains(',') ){
			fieldApiValues.add(vfPDF.Fields_Values_to_Update_For_Email__c);
		}

		Map<String, Object> acctBinds = new Map<String, Object>{
			'recordList' => recordList
		};
		String queryString = 'Select Id, ' + String.join(fields, ' , ') + ' from ' + objectApiName + ' where Id IN :recordList';
		System.debug(queryString);
		Map<Id,SObject> recordsMap = new Map<Id,SObject>(Database.queryWithBinds(queryString,acctBinds,AccessLevel.SYSTEM_MODE));
		Pattern regex = Pattern.compile('\\{([^}]*)\\}');
		Type recordType = Type.forName(objectApiName); 
		List<EmailMessage> activityToAdd = new List<EmailMessage>();

		Map<String, Schema.SObjectField> fieldDescribeMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();

		
		for(String key:recordsMap.keyset()){
			Sobject record = recordsMap.get(key);
			List<String> splitOfRecipientField = vfPDF.Recipient_Address_Field__c.split('\\.');
			Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
			List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
			String emailBody = vfPDF.Email_Body__c;
			Map<String,Object> fieldMap = recordsMap.get(key).getPopulatedFieldsAsMap();
			Matcher matcher = regex.matcher(emailBody);
			while (matcher.find()) {
				String fieldName = matcher.group(1); 
                fieldName = fieldName.trim();
				List<String> splitOfBodyField = fieldName.split('\\.');
				String fieldValue;
				if (splitOfBodyField.size() == 4) {
					SObject relatedRecord = (SObject) record.getSObject(splitOfBodyField[0]);
					SObject relatedRecord1 = (SObject) relatedRecord.getSObject(splitOfBodyField[1]);
					SObject relatedRecord2 = (SObject) relatedRecord1.getSObject(splitOfBodyField[2]);
					fieldValue = getFieldValueByType(relatedRecord2, splitOfBodyField[3]);
				}
				else if (splitOfBodyField.size() == 3) {
					SObject relatedRecord = (SObject) record.getSObject(splitOfBodyField[0]);
					SObject relatedRecord1 = (SObject) relatedRecord.getSObject(splitOfBodyField[1]);
					fieldValue = getFieldValueByType(relatedRecord1, splitOfBodyField[2]);
				}
				else if (splitOfBodyField.size() == 2) {
					SObject relatedRecord = (SObject) record.getSObject(splitOfBodyField[0]);
					fieldValue = getFieldValueByType(relatedRecord, splitOfBodyField[1]);
				} 
				else {
					fieldValue = getFieldValueByType(record, fieldName);
				}
                String regexPattern = '(?i)\\{' + Pattern.quote(fieldName) + '\\}';
                emailBody = emailBody.replaceAll( regexPattern, fieldValue != null ? fieldValue : 'N/A');
			}
			mymail.setHtmlBody(emailBody);
			List<String> toList = new List<String>();
			if(!splitOfRecipientField.isEmpty() && splitOfRecipientField.size() == 2){
				toList = new List<String>{(String) record.getSobject(splitOfRecipientField[0]).get(splitOfRecipientField[1])};
			} else {
				toList = new List<String>{(String) record.get(vfPDF.Recipient_Address_Field__c)};
			}

			mymail.setToAddresses(toList);
			
			mymail.setSubject(vfPDF.Email_Subject__c);
			List<OrgWideEmailAddress> owea = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where Address =:vfPDF.Organization_WIde_Email__c];
			if(owea!=null && owea.size() > 0)
				mymail.setOrgWideEmailAddressId(owea[0].Id);

				EmailMessage emailMessage = new EmailMessage();
				emailMessage.Subject = mymail.getSubject();
				emailMessage.HtmlBody = mymail.getHtmlBody();
				//emailMessage.FromName = 'Your Name';
				emailMessage.ToAddress = String.join(toList, ',');
				emailMessage.Status = '3'; // Status "3" typically represents "Sent"
				emailMessage.Incoming = false; // Indicates that this is an outgoing email
				//emailMessage.RelatedToId = key; // The ID of the record to link it to (e.g., an Account or Opportunity)
				//emailMessage.SaveAsActivity = true;

				activityToAdd.add(emailMessage);
        	

			if(String.isNotEmpty(vfPDF.Visual_Force_Page_Name__c) && vfPDF.Send_Attachment__c){
				Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();    
				String formUrl = '';
				if(String.isNotEmpty(vfPDF.Preview_Parameters_To_Send__c)){
					formUrl = '/apex/'+vfPDF.Visual_Force_Page_Name__c+'?'+vfPDF.Preview_Parameters_To_Send__c + '&bulkIds='+key;
				} else {
					formUrl = '/apex/'+vfPDF.Visual_Force_Page_Name__c+'?bulkIds='+ key;
				}
				system.debug('formUrl: '+formUrl);
				PageReference pdfPage = new PageReference(formUrl);            
				//pdfPage.getParameters().put('bulkIds', key);
				if(Test.isRunningTest()){
					efa.setBody(Blob.valueOf('Test'));
				}else{
					efa.setBody(pdfPage.getContentaspdf());   
				}
				efa.setFileName(vfPDF.File_Name__c+Datetime.now()+'.pdf');
				efa.setContentType('application/pdf');
				emailAttachments.add(efa);
				mymail.setFileAttachments(emailAttachments);
			}

			toSend.add(mymail);

			SObject toUpdate = (SObject)recordType.newInstance();
			toUpdate.put('Id',key);

			for(Integer i = 0;i<fieldApiNames.size();i++){
				if(fieldApiValues.get(i) == 'TODAY()'){
					toUpdate.put(fieldApiNames.get(i),Date.Today());
				}else if(fieldApiValues.get(i) == 'NOW()'){
					toUpdate.put(fieldApiNames.get(i),DateTime.now());
				}else{
					toUpdate.put(fieldApiNames.get(i),fieldApiValues.get(i));
				}
			}

			toUpdateRecords.add(toUpdate);
		}
		Boolean allowUpdate = true;
		for(Messaging.SendEmailResult emailResult : Messaging.sendEmail(toSend)){
			if(!emailResult.isSuccess()){
				allowUpdate = false;
				break;
			}
		}

		if(!toUpdateRecords.isEmpty() && allowUpdate){
			update toUpdateRecords;
            if(!Test.isRunningTest())
				insert activityToAdd;
		}
		return allowUpdate;

	}

	@AuraEnabled
	public static void updateBulkPrint(List<String> recordList,String templateId,String objectApiName){
		List<sObject> toUpdateRecords = new List<sObject>();
		Visualforce_PDF__c vfPDF = [Select Id,Preview_Parameters_To_Send__c,Fields_to_Update_For_Print__c,Fields_Values_to_Update_For_Print__c from Visualforce_PDF__c where Id=:templateId];
		
		List<String> fieldApiNames = new List<String>();
		if(String.isNotEmpty(vfPDF.Fields_to_Update_For_Print__c) && vfPDF.Fields_to_Update_For_Print__c.contains(',') ){
			fieldApiNames = vfPDF.Fields_to_Update_For_Print__c.split(',');
		} else if(String.isNotEmpty(vfPDF.Fields_to_Update_For_Print__c) && !vfPDF.Fields_to_Update_For_Print__c.contains(',') ){
			fieldApiNames.add(vfPDF.Fields_to_Update_For_Print__c);
		}

		List<String> fieldApiValues = new List<String>();
		if(String.isNotEmpty(vfPDF.Fields_Values_to_Update_For_Print__c) && vfPDF.Fields_Values_to_Update_For_Print__c.contains(',') ){
			fieldApiValues = vfPDF.Fields_Values_to_Update_For_Print__c.split(',');
		} else if(String.isNotEmpty(vfPDF.Fields_Values_to_Update_For_Print__c) && !vfPDF.Fields_Values_to_Update_For_Print__c.contains(',') ){
			fieldApiValues.add(vfPDF.Fields_Values_to_Update_For_Print__c);
		}
		Type recordType = Type.forName(objectApiName);

		for(String recordId : recordList){
			SObject toUpdate = (SObject)recordType.newInstance();
			toUpdate.put('Id',recordId);

			for(Integer i = 0;i<fieldApiNames.size();i++){
				if(fieldApiValues.get(i) == 'TODAY()'){
					toUpdate.put(fieldApiNames.get(i),Date.Today());
				}else if(fieldApiValues.get(i) == 'NOW()'){
					toUpdate.put(fieldApiNames.get(i),DateTime.now());
				}else{
					toUpdate.put(fieldApiNames.get(i),fieldApiValues.get(i));
				}
			}
			toUpdateRecords.add(toUpdate);
		}

		if(!toUpdateRecords.isEmpty()){
			update toUpdateRecords;
		}
		
	}

	public static Set<String> checkFields(String text) {
		Set<String> matches = new Set<String>();

		Pattern regex = Pattern.compile('\\{([^}]*)\\}');
		Matcher matcher = regex.matcher(text);

		while (matcher.find()) {
			String match = matcher.group(1).toLowerCase();
			if (!matches.contains(match)) {
				matches.add(match.toLowerCase());
			}
		}
		return matches;
	}
}