# True Link Integration Changes — Replication Guide

This document captures every metadata/Apex change made in this session so it can be reproduced in another Arcare-family org. It covers three independent features:

1. **Connections → True Link update batch** — pushes edited `Connections__c` records back to True Link via PATCH.
2. **`taxDocRecipientConnectionId` capture** — captures a previously-dropped attribute on the Get Balance routine.
3. **Metadata-driven trust status eligibility + status capture on create beneficiary** — moves the hardcoded `{'Closing','Active'}` eligibility check to Custom Metadata (adding the missing `Future Funded` value) and captures the `status` attribute returned by the create-beneficiary call.

All changes were built and verified against the `arcarePartial` sandbox (205 org-wide local tests passing after the final change).

---

## 0. Prerequisites — verify these already exist in the target org

These are **not** part of this session's changes — they're existing platform/objects this work depends on. If the target org doesn't have the same `force-app` source tree already deployed, verify these exist before applying anything below:

- **Objects/fields**: `Connections__c` (with `First_Name__c`, `Last_Name__c`, `Mobile__c`, `Email__c`, `Company_Name__c`, `Notes__c`, `Street_1__c`, `Street_2__c`, `City__c`, `State__c`, `Zip__c`, `Relationship_Types__c`, `Is_Statement_Recipient__c`, `True_Link_Id__c`, `Trust__c` lookup, `Update_True_Link__c`); `Trust__c.TrueLink_ID__c` (the True Link trust-beneficiary id); `Trust__c.Trust_Status__c` picklist already including `Active`, `Future Funded`, `Closing` as values.
- **Custom settings**: `TruelinkData__c` (Hierarchy — `Endpoint__c`, `ApiKey__c`), `Truelink_Feature_Management__c`, `True_Link_Trigger_Switch__c`.
- **Supporting classes** (untouched, reused as-is): `TruelinkRestUtil.cls`, `TrackApiUtil.cls`, `TruelinkStaticUtils.cls`, `TruelinkTransactionResponseWrapper.cls`, `TruelinkBeneficiaryRequestBuilder.cls`.
- **`Track_API_Call__c`** object (used for logging every callout).

If any of the two fields below don't already exist on `Trust__c` in the target org, create them first (full metadata included in Feature 2 and Feature 3 sections).

---

## Feature 1: Connections → True Link update batch

**What it does**: `UpdateConnectionsBatch` queries `Connections__c` where `Update_True_Link__c = true`, and for each, PATCHes `/trust_beneficiaries/{Trust.TrueLink_ID__c}/connections/{Connection.True_Link_Id__c}` with the connection's attributes + `connectionRelationship` block, then resets `Update_True_Link__c` to `false` on success. Errors are logged to `Track_API_Call__c` without resetting the flag. Invocation is manual: `Database.executeBatch(new UpdateConnectionsBatch(), 1)`.

