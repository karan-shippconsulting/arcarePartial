@isTest
public class InvoiceTemplateCombinedController_Test {
@testSetup
    static void testDataSetup(){
         Contact cont=new Contact();
        cont.LastName='TestService';
        cont.FirstName ='Test Frist Name';
        insert cont;
        
        Service__c ser=new Service__c();
        ser.Name = 'Demo Service Name';
        insert ser;
        
        Service_Enrollment__c sr=new Service_Enrollment__c();
        sr.Service__c = ser.Id;
        sr.Account_Number__c='PL1288';
        sr.Client__c = cont.Id;
        insert sr;
        
        Opportunity op=new Opportunity();
        op.Name='demo';
        op.STAGENAME = 'Posted';
        op.Payment_Status__c = 'Open';
        op.CloseDate = Date.Today().addDays(-10);
        op.Service_Enrollment__c = sr.Id;
        op.Amount=240;
        insert op;
       
        Product2 pro2 = new Product2(Name='BXCD', isActive=true,Charge_Type__c='HOURLY SERVICE');
        insert pro2;
          
        PricebookEntry pbe2 =new PricebookEntry(unitprice=0.01,Product2Id=pro2.Id,Pricebook2Id=Test.getStandardPricebookId(),
                                                 isActive=true,UseStandardPrice = false,Original_System_ID__c='Test'+pro2.Id);
        insert pbe2;
        
        OpportunityLineItem OPplineitem2 = new OpportunityLineItem (Quantity=2, OpportunityId=op.Id,
                                                                    UnitPrice=0.01,PriceBookEntryId=pbe2.Id);
        insert OPplineitem2;
        
        
        Product2 pro2DirectExpence = new Product2(Name='BXCD', isActive=true,Charge_Type__c='DIRECT EXPENSE');
        insert pro2DirectExpence;
      
        
        PricebookEntry pbe2DirectExpence =new PricebookEntry(unitprice=0.01,Product2Id=pro2DirectExpence.Id,
        Pricebook2Id=Test.getStandardPricebookId(), isActive=true,UseStandardPrice = false,Original_System_ID__c='Test'+pro2DirectExpence.Id);
        insert pbe2DirectExpence;
              
        OpportunityLineItem OPplineitem2DirectExpence = new OpportunityLineItem (Quantity=2, OpportunityId=op.Id,
                                                                    UnitPrice=0.01,PriceBookEntryId=pbe2DirectExpence.Id);
        insert OPplineitem2DirectExpence;
        
        List<Visualforce_PDF__c> pdfs = new List<Visualforce_PDF__c>();
        Visualforce_PDF__c pdf1 = new Visualforce_PDF__c();
        pdf1.Object_API_Name__c = 'Opportunity';
        pdf1.Visual_Force_Page_Name__c = 'InvoiceTemplateCopy2';
        pdf1.File_Name__c = 'InvoiceTemplateCopy2';
        pdf1.Fields_to_Update_For_Email__c = 'Copy2_Email_Date__c';
        pdf1.Sub_Type__c = 'Email and Update';
        pdf1.Recipient_Address_Field__c='Copy_2_Email__c';
        pdf1.Fields_Values_to_Update_For_Email__c='NOW';
        pdf1.Print_Type__c ='Individual Record';
        pdfs.add(pdf1);
        
        Visualforce_PDF__c pdf2 = new Visualforce_PDF__c();
        pdf2.Object_API_Name__c = 'Opportunity';
        pdf2.Visual_Force_Page_Name__c = 'InvoiceTemplateCopy2';
        pdf2.File_Name__c = 'InvoiceTemplateCopy2';
        pdf2.Fields_to_Update_For_Email__c = 'Copy2_Email_Date__c';
        pdf2.Sub_Type__c = 'Print Preview';
        pdf2.Recipient_Address_Field__c='Copy_1_Email__c';
        pdf2.Fields_Values_to_Update_For_Email__c='NOW';
        pdf2.Print_Type__c ='Individual Record';
        pdfs.add(pdf2);
        
        Visualforce_PDF__c pdf3 = new Visualforce_PDF__c();
        pdf3.Object_API_Name__c = 'Opportunity';
        pdf3.Visual_Force_Page_Name__c = 'InvoiceTemplateCombined';
        pdf3.File_Name__c = 'InvoiceTemplateCombined_';
        pdf3.Fields_to_Update_For_Print__c = 'Copy1_Print_Date__c,Copy2_Print_Date__c,Mail_To_Print_Date__c,Bill_To_Print_Date__c';
        pdf3.Sub_Type__c = 'Print and Update';
        pdf3.Recipient_Address_Field__c='Billing_Email__c,Copy_1_Email__c';
        pdf3.Fields_Values_to_Update_For_Print__c='NOW,NOW,NOW,NOW';
        pdf3.Print_Type__c ='Bulk';
        pdfs.add(pdf3);
        
        insert pdfs;
    }
    @isTest
    static void invoiceTemplateCopy1Test() {
        List<Opportunity> ops = [SELECT Id,
            Service_Enrollment__r.Billing_Attention_To__c,
            Service_Enrollment__r.Billing_Street_1__c,
            Service_Enrollment__r.Billing_Street_2__c,
            Service_Enrollment__r.Billing_City__c,
            Service_Enrollment__r.Billing_State__c,
            Service_Enrollment__r.Billing_Zip_Code__c,
            Service_Enrollment__r.Name,
            Service_enrollment__r.Account_Number__c,
            CloseDate,
            Invoice_Number__c,
            Service_Enrollment__r.Mail_To_Attention__c,
            Service_Enrollment__r.Mail_To_Street_1__c,
            Service_Enrollment__r.Mail_To_Street_2__c,
            Service_Enrollment__r.Mail_To_City__c,
            Service_Enrollment__r.Mail_To_State__c,
            Service_Enrollment__r.Mail_To_Zip_Code__c,
            Service_Enrollment__r.Copy1_Attention_To__c,
            Service_Enrollment__r.Copy1_Street_1__c,
            Service_Enrollment__r.Copy1_Street_2__c,
            Service_Enrollment__r.Copy1_City__c,
            Service_Enrollment__r.Copy1_State__c,
            Service_Enrollment__r.Copy1_Zip_Code__c,
            Service_Enrollment__r.Copy2_Attention_To__c,Service_Enrollment__r.Copy2_Street_1__c,
            Service_Enrollment__r.Copy2_Street_2__c,Service_Enrollment__r.Copy2_City__c,
            Service_Enrollment__r.Copy2_State__c,Service_Enrollment__r.Copy2_Zip_Code__c,
            Account.Name,
                (SELECT ID,Opportunity.Owner.Initials__c,Description,Quantity,UnitPrice,TotalPrice,
                Product2.Charge_Type__c,Time_Entry__r.Entry_Date__c
                FROM OpportunityLineItems)
            FROM Opportunity];
        
        PageReference pageRef = Page.InvoiceTemplateCombined;
        pageRef.getParameters().put('id',String.valueOf(ops[0].Id));
        Test.setCurrentPage(pageRef);
        InvoiceTemplateCombinedController inovice = new InvoiceTemplateCombinedController();
        
    }
}