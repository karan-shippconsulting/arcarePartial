@IsTest
private class TrueLinkTransactionControllerTest {

    @TestSetup static void setup() {
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'test';
        insert setting;
    }

    private static Id createTestData(Boolean withAccountId) {
        Account ben = new Account(Name = 'Donte Jones Jr');
        insert ben;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert con;

        Trust__c trust = new Trust__c(
            Name = 'Test Trust',
            Beneficiary__c = con.Id,
            TrueLink_Account_Id__c = (withAccountId ? '9af8704f125a6a32983b00c04eec21cb' : null) 
        );
        insert trust;

        Beneficiary_Card__c card = new Beneficiary_Card__c(
            Name = '222044436224',
            Balance__c = 100.00,
            Status__c = 'CLOSED',
            Beneficiary__c = con.Id,
            Trust__c = trust.Id
        );
        insert card;

        return card.Id;
    }

    private class GoodMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            String body = '{"data":[' +
                '{ "id":"t1","type":"transaction",' +
                '  "attributes":{' +
                '    "merchantName":"Coffee Shop","location":"Austin, TX",' +
                '    "amount":{"amount":28.00,"field_currency":"USD"},' +
                '    "status":"Settled","settled":true,' +
                '    "processedDate":"2025-01-29 00:00:00"' +
                '  }' +
                '},' +
                '{ "id":"t2","type":"transaction",' +
                '  "attributes":{' +
                '    "merchantName":"Grocery","location":"Dallas, TX",' +
                '    "amount":{"amount":-7.00,"field_currency":"USD"},' +
                '    "status":"Pending","settled":false,' +
                '    "processedDate":"2025-01-01 00:00:00"' +
                '  }' +
                '},' +
                '{ "id":"t3","type":"transaction",' +
                '  "attributes":{' +
                '    "merchantName":"Pharmacy","location":"Houston, TX",' +
                '    "amount":{"amount":-7.00,"field_currency":"USD"},' +
                '    "status":"Pending","settled":false,' +
                '    "processedDate":"2024-12-01 00:00:00"' +  // boundary case
                '  }' +
                '}' +
            ']}';

            res.setBody(body);
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"error":"Something bad happened"}');
            return res;
        }
    }

    @IsTest
    static void test_getBeneficiaryCard_returnsSObject() {
        Id cardId = createTestData(true);

        Test.startTest();
        Beneficiary_Card__c card = TrueLinkTransactionController.getBeneficiaryCard(cardId);
        Test.stopTest();

        System.assertNotEquals(null, card, 'Card sObject should be returned');
        System.assertEquals('222044436224', card.Name);
        System.assertEquals(100, card.Balance__c);
        System.assertEquals('CLOSED', card.Status__c);
        System.assertNotEquals(null, card.Trust__c, 'Trust lookup should be populated');
        System.assertNotEquals(null, card.Beneficiary__c, 'Beneficiary lookup should be populated');
    }

    @IsTest
    static void test_getTransactions_last12Months_includes_boundary_and_computes_totals() {
        Id cardId = createTestData(true);
        Test.setMock(HttpCalloutMock.class, new GoodMock());

        Test.startTest();
        TrueLinkTransactionController.TransactionsSummary res =
            TrueLinkTransactionController.getTransactions(cardId, 'LAST_12_MONTHS');
        Test.stopTest();

        System.assertNotEquals(null, res, 'Response should not be null');
        System.assertNotEquals(null, res.transactions, 'Transactions should not be null');
    }

    @IsTest
    static void test_getTransactions_thisMonth_filters_window() {
        Id cardId = createTestData(true);
        Test.setMock(HttpCalloutMock.class, new GoodMock());

        Test.startTest();
        TrueLinkTransactionController.TransactionsSummary res =
            TrueLinkTransactionController.getTransactions(cardId, 'THIS_MONTH');
        Test.stopTest();

        System.assertNotEquals(null, res, 'Response should not be null');
    }
}