### New file: `force-app/main/default/classes/TrueLinkConnectionUpdateRequestWrapper.cls`
```apex
public class TrueLinkConnectionUpdateRequestWrapper {
    public cls_data data;

    public TrueLinkConnectionUpdateRequestWrapper(){
        data = new cls_data();
    }

    public class cls_data {
        public String type;
        public String id;
        public cls_attributes attributes;
        public cls_relationships relationships;

        cls_data(){
            type = 'connection';
            attributes = new cls_attributes();
            relationships = new cls_relationships();
        }
    }

    public class cls_attributes {
        public String firstName;
        public String lastName;
        public String mobile;
        public String email;
        public String companyName;
        public String notes;
        public String street1;
        public String street2;
        public String city;
        public String state;
        public String zip;
    }

    public class cls_relationships {
        public cls_connectionRelationship connectionRelationship;

        cls_relationships(){
            connectionRelationship = new cls_connectionRelationship();
        }
    }

    public class cls_connectionRelationship {
        public cls_connectionRelationshipData data;

        cls_connectionRelationship(){
            data = new cls_connectionRelationshipData();
        }
    }

    public class cls_connectionRelationshipData {
        public String type;
        public cls_connectionRelationshipAttributes attributes;

        cls_connectionRelationshipData(){
            type = 'connectionRelationship';
            attributes = new cls_connectionRelationshipAttributes();
        }
    }

    public class cls_connectionRelationshipAttributes {
        public List<String> relationshipTypes;
        public Boolean isStatementRecipient;
    }
}
```
`.cls-meta.xml` (same content used for every new class in this guide — see [Meta.xml template](#metaxml-template)).

### New file: `force-app/main/default/classes/UpdateConnectionsBatch.cls`
```apex
public class UpdateConnectionsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([Select Id from Connections__c where Update_True_Link__c = true]);
    }

    public void execute(Database.BatchableContext ctx, List<Connections__c> records){
        for(Connections__c con : records){
            try{
                TrueLinkApiHandler.updateConnection(con.Id);
            } catch(Exception e){
                insert new Track_API_Call__c(
                    Parent_Record_Id__c = con.Id,
                    Status__c = 'Error',
                    Error_Message__c = 'Error While Updating Connection. => ' + e.getMessage() + '=>' + e.getStackTraceString()
                );
            }
        }
    }

    public void finish(Database.BatchableContext ctx){
    }
}
```

### New method in `force-app/main/default/classes/TrueLinkApiHandler.cls`
Add this method (placed after `updateTrustBeneficiaryAddress`, before `updateTrustBeneficiary`):
```apex
    public static void updateConnection(String connectionId){
        Connections__c con = [Select Id, True_Link_Id__c, First_Name__c, Last_Name__c, Mobile__c, Email__c,
                               Company_Name__c, Notes__c, Street_1__c, Street_2__c, City__c, State__c, Zip__c,
                               Relationship_Types__c, Is_Statement_Recipient__c,
                               Trust__c, Trust__r.TrueLink_ID__c
                               from Connections__c where Id =: connectionId limit 1];
        if(String.isBlank(con.True_Link_Id__c) || con.Trust__c == null || String.isBlank(con.Trust__r.TrueLink_ID__c)){
            throw new ApiException('Missing True_Link_Id__c or Trust TrueLink_ID__c for Connection: ' + connectionId);
        }
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c);
        try{
            TrueLinkConnectionUpdateRequestWrapper reqWrapper = new TrueLinkConnectionUpdateRequestWrapper();
            reqWrapper.data.id = con.True_Link_Id__c;
            reqWrapper.data.attributes.firstName = con.First_Name__c;
            reqWrapper.data.attributes.lastName = con.Last_Name__c;
            reqWrapper.data.attributes.mobile = con.Mobile__c;
            reqWrapper.data.attributes.email = con.Email__c;
            reqWrapper.data.attributes.companyName = con.Company_Name__c;
            reqWrapper.data.attributes.notes = con.Notes__c;
            reqWrapper.data.attributes.street1 = con.Street_1__c;
            reqWrapper.data.attributes.street2 = con.Street_2__c;
            reqWrapper.data.attributes.city = con.City__c;
            reqWrapper.data.attributes.state = con.State__c;
            reqWrapper.data.attributes.zip = con.Zip__c;

            if(String.isNotBlank(con.Relationship_Types__c)){
                reqWrapper.data.relationships.connectionRelationship.data.attributes.relationshipTypes = con.Relationship_Types__c.split(';');
            }
            reqWrapper.data.relationships.connectionRelationship.data.attributes.isStatementRecipient = con.Is_Statement_Recipient__c;

            exec.setEndPoint('/trust_beneficiaries/' + con.Trust__r.TrueLink_ID__c + '/connections/' + con.True_Link_Id__c)
                .setMethod('PATCH')
                .setBody(JSON.serialize(reqWrapper, true))
                .setHeader('Authorization', tldata.ApiKey__c)
                .setHeader('Content-Type','application/json');
            exec.send();
            Track_API_Call__c trackObj = exec.getTrackObj();
            trackObj.Parent_Record_Id__c = con.Id;
            update trackObj;
            if(trackObj.Status__c == 'Success'){
                Connections__c toUpdate = new Connections__c(Id=con.Id, Update_True_Link__c=false);
                update toUpdate;
            }
        }
        catch(Exception e){
            exec.logData('Error While Constructing Request. => '+ e.getMessage() + '=>' + e.getStackTraceString());
        }
    }
```

### Tests
- `force-app/main/default/classes/UpdateConnectionsBatchTest.cls` — `@TestSetup` inserts `TruelinkData__c`, `Pooled_Trust__c`, `Trust_Portfolio__c`, a `Contact`, a `Trust__c` (`TrueLink_ID__c='trustbenef-123'`), and a `Connections__c` (`True_Link_Id__c='connection-123'`, `Update_True_Link__c=true`, all 11 attribute fields + `Relationship_Types__c='Sibling;Guardian'` + `Is_Statement_Recipient__c=true`). Two tests: success path (mock returns 200, asserts flag reset + `Track_API_Call__c` success row) and error path (deletes the Trust first to force an exception, asserts error logged and flag stays `true`).
- `force-app/main/default/classes/TrueLinkConnectionUpdateReqWrapperTest.cls` — direct unit tests on the wrapper: constructor initializes the full nested structure (`type='connection'`, `type='connectionRelationship'`, etc.), and a serialize/deserialize round-trip test. **100% class coverage.**
  > Naming note: the natural name `TrueLinkConnectionUpdateRequestWrapperTest` is 42 characters — over Apex's 40-character identifier limit — hence the shortened `ReqWrapperTest`.

Full content of both test files is in this repo already (`force-app/main/default/classes/UpdateConnectionsBatchTest.cls`, `.../TrueLinkConnectionUpdateReqWrapperTest.cls`) — copy them as-is.

---

## Feature 2: Capture `taxDocRecipientConnectionId` on Get Balance

**What it does**: True Link's trust-beneficiary payload (used by `TrueLinkApiHandler.updateAccountBalance` / `fetchAccountBalance`) includes `data.attributes.taxDocRecipientConnectionId`, which was silently dropped during deserialization. Now captured onto `Trust__c.taxDocRecipientConnectionId__c`.

### Field (create if missing): `force-app/main/default/objects/Trust__c/fields/taxDocRecipientConnectionId__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>taxDocRecipientConnectionId__c</fullName>
    <externalId>false</externalId>
    <label>taxDocRecipientConnectionId</label>
    <length>50</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

### Change 1: `force-app/main/default/classes/TruelinkBeneficiaryRequestWrapper.cls`
Add to the `Attributes` inner class (alongside `beneficiaryId`/`trustBeneficiaryInternalId`):
```apex
        public String beneficiaryId;
        public String trustBeneficiaryInternalId;
        public String taxDocRecipientConnectionId;   // <-- added
```

### Change 2: `force-app/main/default/classes/TrueLinkApiHandler.cls`, inside `updateAccountBalance`
Right after the `disallowDisbursementRequests` block:
```apex
            if(response?.data?.attributes?.disallowDisbursementRequests!=null){
                trust.Disbursement_Creation_Enabled__c = !response.data.attributes.disallowDisbursementRequests;
            }
            trust.taxDocRecipientConnectionId__c = response?.data?.attributes?.taxDocRecipientConnectionId;   // <-- added
```

### Tests
`TrueLinkApiHandlerTest.cls` — the `TruelinkRestUtilMock2` mock's JSON body gained `"taxDocRecipientConnectionId": "conn-tax-123"`. New test `testFetchAccountBalanceCapturesTaxDocRecipientConnectionId` calls `fetchAccountBalance` directly (not chained after `updateAccountBalance` — chaining two callout-triggering calls in one test throws `System.CalloutException: uncommitted work pending`, since the first call's internal `Track_API_Call__c` DML leaves work uncommitted before a second callout) and asserts the parsed value.

Also `TruelinkBeneficiaryRequestWrapperTest.cls` got two new tests unrelated to this specific field but done in the same pass to close a coverage gap on the wrapper class (66% → 100%): `testJsonDeserializationPopulatesMetaAccountsAndIncluded` (deserializes a realistic payload covering `Meta.totalAccountBalance`, `AvailableCashSum`, `Relationships.accounts`, `cls_balance`) and `testAvailableCashSumToMap` (directly exercises the previously-uncalled `AvailableCashSum.toMap()`). These are optional to replicate but harmless/recommended.

---

## Feature 3: Metadata-driven trust status eligibility + status on create beneficiary

**What it does**: Replaces 6 hardcoded copies of `{'Closing','Active'}` (3 Apex guards in `updateAccountBalance`/`updateDeposit`/`updateDisbursement`, 3 batch `start()` SOQL filters) with a shared Custom Metadata Type list — fixing the fact that `Future Funded` (a valid `Trust_Status__c` picklist value) was never included. The exception message is now built dynamically from the metadata. Separately, `createTrustBeneficiary` now captures the `status` attribute True Link returns onto `Trust__c.True_Link_Status__c` (previously dropped, same class of gap as Feature 2 but on a different response wrapper).

### New Custom Metadata Type: `Truelink_Trust_Status__mdt`

`force-app/main/default/objects/Truelink_Trust_Status__mdt/Truelink_Trust_Status__mdt.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Truelink Trust Status</label>
    <pluralLabel>Truelink Trust Statuses</pluralLabel>
    <visibility>Public</visibility>
</CustomObject>
```

`force-app/main/default/objects/Truelink_Trust_Status__mdt/fields/Status_Value__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status_Value__c</fullName>
    <fieldManageability>DeveloperControlled</fieldManageability>
    <label>Status Value</label>
    <length>50</length>
    <required>true</required>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

Three records (`force-app/main/default/customMetadata/`):

`Truelink_Trust_Status.Active.md-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Active</label>
    <protected>false</protected>
    <values>
        <field>Status_Value__c</field>
        <value xsi:type="xsd:string">Active</value>
    </values>
</CustomMetadata>
```

`Truelink_Trust_Status.Future_Funded.md-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Future Funded</label>
    <protected>false</protected>
    <values>
        <field>Status_Value__c</field>
        <value xsi:type="xsd:string">Future Funded</value>
    </values>
</CustomMetadata>
```

`Truelink_Trust_Status.Closing.md-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Closing</label>
    <protected>false</protected>
    <values>
        <field>Status_Value__c</field>
        <value xsi:type="xsd:string">Closing</value>
    </values>
</CustomMetadata>
```

### Field (create if missing): `force-app/main/default/objects/Trust__c/fields/True_Link_Status__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>True_Link_Status__c</fullName>
    <externalId>false</externalId>
    <label>True Link Status</label>
    <length>50</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Text</type>
    <unique>false</unique>
</CustomField>
```

### `TrueLinkApiHandler.cls` changes

New shared helper (placed just before the existing private `getTrustId` method):
```apex
    public static Set<String> getEligibleTrustStatuses(){
        Set<String> statuses = new Set<String>();
        for(Truelink_Trust_Status__mdt s : Truelink_Trust_Status__mdt.getAll().values()){
            statuses.add(s.Status_Value__c);
        }
        return statuses;
    }
```

Replace all **3** occurrences of the hardcoded guard (in `updateAccountBalance`, `updateDeposit`, `updateDisbursement`) — same shape each time:
```apex
// before
Set<String> allowedTrustStatus = new Set<String>{'Closing','Active'};
if(!allowedTrustStatus.contains(trust.Trust_Status__c)){
    throw new ApiException('Trust Status should be Active or Closing');
}

// after
Set<String> allowedTrustStatus = getEligibleTrustStatuses();
if(!allowedTrustStatus.contains(trust.Trust_Status__c)){
    throw new ApiException('Trust Status should be one of: ' + String.join(new List<String>(allowedTrustStatus), ', '));
}
```

In `createTrustBeneficiary`'s success block, add one line alongside the existing field captures:
```apex
                        Trust__c toUpdate = new Trust__c(Id=trustPartyId,TrueLink_ID__c=beneficiaryId);
                        toUpdate.Truelink_Address_Id__c = addressId;
                        toUpdate.True_Link_ID_from_TL_Profile__c = trustBeneficiaryInternalId;
                        toUpdate.True_Link_Status__c = response?.data?.attributes?.status;   // <-- added
                        update toUpdate;
```

### `TrueLinkResponseWrapper.cls` change
Add to `Attributes` (alongside `trustBeneficiaryInternalId`):
```apex
		public String trustBeneficiaryInternalId;
		public String maritalStatus;
		public String livingSituation;
		public String status;   // <-- added
```

### Batch `start()` methods — switch to dynamic SOQL

All 3 batches change identically: build `List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());` and bind it in a dynamic SOQL string (same mechanism `UpdateDisbursementsBatch` already used for `:trustIds`).

**`UpdateDepositsBatch.cls`**
```apex
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses');
    }
