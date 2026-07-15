public class CreateTruelinkBeneficiary implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private List<Id> caseIds;
    private Map<String, String> disabilityMap;
    private String orgId;

    public CreateTruelinkBeneficiary(List<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Beneficiary_First_Name__c, Beneficiary_Middle_Name__c, Beneficiary_Last_Name__c, SuppliedEmail, External_Id__c, 
            SuppliedPhone, Birthdate__c, Living_Situation__c, Disability_Designation__c, Address_Ext_Id__c, Trust_Type__c,
            Address_Line_1__c, Address_Line_2__c, City__c, Zip_Code__c, State__c, Gender__c, SSN__c, Maritial_Status__c,
            Account.Beneficiary_ID__pc, Mail_Statement__c, Beneficiary_ID__c
            FROM Case 
            WHERE Id IN :caseIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Case> scope) {
        this.disabilityMap = fetchDisabilityDesignations();
        //this.orgId = fetchOrganizationData();
        
        List<Case> caseListToUpdate = new List<case>();
        List<Custom_Exception__c> ceList = new List<Custom_Exception__c>();

        for (Case caseRecord : scope) {

            String jsonRequestBody = createRequestBody(caseRecord);
            HttpResponse res = sendHttpRequest(caseRecord, jsonRequestBody);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Case caseData = processResponse(res, caseRecord);
                if (caseData != null) {
                    caseListToUpdate.add(caseData);
                }
            } else {
                ceList.add(createException('API_Exception', 'API request failed with status Code: ' + res.getStatusCode() + ' \n ' + res.getBody()));
            }

            if (caseRecord.Address_Line_1__c != null || caseRecord.Address_Line_2__c != null ||
                caseRecord.City__c != null || caseRecord.State__c != null || caseRecord.Zip_Code__c != null) {
                    updateAddress(caseRecord, ceList);
                }
        }

        if (!ceList.isEmpty()) {
            insert ceList;
        }
        if (!caseListToUpdate.isEmpty()) {
            update caseListToUpdate;
        }
    }

    private String createRequestBody(Case caseRecord) {
        String formattedDate;
        if(caseRecord.Birthdate__c != null){
            Date birthdate = caseRecord.Birthdate__c;
            String month = birthdate.month() < 10 ? '0' + birthdate.month() : String.valueOf(birthdate.month());
            String day = birthdate.day() < 10 ? '0' + birthdate.day() : String.valueOf(birthdate.day());
            formattedDate = birthdate.year() + '-' + month + '-' + day;
        }

        TrustBeneficiaryRequest requestBody = new TrustBeneficiaryRequest();
        requestBody.data = new TrustBeneficiaryRequest.Data_Y();
        requestBody.data.type = 'trust_beneficiary';
        requestBody.data.attributes = new TrustBeneficiaryRequest.Attributes();
        requestBody.data.attributes.firstName = caseRecord.Beneficiary_First_Name__c;
        requestBody.data.attributes.middleName = caseRecord.Beneficiary_Middle_Name__c;
        requestBody.data.attributes.lastName = caseRecord.Beneficiary_Last_Name__c;
        requestBody.data.attributes.email = caseRecord.SuppliedEmail;
        requestBody.data.attributes.mobile = caseRecord.SuppliedPhone;
        requestBody.data.attributes.externalId = caseRecord.Beneficiary_ID__c;
        requestBody.data.attributes.dob = formattedDate;
        requestBody.data.attributes.ssn = caseRecord.SSN__c;
        requestBody.data.attributes.gender = caseRecord.Gender__c;
        requestBody.data.attributes.maritalStatus = caseRecord.Maritial_Status__c;
        requestBody.data.attributes.livingSituation = caseRecord.Living_Situation__c;
        requestBody.data.attributes.mailStatement = caseRecord.Mail_Statement__c;
        requestBody.data.relationships = new TrustBeneficiaryRequest.Relationships();
        requestBody.data.relationships.address = createAddress(caseRecord);
        requestBody.data.relationships.activePortfolio = createActivePortfolio(caseRecord);
        if(caseRecord.Disability_Designation__c != null){
            requestBody.data.relationships.disabilityDesignation = createDisabilityPortfolio(caseRecord);
        }

        return JSON.serialize(requestBody);
    }

    private TrustBeneficiaryRequest.Address createAddress(Case caseRecord) {
        TrustBeneficiaryRequest.Address address = new TrustBeneficiaryRequest.Address();
        address.data = new TrustBeneficiaryRequest.Data();
        address.data.type = 'address';
        address.data.attributes = new TrustBeneficiaryRequest.Attributes_Z();
        address.data.attributes.street1 = caseRecord.Address_Line_1__c;
        address.data.attributes.street2 = caseRecord.Address_Line_2__c;
        address.data.attributes.city = caseRecord.City__c;
        address.data.attributes.state = caseRecord.State__c; 
        address.data.attributes.zip = caseRecord.Zip_Code__c;
        return address;
    }

    private TrustBeneficiaryRequest.ActivePortfolio createActivePortfolio(Case caseRecord) {
        TrustBeneficiaryRequest.ActivePortfolio activePortfolio = new TrustBeneficiaryRequest.ActivePortfolio();
        activePortfolio.data = new TrustBeneficiaryRequest.Data_Z();
        //activePortfolio.data.id = Label.Portfolio_Id;
        if(caseRecord.Trust_Type__c == 'Pooled Trust I'){
            activePortfolio.data.id = Label.Pooled_Trust_I;
            this.orgId = Label.Trust_One;
        }else if(caseRecord.Trust_Type__c == 'Pooled Trust II'){
            activePortfolio.data.id = Label.Pooled_Trust_II;
            this.orgId = Label.Trust_Two;
        }else if(caseRecord.Trust_Type__c == 'Private Trust I'){
            activePortfolio.data.id = Label.Private_Trust_I;
            this.orgId = Label.Trust_One;
        }else if(caseRecord.Trust_Type__c == 'Private Trust II'){
            activePortfolio.data.id = Label.Private_Trust_II;
            this.orgId = Label.Trust_Two;
        }
        activePortfolio.data.type = 'portfolio';
        return activePortfolio;
    }

    private TrustBeneficiaryRequest.ActivePortfolio createDisabilityPortfolio(Case caseRecord) {
        TrustBeneficiaryRequest.ActivePortfolio disabilityPortfolio = new TrustBeneficiaryRequest.ActivePortfolio();
        disabilityPortfolio.data = new TrustBeneficiaryRequest.Data_Z();
        disabilityPortfolio.data.id = disabilityMap.get(caseRecord.Disability_Designation__c) != null ? disabilityMap.get(caseRecord.Disability_Designation__c) : 'unknown';
        disabilityPortfolio.data.type = 'disability_designation';
        return disabilityPortfolio;
    }

    private HttpResponse sendHttpRequest(Case caseRecord, String jsonRequestBody) {
        String endpoint = String.isBlank(caseRecord.External_Id__c) 
            ? Label.True_Link_API_Endpoint + 'api/v2/trusts/' + orgId + '/trust_beneficiaries'
            : Label.True_Link_API_Endpoint + 'api/v2/trust_beneficiaries/' + caseRecord.External_Id__c;
        String method = String.isBlank(caseRecord.External_Id__c) ? 'POST' : 'PATCH';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'ApiKey ' + Label.True_Link_API_Key);
        req.setBody(jsonRequestBody);

        Http http = new Http();
        return http.send(req);
    }

    private Map<String, String> fetchDisabilityDesignations() {
        Map<String, String> disabilityMap = new Map<String, String>();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(Label.True_Link_API_Endpoint + 'api/v2/disability_designations');
        req.setMethod('GET');
        req.setHeader('Authorization', 'ApiKey ' + Label.True_Link_API_Key);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> dataList = (List<Object>) responseMap.get('data');

            for (Object item : dataList) {
                Map<String, Object> itemMap = (Map<String, Object>) item;
                String id = (String) itemMap.get('id');
                Map<String, Object> attributesMap = (Map<String, Object>) itemMap.get('attributes');
                String name = (String) attributesMap.get('name');
                disabilityMap.put(name, id);
            }
        } else {
            createException('API_Exception', 'Failed to fetch disability designations. Status code: ' + res.getStatusCode());
        }

        return disabilityMap;
    }

    /*private String fetchOrganizationData() {
        Integer listNum = Integer.valueOf(Label.Org_List_Number);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Label.True_Link_API_Endpoint + 'api/v2/organizations/' + Label.Organization_Id + '/trusts/?page[size]=2');
        req.setMethod('GET');
        req.setHeader('Authorization', 'ApiKey ' + Label.True_Link_API_Key);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> dataList = (List<Object>) responseMap.get('data');
            if (!dataList.isEmpty()) {
                return (String) ((Map<String, Object>) dataList.get(listNum)).get('id');
            }
        } else {
            createException('API_Exception', 'Failed to fetch organization data. Status code: ' + res.getStatusCode());
        }

        return null;
    }*/

    private Case processResponse(HttpResponse res, Case caseRecord) {
        try {
            String resdata = res.getBody();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resdata);
            Map<String, Object> dataMap = (Map<String, Object>) responseMap.get('data');
            String beneficiaryExtId = (String) dataMap.get('id');

            Map<String, Object> relationshipsMap = (Map<String, Object>) dataMap.get('relationships');
            Map<String, Object> addressMap = (Map<String, Object>) relationshipsMap.get('address');
            Map<String, Object> addressData = (Map<String, Object>) addressMap.get('data');
            String addressExtId = (String) addressData.get('id');

            if (String.isBlank(caseRecord.External_Id__c)) {
                Case caseToUpdate = new Case(Id = caseRecord.Id);
                caseToUpdate.External_Id__c = beneficiaryExtId;
                caseToUpdate.Address_Ext_Id__c = addressExtId;
                return caseToUpdate;
            }
            return null;
        } catch (Exception ex) {
            CustomException.LogException(ex);
            return null;
        }
    }

    private void updateAddress(Case caseRecord, List<Custom_Exception__c> ceList) {
        if (String.isBlank(caseRecord.Address_Ext_Id__c)) return;

        String endpoint = Label.True_Link_API_Endpoint + 'api/v2/addresses/' + caseRecord.Address_Ext_Id__c;

        Map<String, Object> addressAttributes = new Map<String, Object>();
        addressAttributes.put('street1', caseRecord.Address_Line_1__c);
        addressAttributes.put('street2', caseRecord.Address_Line_2__c);
        addressAttributes.put('city', caseRecord.City__c);
        addressAttributes.put('state', caseRecord.State__c);
        addressAttributes.put('zip', caseRecord.Zip_Code__c);

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('data', new Map<String, Object>{
            'type' => 'address',
            'id' => caseRecord.Address_Ext_Id__c,
            'attributes' => addressAttributes
        });

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'ApiKey ' + Label.True_Link_API_Key);
        req.setBody(JSON.serialize(requestBody));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 204) {
            ceList.add(createException('API_Exception', 'Address update request failed with status Code: ' + res.getStatusCode() + ' \n ' + res.getBody()));
        }
    }

    public static Custom_Exception__c createException(String type, String message) {
        Custom_Exception__c ce = new Custom_Exception__c();
        ce.Exception_Type__c = type;
        ce.Exception_Message__c = message;
        return ce;
    }

    public void finish(Database.BatchableContext BC) {}
}