@isTest
public class TrueLinkConnectionsSyncBatchTest {

    @TestSetup
    static void setup() {
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'https://test.truelinkfinancial.com/api/v2';
        setting.Sandbox_Apikey__c = 'Apikey test';
        setting.Sandbox_Endpoint__c = 'https://test.truelinkfinancial.com/api/v2';
        insert setting;
    }

    @isTest
    static void testBatchExecute() {
        Test.setMock(HttpCalloutMock.class, new ConnectionsMock());

        Contact con = new Contact(LastName = 'Test Beneficiary');
        insert con;

        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'TEST123');
        insert pc;

        Trust_Portfolio__c tp = new Trust_Portfolio__c(
            Name = 'Test Portfolio',
            Is_Default__c = true,
            True_Link_Portfolio_ID__c = 'test-portfolio',
            Type__c = 'Portfolio',
            Pooled_Trust__c = pc.Id
        );
        insert tp;

        Trust__c trust = new Trust__c(
            Name = 'Test Trust',
            Beneficiary__c = con.Id,
            Trust_Portfolio__c = tp.Id,
            Pooled_Trust__c = pc.Id,
            TrueLink_ID__c = 'aaron-streufert-x2364041'
        );
        insert trust;

        Test.startTest();
        Database.executeBatch(new TrueLinkConnectionsSyncBatch(), 1);
        Test.stopTest();

        List<Connections__c> connections = [
            SELECT Id, True_Link_Id__c, First_Name__c, Last_Name__c,
                   Trust__c, Relationship_Types__c, Is_Statement_Recipient__c
            FROM Connections__c
        ];
        System.assertEquals(7, connections.size(), 'Expected 7 connection records');
        System.assertEquals(trust.Id, connections[0].Trust__c, 'Connection should be linked to Trust');
    }

    private class ConnectionsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"data":[' +
                    '{"type":"connection","id":"19471","attributes":{"firstName":"Jessica","lastName":"Dalton","mobile":"9136340783","email":"jessicadalton@lifecentersofkansas.com","companyName":null,"notes":"Relationship: Rep. payee","isCommon":false,"street1":null,"street2":null,"city":null,"state":"","zip":""},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"21624"}}}},' +
                    '{"type":"connection","id":"19472","attributes":{"firstName":"Angela","lastName":"Pitts","mobile":"9134844207","email":"angiepitts1@comcast.net","companyName":null,"notes":"Relationship: Case mgr.","isCommon":false,"street1":null,"street2":null,"city":null,"state":"","zip":""},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"21625"}}}},' +
                    '{"type":"connection","id":"19473","attributes":{"firstName":"Sherry","lastName":"Streufert","mobile":"9133417454","email":"sherrystreufert@yahoo.com","companyName":null,"notes":"Relationship: mother/gdn","isCommon":false,"street1":"4404 W. 78th St.","street2":null,"city":"Prairie Village","state":"KS","zip":"66208"},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"21626"}}}},' +
                    '{"type":"connection","id":"19474","attributes":{"firstName":"Sherry","lastName":"Streufert","mobile":"9135449716","email":"sherrystreufert@yahoo.com","companyName":null,"notes":"Relationship: Mother/gdn","isCommon":false,"street1":"4404 W 78th St","street2":null,"city":"Prairie Village","state":"KS","zip":"66208"},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"21627"}}}},' +
                    '{"type":"connection","id":"19475","attributes":{"firstName":"Stephen","lastName":"Streufert","mobile":null,"email":null,"companyName":null,"notes":"Relationship: father","isCommon":false,"street1":"3313-3 Red Bridge Rd","street2":null,"city":"Kansas City","state":"MO","zip":"64137"},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"21628"}}}},' +
                    '{"type":"connection","id":"27748","attributes":{"firstName":"Amber","lastName":"Hastings","mobile":"9139635229","email":"ahastings37@yahoo.com","companyName":"","notes":"co-guardian","isCommon":false,"street1":"813 Colbern St","street2":"","city":"Belton","state":"MO","zip":"64012"},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"30185"}}}},' +
                    '{"type":"connection","id":"39329","attributes":{"firstName":"Aaron Streufert","lastName":null,"mobile":null,"email":null,"companyName":null,"notes":null,"isCommon":false,"street1":"c/o Sherry Streufert","street2":"4404 W. 78th St.","city":"Prairie Village","state":"KS","zip":"66208"},"relationships":{"organization":{"data":{"type":"organization","id":"arcare-x1349406"}},"connectionRelationship":{"data":{"type":"connection_relationship","id":"42112"}}}}' +
                '],"included":[' +
                    '{"type":"connection_relationship","id":"21624","attributes":{"relationshipTypes":[],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"21625","attributes":{"relationshipTypes":[],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"21626","attributes":{"relationshipTypes":[],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"21627","attributes":{"relationshipTypes":[],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"21628","attributes":{"relationshipTypes":[],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"30185","attributes":{"relationshipTypes":["Guardian","Sister"],"isStatementRecipient":false}},' +
                    '{"type":"connection_relationship","id":"42112","attributes":{"relationshipTypes":[],"isStatementRecipient":true}}' +
                ']}'
            );
            return res;
        }
    }
}