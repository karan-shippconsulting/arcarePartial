public class TrueLinkConnectionsSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, TrueLink_ID__c
            FROM Trust__c
            WHERE TrueLink_ID__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Trust__c> scope) {
        Trust__c trust = scope[0];

        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.endpoint__c)
            .setEndPoint('/trust_beneficiaries/' + trust.TrueLink_ID__c + '/connections')
            .setMethod('GET')
            .setHeader('Authorization', tldata.ApiKey__c)
            .setHeader('Content-Type', 'application/json');

        Map<String, String> params = new Map<String, String>();
        params.put('page[number]', '1');
        params.put('page[size]', '2500');
        exec.setParams(params);

        String resBody = exec.send().getBody();
        Track_API_Call__c trackObj = exec.getTrackObj();
        trackObj.Parent_Record_Id__c = trust.Id;
        update trackObj;

        if (trackObj.Status__c != 'Success') return;

        try {
            TrueLinkConnectionsResponseWrapper response = TrueLinkConnectionsResponseWrapper.parse(resBody);

            if (response == null || response.data == null || response.data.isEmpty()) return;

            // Map connectionRelationship id → included attributes for the join
            Map<String, TrueLinkConnectionsResponseWrapper.cls_included_attributes> relMap =
                new Map<String, TrueLinkConnectionsResponseWrapper.cls_included_attributes>();
            if (response.included != null) {
                for (TrueLinkConnectionsResponseWrapper.cls_included inc : response.included) {
                    if (inc != null && inc.id != null) {
                        relMap.put(inc.id, inc.attributes);
                    }
                }
            }

            List<Connections__c> connections = new List<Connections__c>();
            for (TrueLinkConnectionsResponseWrapper.cls_data d : response.data) {
                Connections__c con = new Connections__c();
                con.True_Link_Id__c = d.id;
                con.Trust__c = trust.Id;

                if (d.attributes != null) {
                    con.First_Name__c   = d.attributes.firstName;
                    con.Last_Name__c    = d.attributes.lastName;
                    con.Mobile__c       = d.attributes.mobile;
                    con.Email__c        = d.attributes.email;
                    con.Company_Name__c = d.attributes.companyName;
                    con.Notes__c        = d.attributes.notes;
                    con.Is_Common__c    = d.attributes.isCommon != null ? d.attributes.isCommon : false;
                    con.Street_1__c     = d.attributes.street1;
                    con.Street_2__c     = d.attributes.street2;
                    con.City__c         = d.attributes.city;
                    con.State__c        = d.attributes.state;
                    con.Zip__c          = d.attributes.zip;

                    String firstName = d.attributes.firstName != null ? d.attributes.firstName : '';
                    String lastName  = d.attributes.lastName  != null ? d.attributes.lastName  : '';
                    String fullName  = (firstName + ' ' + lastName).trim();
                    con.Name = String.isNotBlank(fullName)
                        ? (fullName.length() > 80 ? fullName.substring(0, 80) : fullName)
                        : d.id;
                }

                if (d.relationships != null) {
                    if (d.relationships.organization?.data != null) {
                        con.Organization_Id__c = d.relationships.organization.data.id;
                    }
                    if (d.relationships.connectionRelationship?.data != null) {
                        String relId = d.relationships.connectionRelationship.data.id;
                        con.Connection_Relationship_Id__c = relId;

                        TrueLinkConnectionsResponseWrapper.cls_included_attributes relAttrs = relMap.get(relId);
                        if (relAttrs != null) {
                            if (relAttrs.relationshipTypes != null && !relAttrs.relationshipTypes.isEmpty()) {
                                con.Relationship_Types__c = String.join(relAttrs.relationshipTypes, ';');
                            }
                            con.Is_Statement_Recipient__c = relAttrs.isStatementRecipient != null
                                ? relAttrs.isStatementRecipient : false;
                        }
                    }
                }

                connections.add(con);
            }

            if (!connections.isEmpty()) {
                upsert connections True_Link_Id__c;
            }

        } catch (Exception e) {
            exec.logData('Error parsing connections response: ' + e.getMessage() + ' => ' + e.getStackTraceString());
        }
    }

    public void finish(Database.BatchableContext bc) {}
}