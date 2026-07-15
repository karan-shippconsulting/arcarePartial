@isTest
private class CreateTruelinkBeneficiaryTest {
    @TestSetup
    static void setupTestData() {
        Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new CreateTruelinkBeneficiaryMock());
        Account acc = new Account(FirstName = 'Test', LastName = 'Account', RecordTypeId = personAccountRecordTypeId);
        insert acc;
        
        Case testCase = new Case(
            Beneficiary_First_Name__c = 'John',
            Beneficiary_Last_Name__c = 'Doe',
            SuppliedEmail = 'john.doe@example.com',
            SuppliedPhone = '1234567890',
            Birthdate__c = Date.today().addYears(-30),
            Living_Situation__c = 'Independent',
            Disability_Designation__c = 'Traumatic brain injury (TBI)',
            Address_Line_1__c = '123 Test St',
            City__c = 'TestCity',
            State__c = 'ME',
            Zip_Code__c = '12345',
            Gender__c = 'Male',
            Maritial_Status__c = 'Never married',
            Address_Ext_Id__c = 'xyz123425',
            AccountId = acc.Id,
            Enter_to_TrueLink_now__c = 'Yes',
            Beneficiary_Profile__c = acc.Id,
            SSN__c = '123456789'
        );
        insert testCase;
    }
    
    @isTest
    static void testCreateTruelinkBeneficiary() {
        Test.setMock(HttpCalloutMock.class, new CreateTruelinkBeneficiaryMock());
        
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<Id> caseIds = new List<Id>{testCase.Id};
            
            Test.startTest();
        CreateTruelinkBeneficiary batch = new CreateTruelinkBeneficiary(caseIds);
        Database.executeBatch(batch);
        CreateTruelinkBeneficiary.createException('API_Exception','Address update request failed with status Code');
        Test.stopTest();
        
        testCase = [SELECT External_Id__c, Address_Ext_Id__c FROM Case WHERE Id = :testCase.Id];
        System.assertNotEquals(null, testCase.External_Id__c, 'External_Id__c should be populated');
        System.assertNotEquals(null, testCase.Address_Ext_Id__c, 'Address_Ext_Id__c should be populated');
    }
    
    @isTest
    static void testCreateTruelinkBeneficiaryWithInvalidDisability() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.Disability_Designation__c = 'Behavior Disorder';
        update testCase;
        
        Test.setMock(HttpCalloutMock.class, new CreateTruelinkBeneficiaryMock());
        
        Test.startTest();
        CreateTruelinkBeneficiary batch = new CreateTruelinkBeneficiary(new List<Id>{testCase.Id});
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateTruelinkBeneficiaryWithExistingExternalId() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.External_Id__c = 'existing-external-id';
        update testCase;
        
        Test.setMock(HttpCalloutMock.class, new CreateTruelinkBeneficiaryMock());
        
        Test.startTest();
        CreateTruelinkBeneficiary batch = new CreateTruelinkBeneficiary(new List<Id>{testCase.Id});
        Database.executeBatch(batch);
        Test.stopTest();
        
        testCase = [SELECT External_Id__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals('existing-external-id', testCase.External_Id__c, 'Existing External_Id__c should not be changed');
    }
    
    public class CreateTruelinkBeneficiaryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('disability_designations')) {
                res.setBody('{"data":[{"type":"disability_designation","id":"1","attributes":{"name":"Amputation"}},{"type":"disability_designation","id":"2","attributes":{"name":"Attention deficit hyperactivity disorder (ADHD)"}},{"type":"disability_designation","id":"3","attributes":{"name":"Autism spectrum"}},{"type":"disability_designation","id":"4","attributes":{"name":"Autoimmune"}},{"type":"disability_designation","id":"5","attributes":{"name":"Behavior disorder"}},{"type":"disability_designation","id":"6","attributes":{"name":"Bipolar"}},{"type":"disability_designation","id":"7","attributes":{"name":"Cancer"}},{"type":"disability_designation","id":"8","attributes":{"name":"Cerebral palsy"}},{"type":"disability_designation","id":"9","attributes":{"name":"Cystic fibrosis"}},{"type":"disability_designation","id":"10","attributes":{"name":"Deaf or hard of hearing"}},{"type":"disability_designation","id":"11","attributes":{"name":"Developmental disability"}},{"type":"disability_designation","id":"12","attributes":{"name":"Down syndrome"}},{"type":"disability_designation","id":"13","attributes":{"name":"Epilepsy"}},{"type":"disability_designation","id":"14","attributes":{"name":"Fibromyalgia"}},{"type":"disability_designation","id":"15","attributes":{"name":"Intellectual and developmental disability (IDD)"}},{"type":"disability_designation","id":"16","attributes":{"name":"Mental health"}},{"type":"disability_designation","id":"17","attributes":{"name":"Multiple sclerosis (MS)"}},{"type":"disability_designation","id":"18","attributes":{"name":"Muscular dystrophy"}},{"type":"disability_designation","id":"19","attributes":{"name":"Musculoskeletal"}},{"type":"disability_designation","id":"20","attributes":{"name":"Neurological"}},{"type":"disability_designation","id":"21","attributes":{"name":"Obsessive compulsive disorder (OCD)"}},{"type":"disability_designation","id":"30","attributes":{"name":"Other"}},{"type":"disability_designation","id":"22","attributes":{"name":"Physical disability"}},{"type":"disability_designation","id":"23","attributes":{"name":"Post-traumatic stress disorder (PTSD)"}},{"type":"disability_designation","id":"24","attributes":{"name":"Schizophrenia"}},{"type":"disability_designation","id":"25","attributes":{"name":"Speech or language impairment"}},{"type":"disability_designation","id":"26","attributes":{"name":"Spinal cord injury"}},{"type":"disability_designation","id":"27","attributes":{"name":"Tourette syndrome"}},{"type":"disability_designation","id":"28","attributes":{"name":"Traumatic brain injury (TBI)"}},{"type":"disability_designation","id":"29","attributes":{"name":"Visual impairment"}}]}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('organizations')) {
                res.setBody('{"data":[{"type":"trust","id":"pact-first-party-snt-x5661391","attributes":{"name":"Arcare - API First Party SNT","type":"pooled","description":null,"displayedPaymentTypes":["Check","EFT","Card","Direct Debit"],"status":"Active"}},{"type":"trust","id":"pact-third-party-snt-x9486180","attributes":{"name":"Arcare - API Third Party SNT","type":"pooled","description":null,"displayedPaymentTypes":["Check","EFT","Card"],"status":"Active"}},{"type":"trust","id":"pact-basic-support-maintenance-x2249849","attributes":{"name":"Arcare - API Test Pool","type":"pooled","description":null,"displayedPaymentTypes":["Check","EFT","Card"],"status":"Inactive"}}],"meta":{"page":{"number":1,"size":25}}}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('trust_beneficiaries')) {
                if (req.getMethod() == 'POST') {
                    res.setBody('{"data":{"id":"ben-ext-id","relationships":{"address":{"data":{"id":"addr-ext-id"}}}}}');
                    res.setStatusCode(201);
                } else if (req.getMethod() == 'PATCH') {
                    res.setBody('{"data":{"id":"existing-external-id","relationships":{"address":{"data":{"id":"addr-ext-id"}}}}}');
                    res.setStatusCode(200);
                }
            } else if (req.getEndpoint().contains('addresses')) {
                if (req.getMethod() == 'PATCH') {
                    res.setStatusCode(204);
                } else {
                    res.setStatusCode(404);
                }
            } else {
                res.setStatusCode(404);
            }
            
            return res;
        }
    }
    
    public class MyCustomException extends Exception {}
    
    @isTest
    public static void ExceptionTest() {
        String exceptionMessage = 'This is a test exception';
        MyCustomException testException = new MyCustomException();
        
        Test.startTest();
        CustomException.LogException(testException);
        Test.stopTest();   
    }
    
    @isTest
    static void testParse() {
        String jsonInput = '{"data":{"type":"trustBeneficiary","attributes":{"prefix":"Mr.","firstName":"John","middleName":"A.","lastName":"Doe","suffix":"Jr.","email":"john.doe@example.com","mobile":"123-456-7890","externalId":"ext-123","ein":"123456789","ssn":"123-45-6789","taxIdNumberType":"Individual","dob":"1980-01-01","gender":"Male","maritalStatus":"Single","livingSituation":"Own"},"relationships":{"address":{"data":{"type":"address","attributes":{"street1":"123 Main St","street2":"Apt 4B","city":"Anytown","state":"CA","zip":"90210"}}},"activePortfolio":{"data":{"id":"portfolio-123","type":"activePortfolio"}},"disabilityDesignation":{"data":{"id":"disability-123","type":"disabilityDesignation"}}}}}';

        TrustBeneficiaryRequest.parse(jsonInput);

    }
}