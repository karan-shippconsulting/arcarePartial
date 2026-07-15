@isTest
public class BeneficiaryTriggerTest {    
    @isTest
    static void testAfterUpdateTrigger() {    
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'test';
        insert setting;
        
        True_Link_Trigger_Switch__c	 apiSwitch = new True_Link_Trigger_Switch__c	();
        apiSwitch.Update_Beneficiary__c = true;
        apiSwitch.Update_Beneficiary_Address__c = true;
        insert apiSwitch;
        
        Pooled_Trust__c pt = new Pooled_Trust__c (name='test',Trust_id__c='test');
        insert pt;
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pt.id);
        insert tp;
        contact con = new contact(lastname='test');
        insert con;
        trust__c trust = new trust__c(Name = 'Test Account', Beneficiary__c=con.id, Trust_Status__c = 'Active', Pooled_Trust__c=pt.id, Trust_Portfolio__c= tp.id);
        insert trust;
        
        con.Update_True_Link__c = true;
        update con;
    }
}