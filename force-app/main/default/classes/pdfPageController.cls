public with sharing class pdfPageController {
    public String pdfText {get;set;}
    public pdfPageController() {
        String recId = String.escapeSingleQuotes(ApexPages.currentPage()?.getParameters()?.get('recId'));
        this.pdfText = [Select Id, Final_Body__c from Custom_Email_Template__c where Id=:recId]?.Final_Body__c;
    }
    public pdfPageController(ApexPages.StandardController con){
        String recId = String.escapeSingleQuotes(ApexPages.currentPage()?.getParameters()?.get('recId'));
        this.pdfText = [Select Id, Final_Body__c from Custom_Email_Template__c where Id=:recId]?.Final_Body__c;
    }
}