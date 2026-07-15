@isTest
public class BulkViewSelectorController_Test {
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
        sr.Copy_1_Invoice_Options__c='Email';
        sr.Copy_1_Email__c = 'test@test.com';
        sr.Client__c = cont.Id;
        insert sr;
        
        Service_Enrollment__c sr1=new Service_Enrollment__c();
        sr1.Service__c = ser.Id;
        sr1.Account_Number__c='PL12883';
        sr1.Copy_1_Invoice_Options__c='Print';
        sr1.Client__c = cont.Id;
        insert sr1;
        
        Opportunity op=new Opportunity();
        op.Name='demo';
        op.STAGENAME = 'Posted';
        op.Payment_Status__c = 'Open';
        op.CloseDate = Date.Today().addDays(-10);
        op.Service_Enrollment__c = sr.Id;
        op.Amount=240;
        insert op;
        
        Opportunity op1=new Opportunity();
        op1.Name='demo';
        op1.STAGENAME = 'Posted';
        op1.Payment_Status__c = 'Open';
        op1.CloseDate = Date.Today().addDays(-10);
        op1.Service_Enrollment__c = sr1.Id;
        op1.Amount=240;
        insert op1;
       
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
        pdf1.Service_Enrollment_Master_Field__c = 'Copy_1_Invoice_Options__c';
        pdf1.Object_API_Name__c = 'Opportunity';
        pdf1.Visual_Force_Page_Name__c = 'InvoiceTemplateCopy2';
        pdf1.File_Name__c = 'InvoiceTemplateCopy2';
        pdf1.Fields_to_Update_For_Email__c = 'Copy2_Email_Date__c';
        pdf1.Sub_Type__c = 'Email';
        pdf1.Recipient_Address_Field__c='Copy_2_Email__c';
        pdf1.Fields_Values_to_Update_For_Email__c='NOW';
        pdf1.Print_Type__c ='Individual Record';
        pdfs.add(pdf1);
        
        Visualforce_PDF__c pdf2 = new Visualforce_PDF__c();
        pdf2.Object_API_Name__c = 'Opportunity';
        pdf2.Service_Enrollment_Master_Field__c = 'Copy_1_Invoice_Options__c';
        pdf2.Visual_Force_Page_Name__c = 'InvoiceTemplateCopy2';
        pdf2.File_Name__c = 'InvoiceTemplateCopy2';
        pdf2.Fields_to_Update_For_Email__c = 'Copy2_Email_Date__c';
        pdf2.Sub_Type__c = 'Print';
        pdf2.Recipient_Address_Field__c='Copy_1_Email__c';
        pdf2.Fields_Values_to_Update_For_Email__c='NOW';
        pdf2.Print_Type__c ='Individual Record';
        pdfs.add(pdf2);
        
        Visualforce_PDF__c pdf3 = new Visualforce_PDF__c();
        pdf3.Object_API_Name__c = 'Opportunity';
        pdf3.Service_Enrollment_Master_Field__c = 'Copy_1_Invoice_Options__c';
        pdf3.Visual_Force_Page_Name__c = 'InvoiceTemplateCombined';
        pdf3.File_Name__c = 'InvoiceTemplateCombined_';
        pdf3.Fields_to_Update_For_Print__c = 'Copy1_Print_Date__c,Copy2_Print_Date__c,Mail_To_Print_Date__c,Bill_To_Print_Date__c';
        pdf3.Sub_Type__c = 'Print';
        pdf3.Recipient_Address_Field__c='Billing_Email__c,Copy_1_Email__c';
        pdf3.Fields_Values_to_Update_For_Print__c='NOW,NOW,NOW,NOW';
        pdf3.Print_Type__c ='Bulk';
        pdfs.add(pdf3);
        
        insert pdfs;
    }
    @isTest
    static void invoiceTemplateCopy1Test() {
        List<String> opIds = new List<String>();
        List<Opportunity> ops = [SELECT id,Days_Aging_Range__c,Payment_Status__c,Service_Enrollment__c,STAGENAME FROM Opportunity];
        for(Opportunity op : ops){
            opIds.add(op.Id);
        }
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(ops);
        BulkViewSelectorController ext = new BulkViewSelectorController(std);
        //BulkViewSelectorController.vfPageSelector(opIds,'Print and Update');
    }
    
    @isTest
    static void invoiceTemplateCopy2Test() {
        List<String> opIds = new List<String>();
        List<Opportunity> ops = [SELECT id,Days_Aging_Range__c,Payment_Status__c,Service_Enrollment__c,STAGENAME FROM Opportunity];
        for(Opportunity op : ops){
            opIds.add(op.Id);
        }
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(ops);
        BulkViewSelectorController ext = new BulkViewSelectorController(std);
        BulkViewSelectorController.vfPageSelector(opIds,'Email and Update');
    }
    @isTest
    static void invoiceTemplateCopy3Test() {
        List<String> opIds = new List<String>();
        List<Opportunity> ops = [SELECT id,Days_Aging_Range__c,Payment_Status__c,Service_Enrollment__c,STAGENAME FROM Opportunity];
        for(Opportunity op : ops){
            opIds.add(op.Id);
        }
        ApexPages.StandardSetController std = new ApexPages.StandardSetController(ops);
        BulkViewSelectorController ext = new BulkViewSelectorController(std);
        BulkViewSelectorController.vfPageSelector(opIds,'Print Preview');
    }
}