public without sharing class BenefitsController {

    @AuraEnabled
    public static List<Benefit__c> getBenefits(Id contactId, Long ts, String filterLogic) {
        if (contactId == null) {
            return new List<Benefit__c>();
        }

        String baseQuery =
            'SELECT Id, Benefit_Type__c, Benefit_Status__c, Benefit_Amount_Month__c, Beneficiary__c ' +
            'FROM Benefit__c ' +
            'WHERE Beneficiary__c = :contactId';

        if (String.isNotBlank(filterLogic)) {
            baseQuery += ' AND ' + filterLogic;
        }

        baseQuery += ' ORDER BY CreatedDate ASC';

        return Database.query(baseQuery);
    }

    @AuraEnabled
    public static Benefit__c saveBenefit(Benefit__c ben) {
        if (ben == null) {
            throw new AuraHandledException('Benefit record cannot be null');
        }
        upsert ben;
        return ben;
    }
}