public without sharing class SignPdfController{
    
    @AuraEnabled(cacheable=true)
    public static String getRecordsId(String recordId) {
        List<Id> lsOfCont = new List<Id>();
        List<ContentDocumentLink> lsOfCDL = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
        String idString='';
        for(integer i=0;i<lsOfCDL.size();i++){
            if(i == lsOfCDL.size()-1){
                idString+= lsOfCDL[i].ContentDocumentId;
            }else{
                idString+= lsOfCDL[i].ContentDocumentId + ',';
            }
            
        }
        System.debug('IDs are '+idString);
        return idString;
    }
    @AuraEnabled
    public static List<String> getData(String recordId){
        System.debug('ID is '+recordId);
        Map<String,String> mapOfData = new Map<String,String>();
        List<ContentDocumentLink> lsOfCDL = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
        List<Id> tempsId =new List<Id>();
        for(ContentDocumentLink tempLoop:lsOfCDL){
            tempsId.add(tempLoop.ContentDocumentId);
        }
        List<ContentVersion> lsOfCV = [SELECT Id,VersionData,FileExtension FROM ContentVersion WHERE ContentDocumentId=:tempsId];
        List<String> lsOfFiles = new  List<String>();
        for(ContentVersion tempLoopCv :lsOfCV){
            lsOfFiles.add(EncodingUtil.base64Encode(tempLoopCv.VersionData));
            System.debug('File Extension is  '+tempLoopCv.FileExtension);
            if((''+tempLoopCv.FileExtension).toLowerCase() == 'pdf'){
               mapOfData.put(''+tempLoopCv.Id+','+'PDF',EncodingUtil.base64Encode(tempLoopCv.VersionData));    
            }else{
                 mapOfData.put(''+tempLoopCv.Id+','+'PDF',EncodingUtil.base64Encode(tempLoopCv.VersionData));
            }
               
        }
        PageReference pr = new PageReference('/apex/SignPdfWithCurrentUser');
        Blob signatureBlob;
        if(!Test.isRunningTest()){
            signatureBlob = pr.getContentAsPdf();
        } else {
            signatureBlob = Blob.valueOf('Sample PDF content');
        }
    	
        lsOfFiles.add(EncodingUtil.base64Encode(signatureBlob));
        return lsOfFiles; 
    }

    @AuraEnabled
    public static void attachPdfOnRecord(String base64Data, String recordId) {
        Blob pdfBlob = EncodingUtil.base64Decode(base64Data);
        List<ContentDocumentLink> lsOfCDL = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId=:recordId];
        String fileName = lsOfCDL[0].ContentDocument.Title;
        delete lsOfCDL;
        
        ContentVersion newVersion = new ContentVersion();
        newVersion.Title = 'Signed_' + fileName;
        newVersion.PathOnClient = '/' + newVersion.Title + '.pdf';
        newVersion.VersionData = pdfBlob;
        newVersion.IsMajorVersion = true;
        newVersion.FirstPublishLocationId = recordId;
        insert newVersion;
        
        /*// Link it back to the same record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = recordId;
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newVersion.Id].ContentDocumentId;
        cdl.ShareType = 'V'; // Viewer
        cdl.Visibility = 'AllUsers';
        insert cdl;*/
    }
}