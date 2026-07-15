@IsTest
private class BenefitsControllerTest {

    @TestSetup
    static void setupData() {
        // Create Contact (Beneficiary)
        Contact c = new Contact(
            LastName = 'Test Beneficiary'
        );
        insert c;

        // Create Benefit child records
        List<Benefit__c> benefits = new List<Benefit__c>();
        for (Integer i = 0; i < 3; i++) {
            benefits.add(new Benefit__c(
                Beneficiary__c = c.Id,
                Benefit_Type__c = 'Type ' + i,
                Benefit_Amount_Month__c = 100 + i
            ));
        }
        insert benefits;
    }

    @IsTest
    static void testGetBenefits() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        BenefitsController.getBenefits(c.Id, DateTime.now().getTime(), null);
        Test.stopTest();
    }

    @IsTest
    static void testGetBenefitsWithNullId() {
        Test.startTest();
        BenefitsController.getBenefits(null, DateTime.now().getTime(), null);
        Test.stopTest();
    }

    @IsTest
    static void testGetBenefitsWithFilterLogic() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        String filter = 'Benefit_Amount_Month__c >= 100';

        Test.startTest();
        BenefitsController.getBenefits(c.Id, DateTime.now().getTime(), filter);
        Test.stopTest();
    }

    @IsTest
    static void testSaveBenefit_Insert() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Benefit__c newBen = new Benefit__c(
            Beneficiary__c = c.Id,
            Benefit_Type__c = 'New Type',
            Benefit_Amount_Month__c = 250
        );

        Test.startTest();
        BenefitsController.saveBenefit(newBen);
        Test.stopTest();
    }

    @IsTest
    static void testSaveBenefit_Update() {
        Benefit__c existing =
            [SELECT Id, Benefit_Amount_Month__c FROM Benefit__c LIMIT 1];

        existing.Benefit_Amount_Month__c += 25;

        Test.startTest();
        BenefitsController.saveBenefit(existing);
        Test.stopTest();
    }

    @IsTest
    static void testSaveBenefit_NullInput() {
        try {
            Test.startTest();
            BenefitsController.saveBenefit(null);
            Test.stopTest();
        } catch (Exception e) {
            // Expected exception
        }
    }
}