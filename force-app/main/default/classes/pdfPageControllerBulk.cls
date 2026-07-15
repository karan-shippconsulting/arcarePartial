public with sharing class pdfPageControllerBulk {
    public List<String> pdfText { get; set; }

    public pdfPageControllerBulk() {
        initialize();
    }

    public pdfPageControllerBulk(ApexPages.StandardController con) {
        initialize();
    }

    private void initialize() {
        pdfText = new List<String>();
        String recId = ApexPages.currentPage()?.getParameters()?.get('recId');
        
        if (String.isNotEmpty(recId)) {
            Id currentUserId = UserInfo.getUserId();
            for (Bulk_Custom_Email_Template__c bcet : [SELECT Final_Email_Body__c 
                FROM Bulk_Custom_Email_Template__c 
                WHERE Custom_Email_Template__c = :recId AND CreatedById =: currentUserId]) {
                pdfText.add(bcet.Final_Email_Body__c);
            }
        }
    }
}