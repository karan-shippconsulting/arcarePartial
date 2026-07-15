public class UpdateAttachmentURLOnDisbursements implements Queueable, Database.AllowsCallouts {
    @TestVisible private static Integer BATCH_SIZE = 10;
    private String trustId;

    public UpdateAttachmentURLOnDisbursements(String trustId) {
        this.trustId = trustId;
    }

    public void execute(QueueableContext context) {
        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();

        Integer fetchLimit = BATCH_SIZE * 10;
        List<Transaction__c> candidates = [
            SELECT Id, Attachment_Id__c, Attachment_URL__c
            FROM Transaction__c
            WHERE Trust__c = :trustId
            AND Attachment_Id__c != null
            LIMIT :fetchLimit
        ];

        List<Transaction__c> toProcess = new List<Transaction__c>();
        for (Transaction__c t : candidates) {
            if (String.isBlank(t.Attachment_URL__c)) {
                toProcess.add(t);
                if (toProcess.size() >= BATCH_SIZE) break;
            }
        }

        if (toProcess.isEmpty()) return;

        List<Transaction__c> toUpdate = new List<Transaction__c>();
        List<Track_API_Call__c> trackApiCallList = new List<Track_API_Call__c>();

        for (Transaction__c tranx : toProcess) {
            Track_API_Call__c track = new Track_API_Call__c();
            try {
                Http http = new Http();
                HttpRequest req = new HttpRequest();
                req.setEndPoint(tldata.endpoint__c.removeEnd('/') + '/attachments/' + tranx.Attachment_Id__c);
                req.setMethod('GET');
                req.setHeader('Authorization', tldata.ApiKey__c);
                req.setHeader('Content-Type', 'application/json');
                req.setHeader('Accept', 'application/json');
                HttpResponse res = http.send(req);
                String contentType = res.getHeader('Content-Type');
                if (contentType == null || !contentType.containsIgnoreCase('application/json')) {
                    throw new CalloutException('Non-JSON response (Content-Type: ' + contentType + '). Check endpoint URL.');
                }
                String responseBody = res.getBody();
                Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> data = (Map<String, Object>) resMap.get('data');
                Map<String, Object> attributes = (Map<String, Object>) data.get('attributes');
                String url = (String) attributes.get('url');

                track.Http_Method__c = req.getMethod();
                track.Request_URL__c = req.getEndpoint();
                Integer responseBdyLength = Math.min(responseBody.length(), 13107);
                track.Response__c = responseBody.substring(0, responseBdyLength);
                track.StatusCode__c = res.getStatusCode();
                track.Status__c = (track.StatusCode__c >= 200 && track.StatusCode__c <= 300) ? 'Success' : 'Error';

                if (url != null && url.length() > 32768) {
                    throw new CalloutException('Attachment URL exceeds 32768 chars (' + url.length() + '). Field length may need to be increased.');
                }
                toUpdate.add(new Transaction__c(Id = tranx.Id, Attachment_URL__c = url));
            } catch (Exception ex) {
                track.Error_Message__c = 'Error While Parsing Response. => ' + ex.getMessage() + '=>' + ex.getStackTraceString();
                track.Status__c = 'Error';
            }
            track.Parent_Record_Id__c = tranx.Attachment_Id__c;
            trackApiCallList.add(track);
        }

        update toUpdate;
        insert trackApiCallList;

        Boolean moreToProcess = toProcess.size() == BATCH_SIZE || candidates.size() == fetchLimit;
        if (moreToProcess && !Test.isRunningTest()) {
            System.enqueueJob(new UpdateAttachmentURLOnDisbursements(trustId));
        }
    }
}