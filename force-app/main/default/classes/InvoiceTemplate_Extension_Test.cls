@isTest
public class InvoiceTemplate_Extension_Test {
   
	@isTest
    static void invoiceTemplateCopy1Test() {
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
        
        System.debug([SELECT id,Days_Aging_Range__c,Payment_Status__c,Service_Enrollment__c,STAGENAME FROM Opportunity]);
        ApexPages.StandardController std = new ApexPages.StandardController(op);
		InvoiceTemplate_Extension ext = new InvoiceTemplate_Extension(std);
        
       	List<Opportunity> opps = [SELECT Id,
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

    }
    
    @isTest
    static void invoiceTemplateCopy2Test() {
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
        
       	List<Opportunity> opps = [SELECT Id,
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
        
        System.debug('---'+[SELECT ID,Days_Aging_Range__c,Amount,Service_Enrollment__c
            FROM Opportunity
            WHERE STAGENAME='Posted' 
            AND Payment_Status__c =:'Open' 
            AND Days_Aging_Range__c!=: null
            ORDER BY Days_Aging_Range__c ASC]);
        
        PageReference pageRef = Page.InvoiceTemplateCombined;
        pageRef.getParameters().put('id',String.valueOf(opps[0].Id+';'));
        Test.setCurrentPage(pageRef);
        
		InvoiceTemplate_Extension invoice = new InvoiceTemplate_Extension();
        invoice.controllerValue = opps[0];
        invoice.setAllVariableValues(opps[0]);
        

    }
}