@isTest
public class TruelinkBeneficiaryRequestBuilderTest {
    
    public static Contact createTestData(){        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc; 
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
                
        Contact party = new Contact(
            lastname = 'Test Account',
            MailingStreet = '123 Main St',
            MailingCity = 'Anytown',
            MailingState = 'CA',
            Mailingpostalcode = '12345',
            Salutation__c = 'Mr',
            email = 'john.doe@example.com',
            mobilephone = '9876543210',
            birthdate = Date.today().addDays(-30)
        );
        insert party;

        trust__c trust = new trust__c(Pooled_Trust__c = pc.Id,Trust_Portfolio__c = tp.id);
        trust.Trust_Status__c = 'Active';
        trust.TrueLink_ID__c = '123123';
        trust.Beneficiary__c=party.id;
        insert trust;
        
        return party;
    }
    
    @isTest
    public static void testBuild() {
        TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
        contact party = createTestData();
        trust__c trust = [select id,Trust_Status__c,TrueLink_ID__c,Pooled_Trust__c,Trust_Portfolio__c from trust__c limit 1];
        TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id,trust.Id,'test',true);
        TruelinkBeneficiaryRequestWrapper wrapper1 = builder.build(party.Id,trust.Id,'test',false);
        TruelinkBeneficiaryRequestWrapper wrapper2 = builder.buildRequestForEinBidUpdate(trust.id);
        TruelinkBeneficiaryRequestWrapper wrapper3 = builder.buildRequestForTrustDisbursement(trust.id);
        TruelinkBeneficiaryAddressRequestWrapper wrapper4 = builder.buildAddress(party.id,trust.TrueLink_ID__c);
        System.assertNotEquals(null, wrapper);
    }

    @isTest
    public static void testBuildSyncsAttributesWhenTogglesOn() {
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Marital_Status__c = true;
        feature.Sync_Living_Situation__c = true;
        upsert feature;

        Contact party = createTestData();
        party.Marital_Status__c = 'Married';
        party.Living_Situation__c = 'Other';
        update party;

        trust__c trust = [select id from trust__c limit 1];
        TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
        TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, null, false);

        System.assertEquals('Married', wrapper.data.attributes.maritalStatus, 'Expected maritalStatus to be synced when the toggle is on');
        System.assertEquals('Other', wrapper.data.attributes.livingSituation, 'Expected livingSituation to be synced when the toggle is on');
    }

    @isTest
    public static void testBuildOmitsAttributesWhenTogglesOff() {
        // NOTE: DML on a custom setting's org defaults record is NOT rolled back at the end of a
        // test method (unlike ordinary sObject DML), so this must restore the toggles to their
        // Sync_On default in a finally block or it will permanently flip live org data to false.
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Marital_Status__c = false;
        feature.Sync_Living_Situation__c = false;
        upsert feature;

        try {
            Contact party = createTestData();
            party.Marital_Status__c = 'Married';
            party.Living_Situation__c = 'Other';
            update party;

            trust__c trust = [select id from trust__c limit 1];
            TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
            TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, null, false);

            System.assertEquals(null, wrapper.data.attributes.maritalStatus, 'Expected maritalStatus to be omitted when the toggle is off');
            System.assertEquals(null, wrapper.data.attributes.livingSituation, 'Expected livingSituation to be omitted when the toggle is off');
        } finally {
            feature.Sync_Marital_Status__c = true;
            feature.Sync_Living_Situation__c = true;
            upsert feature;
        }
    }

    private static Contact createTestDataWithDisabilityDesignation() {
        Contact party = createTestData();

        Truelink_Disability_Designation__c designation = new Truelink_Disability_Designation__c(
            Name = 'Test Designation',
            Truelink_Internal_ID__c = 'TD1'
        );
        insert designation;

        party.Truelink_Disability_Designation__c = designation.Id;
        update party;

        return party;
    }

    @isTest
    public static void testBuildSyncsDisabilityDesignationOnCreateWhenToggleOn() {
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Disability_Designation__c = true;
        upsert feature;

        Contact party = createTestDataWithDisabilityDesignation();
        trust__c trust = [select id from trust__c limit 1];

        TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
        TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, null, false);

        System.assertNotEquals(null, wrapper.data.relationships.disabilityDesignation, 'disabilityDesignation should be set on create when the toggle is on');
        System.assertEquals('disability_designation', wrapper.data.relationships.disabilityDesignation.data.type);
        System.assertEquals('TD1', wrapper.data.relationships.disabilityDesignation.data.id);
    }

    @isTest
    public static void testBuildSyncsDisabilityDesignationOnUpdateWhenToggleOn() {
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Disability_Designation__c = true;
        upsert feature;

        Contact party = createTestDataWithDisabilityDesignation();
        trust__c trust = [select id from trust__c limit 1];

        TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
        TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, 'test-beneficiary-id', true);

        System.assertNotEquals(null, wrapper.data.relationships, 'relationships should be initialized on update so disabilityDesignation can be carried');
        System.assertNotEquals(null, wrapper.data.relationships.disabilityDesignation, 'disabilityDesignation should be set on update when the toggle is on');
        System.assertEquals('disability_designation', wrapper.data.relationships.disabilityDesignation.data.type);
        System.assertEquals('TD1', wrapper.data.relationships.disabilityDesignation.data.id);
        // Update payloads shouldn't pick up address/activePortfolio just because relationships had to be initialized.
        System.assertEquals(null, wrapper.data.relationships.address);
        System.assertEquals(null, wrapper.data.relationships.activePortfolio);
    }

    @isTest
    public static void testBuildOmitsDisabilityDesignationOnCreateWhenToggleOff() {
        // NOTE: DML on a custom setting's org defaults record is NOT rolled back at the end of a
        // test method (unlike ordinary sObject DML), so this must restore the toggle to its
        // Sync_On default in a finally block or it will permanently flip live org data to false.
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Disability_Designation__c = false;
        upsert feature;

        try {
            Contact party = createTestDataWithDisabilityDesignation();
            trust__c trust = [select id from trust__c limit 1];

            TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
            TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, null, false);

            System.assertEquals(null, wrapper.data.relationships.disabilityDesignation, 'disabilityDesignation should be explicitly nulled on create when the toggle is off');
        } finally {
            feature.Sync_Disability_Designation__c = true;
            upsert feature;
        }
    }

    @isTest
    public static void testBuildOmitsDisabilityDesignationOnUpdateWhenToggleOff() {
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        feature.Sync_Disability_Designation__c = false;
        upsert feature;

        try {
            Contact party = createTestDataWithDisabilityDesignation();
            trust__c trust = [select id from trust__c limit 1];

            TruelinkBeneficiaryRequestBuilder builder = new TruelinkBeneficiaryRequestBuilder();
            TruelinkBeneficiaryRequestWrapper wrapper = builder.build(party.Id, trust.Id, 'test-beneficiary-id', true);

            System.assertNotEquals(null, wrapper.data.relationships, 'relationships should still be initialized on update even when the toggle is off');
            System.assertEquals(null, wrapper.data.relationships.disabilityDesignation, 'disabilityDesignation should be explicitly nulled on update when the toggle is off');
        } finally {
            feature.Sync_Disability_Designation__c = true;
            upsert feature;
        }
    }

}