```

**`UpdateDisbursementsBatch.cls`**
```apex
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        if(trustIds != null && !trustIds.isEmpty()){
            return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses AND Id IN :trustIds');
        }
        return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses');
    }
```

**`UpdateBeneficiaryBalanceBatch.cls`**
```apex
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> eligibleStatuses = new List<String>(TrueLinkApiHandler.getEligibleTrustStatuses());
        return Database.getQueryLocator('SELECT Id, TrueLink_ID__c, True_Link_Balance__c FROM trust__c WHERE TrueLink_ID__c != null AND Trust_Status__c IN :eligibleStatuses');
    }
```

### Tests

**`TrueLinkApiHandlerTest.cls`** — 3 new tests:
- `testGetEligibleTrustStatuses` — asserts the metadata returns exactly `{'Active','Future Funded','Closing'}`.
- `testUpdateAccountBalanceThrowsForIneligibleStatusWithDynamicMessage` — inserts a trust with `Trust_Status__c='Intake'`, asserts `ApiException` is thrown and its message contains all 3 eligible values.
- `testCreateTrustBeneficiaryCapturesStatus` — new mock `TrueLinkCreateBeneficiaryMock` returning `"status": "Active"`; calls `createTrustBeneficiary` directly, re-queries the trust, asserts `True_Link_Status__c == 'Active'`.

**`UpdateTruelinkBatchesTest.cls`** — new test `testUpdateDepositsBatchExcludesIneligibleStatus`: inserts an extra `Trust__c` with `Trust_Status__c='Intake'` and a `TrueLink_ID__c` set, runs the batch, asserts no `Transaction__c` was created for it while the pre-existing eligible trust still gets processed.
> ⚠️ Must set `TruelinkStaticUtils.stopRecursionOnTrustUpdate = true;` before running the batch in this test (same as every other passing batch test in this file) — otherwise the `Transaction__c` upsert can cascade into a `Trust__c` update that fires `TrustTrigger`'s `AfterUpdate`, which tries to call an `@future` method from within batch context and throws `System.AsyncException: Future method cannot be called from a future or batch method`. This is a pre-existing platform constraint of this codebase, not something introduced by this change — just easy to trip over if you copy this test without the flag.

**`UpdateBeneficiaryBalanceBatchTest.cls`** — new test `testStartExcludesIneligibleTrustStatus`: inserts an eligible + an ineligible (`'Intake'`) trust, calls `cb.start(null)` directly, iterates the `Database.QueryLocatorIterator`, asserts the eligible trust's Id is present and the ineligible one's is not.

### Known related debt (not touched, flagged for awareness)
`force-app/main/default/triggers/TrustTrigger.trigger` has its own **separate** hardcoded status set — `Set<String> allowedTrustStatus = new Set<String>{'Pending-Active','Active','Closing'};` (line 8) — used to decide when to auto-fire `createTrustBeneficiary` on a Trust status change. This is outside the balance/deposit/disbursement scope of this change and was intentionally left alone, but is the same pattern and a candidate to fold into `Truelink_Trust_Status__mdt` later if wanted.

---

## Meta.xml template

Every new Apex class in this guide uses the same `.cls-meta.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

