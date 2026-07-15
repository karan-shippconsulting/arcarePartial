@isTest
public class TrueLinkApiHandlerTest {

    @TestSetup static void setup() {
        TruelinkData__c setting = new TruelinkData__c();
        setting.ApiKey__c = 'Apikey test';
        setting.Endpoint__c = 'test';
        insert setting;
        
        True_Link_Trigger_Switch__c	 apiSwitch = new True_Link_Trigger_Switch__c();
        apiSwitch.Create_Beneficiary__c = true;
        apiSwitch.Update_Beneficiary__c = true;
        apiSwitch.Update_Beneficiary_Address__c = true;
        insert apiSwitch;

        Truelink_Feature_Management__c feature = new Truelink_Feature_Management__c();
        feature.Deposit_Last_Run_Datetime__c = System.now();
        feature.Disbursement_Last_Run_Datetime__c = System.now();
        feature.Lookback_Period_In_Minutes__c = 1000;
        insert feature;
	}
    @isTest
    static void testCreateTrustBeneficiary() {
        // Set up mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new TruelinkRestUtilMock());
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        // Test data setup
        trust__c acc = new trust__c(Name='Test Account', Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id,Disbursement_Creation_Enabled__c = false); 
        insert acc;
        
        trust__c acc2 = new trust__c(Name='Account VALUE NEW', Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, TrueLink_Id__c='TestTrustId2');
        insert acc2;
        
        // Execute the method
        TrueLinkApiHandler.createTrustBeneficiaryAddress(acc.Id, 'TestTrustId2');
        TrueLinkApiHandler.updateTrustBeneficiaryAddress(acc.Id, 'TestTrustId2');
        TrueLinkApiHandler.updateTrust(acc.Id, 'TestTrustId2');
        //TrueLinkApiHandler.updateAccountBalanceTest(acc.Id);
        acc.Enrollment_Fee_Verified__c = True;
        acc.Trust_Status__c = 'Active';
        update acc;
        
    }
    
    @isTest
    static void testUpdateTrust() {
        // Set up mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new TruelinkRestUtilMock());
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        // Test data setup
        trust__c acc = new trust__c(Name='Test Account', Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id,Disbursement_Creation_Enabled__c = false); 
        insert acc;
        
        trust__c acc2 = new trust__c(Name='Account VALUE NEW', Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, TrueLink_Id__c='TestTrustId2');
        insert acc2;
        acc.Enrollment_Fee_Verified__c = True;
        acc.Trust_Status__c = 'Active';
        acc.Disbursement_Creation_Enabled__c = true;
        acc.TrueLink_ID__c = '124';
        update acc;
        
        try{
            acc.Update_EIN_and_BID__c = true;
            update acc;
        } catch(exception e){}
    }
    
    @isTest
    static void testUpdateTrustBeneficiary() {
        // Set up mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new TruelinkRestUtilMock());
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        Id rtId = [SELECT Id FROM RecordType WHERE IsPersonType = TRUE AND SObjectType='Account' LIMIT 1].Id;
        Account acct = new Account(FirstName = 'Test',
            LastName = 'Beneficiary',Update_True_Link__pc = true,recordTypeId=rtId);
        insert acct;
        Contact personContact = [SELECT Id FROM Contact where AccountId =: acct.Id];
        // Test data setup
        trust__c acc = new trust__c(Name='Test Account', beneficiary__c=personContact.Id, Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, Trust_Status__c='Active',TrueLink_Id__c='TestTrustId');
        insert acc;

        acct.Living_Street_1__pc='test';
        update acct;
        
        acc.Truelink_Address_Id__c = '124';
        update acc;
        update acct;
        
        // Execute the method
        //        TrueLinkApiHandler.updateTrustBeneficiary(acc.Id, acc.Id, 'TestBeneficiaryId');
    }
    
    @isTest
    static void testAddressUpdateTrustBeneficiary() {
        // Set up mock for HTTP callout
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        Id rtId = [SELECT Id FROM RecordType WHERE IsPersonType = TRUE AND SObjectType='Account' LIMIT 1].Id;
        Account acct = new Account(FirstName = 'Test',
            LastName = 'Beneficiary',Update_True_Link__pc = true,recordTypeId=rtId);
        insert acct;
        Contact personContact = [SELECT Id FROM Contact where AccountId =: acct.Id];

        trust__c acc = new trust__c(Name='Test Account', beneficiary__c=personContact.Id, Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, Trust_Status__c='Active',TrueLink_Id__c='TestTrustId');
        insert acc;
        
        acct.living_street_1__pc='test';
        update acct;
        
        // Execute the method
        //        TrueLinkApiHandler.updateTrustBeneficiary(acc.Id, acc.Id, 'TestBeneficiaryId');
    }
    
