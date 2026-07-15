public without sharing class remainderPersonTableController {

    @AuraEnabled
    public static List<Remainder_Person__c> getRemainderPeople(
        Id closingId,
        Long ts,
        String filterLogic
    ) {
        if (closingId == null) {
            return new List<Remainder_Person__c>();
        }

        String q =
            'SELECT Id, Closing__c, Remainder_Person_Contact__c, Remainder_Person_Address__c, ' +
            'Remainder_Person_First_Name__c, Remainder_Person_Last_Name__c, ' +
            'Remainder_Person_Phone__c, Remainder_Person_Email__c, ' +
            'Percent_of_Remaining_Funds__c, Status__c ' +
            'FROM Remainder_Person__c ' +
            'WHERE Closing__c = :closingId';


        if (String.isNotBlank(filterLogic)) {
            q += ' AND ' + filterLogic;
        }

        q += ' ORDER BY CreatedDate ASC';
        return Database.query(q);
    }

    @AuraEnabled
    public static Remainder_Person__c saveRemainderPerson(Remainder_Person__c rp) {
        if (rp == null) {
            throw new AuraHandledException('Remainder Person record cannot be null');
        }
        upsert rp;
        return rp;
    }
}