## Full file list

New files:
```
force-app/main/default/classes/TrueLinkConnectionUpdateRequestWrapper.cls(-meta.xml)
force-app/main/default/classes/UpdateConnectionsBatch.cls(-meta.xml)
force-app/main/default/classes/UpdateConnectionsBatchTest.cls(-meta.xml)
force-app/main/default/classes/TrueLinkConnectionUpdateReqWrapperTest.cls(-meta.xml)
force-app/main/default/objects/Truelink_Trust_Status__mdt/Truelink_Trust_Status__mdt.object-meta.xml
force-app/main/default/objects/Truelink_Trust_Status__mdt/fields/Status_Value__c.field-meta.xml
force-app/main/default/customMetadata/Truelink_Trust_Status.Active.md-meta.xml
force-app/main/default/customMetadata/Truelink_Trust_Status.Future_Funded.md-meta.xml
force-app/main/default/customMetadata/Truelink_Trust_Status.Closing.md-meta.xml
```

Modified files:
```
force-app/main/default/classes/TrueLinkApiHandler.cls
force-app/main/default/classes/TrueLinkApiHandlerTest.cls
force-app/main/default/classes/TrueLinkResponseWrapper.cls
force-app/main/default/classes/TruelinkBeneficiaryRequestWrapper.cls
force-app/main/default/classes/TruelinkBeneficiaryRequestWrapperTest.cls
force-app/main/default/classes/UpdateBeneficiaryBalanceBatch.cls
force-app/main/default/classes/UpdateBeneficiaryBalanceBatchTest.cls
force-app/main/default/classes/UpdateDepositsBatch.cls
force-app/main/default/classes/UpdateDisbursementsBatch.cls
force-app/main/default/classes/UpdateTruelinkBatchesTest.cls
force-app/main/default/objects/Trust__c/fields/taxDocRecipientConnectionId__c.field-meta.xml   (create if missing)
force-app/main/default/objects/Trust__c/fields/True_Link_Status__c.field-meta.xml              (create if missing)
```