    @isTest
    static void testUpdateAccountBalance() {
        // Set up mock for HTTP callout
        Test.setMock(HttpCalloutMock.class, new TruelinkRestUtilMock2());
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        trust__c acc = new trust__c(Name='Test Trust Account', beneficiary__c=con.id, Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, TrueLink_Id__c='TestTrustId', Trust_Status__c='Inactive');
        insert acc;
        trust__c acc1 = new trust__c(Name='Test Trust Account', beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id, TrueLink_Id__c='TestTrustId1', Trust_Status__c='Active');
        insert acc1;
        
        // Execute the method
        Test.startTest();
            TrueLinkApiHandler.updateAccountBalance(acc1.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testUpdateDeposit() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new transactionsMock());
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        // Test data setup
        trust__c trust = new trust__c(Name='Test Account', truelink_Id__c='abc',Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id,Disbursement_Creation_Enabled__c = false,trust_status__c='Active'); 
        insert trust;
        
        // Run test in test context
        Test.startTest();
        // Call the method
        TrueLinkApiHandler.updateDeposit(trust.Id);
        //TrueLinkApiHandler.updateDisbursement(trust.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateDisbursement() {
        // Mock the HTTP response
        Test.setMock(HttpCalloutMock.class, new transactionsMock());
        
        contact con = new contact(lastname='Account VALUE NEW' );
        insert con;
        
        Pooled_Trust__c pc = new Pooled_Trust__c(Trust_Id__c = 'AB123');
        insert pc;
        
        Trust_Portfolio__c tp = new Trust_Portfolio__c (name='test', Is_Default__c=true, True_Link_Portfolio_ID__c='test', Type__c='Portfolio', Pooled_Trust__c=pc.id);
        insert tp;
        
        // Test data setup
        trust__c trust = new trust__c(Name='Test Account', truelink_Id__c='abc',Beneficiary__c=con.id,Trust_Portfolio__c=tp.id, Pooled_Trust__c=pc.id,Disbursement_Creation_Enabled__c = false,trust_status__c='Active'); 
        insert trust;
        
        // Run test in test context
        Test.startTest();
        // Call the method
        TrueLinkApiHandler.updateDisbursement(trust.Id);
        Test.stopTest();
    }
    
    // Define the mock class
    private class TruelinkRestUtilMock implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"id":"adasdad","meta":{"totalAccountBalance":1000.00},"relationships":{"address":{"data":{"id":"TEST ADDRESS ID"}},"activePortfolio":{"data":{"id":"TestPortfolioId"}}}}}');
            return res;
        }
    }
    
     private class TruelinkRestUtilMock2 implements HttpCalloutMock { 
         
        public HTTPResponse respond(HTTPRequest req) {
            String jsonPayload = '{' +
    '"data": {' +
        '"type": "trust_beneficiary",' +
        '"id": "dontel-jones-x2820769",' +
        '"attributes": {' +
            '"prefix": null,' +
            '"firstName": "Dontel",' +
            '"middleName": "Jerraud",' +
            '"lastName": "Jones",' +
            '"suffix": "Jr",' +
            '"mobile": null,' +
            '"email": null,' +
            '"externalId": "3774",' +
            '"ein": null,' +
            '"taxIdNumberType": null,' +
            '"age": 19,' +
            '"dob": "2006-08-27",' +
            '"gender": "Male",' +
            '"overdrawAllowed": false,' +
            '"trustBeneficiaryInternalId": "832214",' +
            '"maritalStatus": null,' +
            '"livingSituation": null,' +
            '"beneficiaryId": "IV",' +
            '"chargeSetupFee": false,' +
            '"disallowDisbursementRequests": false,' +
            '"mailStatement": true,' +
            '"taxDocRecipientConnectionId": null,' +
            '"status": "Active"' +
        '},' +
        '"relationships": {' +
            '"accounts": {' +
                '"data": [' +
                    '{' +
                        '"type": "account",' +
                        '"id": "9af8704f125a6a32983b00c04eec21cb"' +
                    '}' +
                ']' +
            '},' +
            '"address": {' +
                '"data": {' +
                    '"type": "address",' +
                    '"id": "01f35a2fd0be7c0004674f5647005e57"' +
                '}' +
            '},' +
            '"disabilityDesignation": null,' +
            '"governmentBenefitsTrustBeneficiary": {' +
                '"data": []' +
            '},' +
            '"organization": {' +
                '"data": {' +
                    '"type": "organization",' +
                    '"id": "arc-of-texas-x4540358"' +
                '}' +
            '},' +
            '"trust": {' +
                '"data": {' +
                    '"type": "trust",' +
                    '"id": "the-arc-of-texas-master-pooled-trust-x7411271"' +
                '}' +
            '},' +
            '"activePortfolio": {' +
                '"data": {' +
                    '"type": "portfolio",' +
                    '"id": "the-arc-of-texas-investment"' +
                '}' +
            '},' +
            '"primaryCard": {' +
                '"data": {' +
                    '"type": "card",' +
                    '"id": "tamerie-jones-x5070323"' +
                '}' +
            '},' +
            '"organizationCard": null' +
        '},' +
        '"meta": {' +
            '"totalAccountBalance": 17629.016534071598,' +
            '"availableCashSum": {' +
                '"amount": -2000.0,' +
                '"currency": "USD"' +
            '}' +
        '}' +
    '},' +
    '"included": [' +
        '{' +
            '"type": "card",' +
            '"id": "tamerie-jones-x5070323",' +
            '"attributes": {' +
                '"lastFour": "0487",' +
                '"cardReference": "222044436224",' +
                '"program": "professional_trust",' +
                '"status": "CLOSED",' +
                '"expiryDate": "2026-09-30",' +
                '"balance": {' +
                    '"amount": 0.0,' +
                    '"currency": "USD",' +
                    '"timestamp": "2025-10-29T00:38:58.000Z"' +
                '},' +
                '"isBreached": false,' +
                '"breach": null,' +
                '"fraudBlockType": null' +
            '},' +
            '"relationships": {' +
                '"cardReissues": {' +
                    '"data": []' +
                '}' +
            '}' +
        '}' +
    ']' +
    '}';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(jsonPayload);
            return res;
        }
    }
    
    private class transactionsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String json = '{'+
		'  "data": ['+
		'    {'+
		'      "id": "string",'+
		'      "type": "disbursement",'+
		'      "attributes": {'+
		'        "amount": {'+
		'          "amount": 0,'+
		'          "currency": "USD"'+
		'        },'+
		'        "clearedDate": "2024-12-25",'+
		'        "checkMemoLine": "string",'+
		'        "deliveryDate": "2024-12-25",'+
		'        "payeeAddress": {'+
		'          "street1": "string",'+
		'          "street2": "string",'+
		'          "city": "string",'+
		'          "state": "string",'+
		'          "zip": "string"'+
		'        },'+
		'        "payeeBankAccount": {'+
		'          "accountNumber": "string",'+
		'          "routingNumber": "string"'+
		'        },'+
		'        "payeeMemo": "string",'+
		'        "payeeDisposition": "string",'+
		'        "payeeName": "string",'+
		'        "payeeDescription": "string",'+
		'        "payeeSpecialInstructions": "string",'+
		'        "payeeSwiftCode": "string",'+
		'        "paymentMethod": "string",'+
		'        "postageType": "string",'+
		'        "status": "string",'+
		'        "requestorDescription": "string",'+
		'        "requestedBySignature": "string",'+
		'        "postageCode": 0,'+
		'        "checkNum": 0,'+
		'        "updatedAt": "2024-12-25T08:35:27.825Z"'+
		'      },'+
		'      "meta": {'+
		'        "displayCategory": "string",'+
		'        "displayPaymentMethod": "string"'+
		'      },'+
		'      "relationships": {'+
		'        "attachments": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "attachment"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "decisions": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "disbursement_decision"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "categoryAmounts": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "disbursement_category_amount"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "smartpayablesInsert": {'+
		'          "data": {'+
		'            "id": "string",'+
		'            "type": "attachment"'+
		'          }'+
		'        },'+
		'        "sourceBankAccount": {'+
		'          "data": {'+
		'            "id": "string",'+
		'            "type": "bank_account"'+
		'          }'+
		'        }'+
		'      }'+
		'    }'+
		'  ],'+
		'  "included": ['+
		'    {'+
		'      "id": "string",'+
		'      "type": "user",'+
		'      "attributes": {'+
		'        "firstName": "string",'+
		'        "lastName": "string",'+
		'        "email": "string",'+
		'        "siteAdmin": true'+
		'      },'+
		'      "meta": {}'+
		'    },'+
		'    {'+
		'      "id": "string",'+
		'      "type": "disbursement_category_amount",'+
		'      "attributes": {'+
		'        "firstName": "string",'+
		'        "lastName": "string",'+
		'        "email": "string",'+
		'        "siteAdmin": true,'+
		'        "amount": {'+
		'          "amount": 0,'+
		'          "currency": "USD"'+
		'        },'+
		'        "category": "string",'+
		'        "notes": "string"'+
		'      },'+
		'      "meta": {},'+
		'      "relationships": {'+
		'        "attachments": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "attachment"'+
		'            }'+
		'          ]'+
		'        }'+
		'      }'+
		'    }'+
		'  ],'+
		'  "meta": {'+
		'    "page": {},'+
		'    "displayCategory": "string",'+
		'    "displayPaymentMethod": "string"'+
		'  }'+
		'}';
            res.setBody(json); // Sample JSON response
            res.setStatusCode(200);
            return res;
        }
    }
}