## Deployment command (against a target org alias)

```bash
sf project deploy start --target-org <TARGET_ORG_ALIAS> \
  --source-dir force-app/main/default/objects/Truelink_Trust_Status__mdt \
  --source-dir force-app/main/default/customMetadata/Truelink_Trust_Status.Active.md-meta.xml \
  --source-dir force-app/main/default/customMetadata/Truelink_Trust_Status.Future_Funded.md-meta.xml \
  --source-dir force-app/main/default/customMetadata/Truelink_Trust_Status.Closing.md-meta.xml \
  --source-dir force-app/main/default/classes/TrueLinkApiHandler.cls \
  --source-dir force-app/main/default/classes/TrueLinkResponseWrapper.cls \
  --source-dir force-app/main/default/classes/TruelinkBeneficiaryRequestWrapper.cls \
  --source-dir force-app/main/default/classes/UpdateDepositsBatch.cls \
  --source-dir force-app/main/default/classes/UpdateDisbursementsBatch.cls \
  --source-dir force-app/main/default/classes/UpdateBeneficiaryBalanceBatch.cls \
  --source-dir force-app/main/default/classes/TrueLinkConnectionUpdateRequestWrapper.cls \
  --source-dir force-app/main/default/classes/UpdateConnectionsBatch.cls \
  --source-dir force-app/main/default/classes/TrueLinkApiHandlerTest.cls \
  --source-dir force-app/main/default/classes/TruelinkBeneficiaryRequestWrapperTest.cls \
  --source-dir force-app/main/default/classes/UpdateTruelinkBatchesTest.cls \
  --source-dir force-app/main/default/classes/UpdateBeneficiaryBalanceBatchTest.cls \
  --source-dir force-app/main/default/classes/UpdateConnectionsBatchTest.cls \
  --source-dir force-app/main/default/classes/TrueLinkConnectionUpdateReqWrapperTest.cls \
  --test-level RunLocalTests --wait 33
```

(If the target org already has the whole `force-app` tree, a plain `sf project deploy start --source-dir force-app` after copying these files in is simplest.)

## Post-deploy verification
1. Confirm `Trust_Status__c` picklist on `Trust__c` already includes `Active`, `Future Funded`, `Closing` — if not, add them (restricted picklist).
2. Run: `sf apex run test --target-org <TARGET_ORG_ALIAS> --tests TrueLinkApiHandlerTest --tests UpdateTruelinkBatchesTest --tests UpdateBeneficiaryBalanceBatchTest --tests UpdateConnectionsBatchTest --tests TrueLinkConnectionUpdateReqWrapperTest --tests TruelinkBeneficiaryRequestWrapperTest --code-coverage --result-format human`
3. Manually verify `Truelink_Trust_Status__mdt` has exactly 3 active records via Setup → Custom Metadata Types.
4. Smoke-test one Connection with `Update_True_Link__c=true` against the target org's real/QA True Link endpoint: `Database.executeBatch(new UpdateConnectionsBatch(), 1);` from Execute Anonymous, then confirm the flag reset and check `Track_API_Call__c` for the PATCH result.
