public class TrueLinkTransactionController {
    public enum TxFilter { THIS_MONTH, LAST_MONTH, LAST_3_MONTHS, LAST_12_MONTHS }

    @AuraEnabled(cacheable=true)
    public static Beneficiary_Card__c getBeneficiaryCard(Id beneficiaryCardId) {
        return [
            SELECT Id, Name, Balance__c, Status__c,
                   Beneficiary__r.Name,
                   Trust__c, Trust__r.TrueLink_Account_Id__c
            FROM Beneficiary_Card__c
            WHERE Id = :beneficiaryCardId
            LIMIT 1
        ];
    }

    public class TransactionsSummary {
        @AuraEnabled public List<Map<String, Object>> transactions;
        @AuraEnabled public Decimal currentPending;
        @AuraEnabled public Decimal effectiveBalance;
    }

    @AuraEnabled
    public static TransactionsSummary getTransactions(Id beneficiaryCardId, String filterKey) {
        Beneficiary_Card__c bc = getBeneficiaryCard(beneficiaryCardId);
        String acctId = (bc.Trust__r != null ? bc.Trust__r.TrueLink_Account_Id__c : null);

        if (String.isBlank(acctId)) {
            throw new AuraHandledException('TrueLink Account Id is missing on the related Trust record.');
        }

        TruelinkData__c tldata = TruelinkData__c.getOrgDefaults();
        System.debug('tldata -- ' + tldata);
        Truelink_Feature_Management__c feature = Truelink_Feature_Management__c.getOrgDefaults();
        TruelinkRestUtil exec = new TruelinkRestUtil(tldata.Endpoint__c)
            .setEndPoint('/accounts/'+acctId+'/transactions/')
            .setMethod('GET')
            .setHeader('Authorization', tldata.ApiKey__c)
            .setHeader('Content-Type','application/json');

        String resBody = exec.send().getBody();
        Track_API_Call__c trackObj = exec.getTrackObj();
        trackObj.Parent_Record_Id__c = beneficiaryCardId;
        update trackObj;

        TruelinkTransactionResponseWrapper response;

        if(trackObj.Status__c == 'Success'){
            try {
                response = (TruelinkTransactionResponseWrapper)JSON.deserialize(resBody,TruelinkTransactionResponseWrapper.class);
            }
            catch(Exception e){
                exec.logData('Error While Parsing Response. => '+ e.getMessage() + '=>' + e.getStackTraceString());
                return null;
            }
        }

        System.debug('response.data size -- ' + response.data.size());

        List<Map<String, Object>> txs = new List<Map<String, Object>>();
        if(response!=null && response.data!=null){
            for(TruelinkTransactionResponseWrapper.cls_data dta : response.data){
                Map<String, Object> t = new Map<String, Object>();
                t.put('id', dta.id);
                t.put('merchantName', dta.attributes.merchantName);
                t.put('location', dta.attributes.location);
                t.put('status',  dta.attributes.status);
                t.put('settled', dta.attributes.settled);
                t.put('amount', dta.attributes.amount.amount);
                t.put('currency', dta.attributes.amount.field_currency);
                t.put('timestamp', dta.attributes.timestamp);
                t.put('dateDisplay', dta.attributes.timestamp != null ? dta.attributes.timestamp.formatGMT('MMM dd') : null);
                txs.add(t);
            }
        }

        TxFilter filter = parseFilter(filterKey);
        Date today = Date.today();
        Date startDate; 
        Date endDate;   

        Date firstOfThisMonth = Date.newInstance(today.year(), today.month(), 1);

        switch on filter {
            when THIS_MONTH {
                startDate = firstOfThisMonth;
                endDate = firstOfThisMonth.addMonths(1);      
            }
            when LAST_MONTH {
                startDate = firstOfThisMonth.addMonths(-1);     
                endDate = firstOfThisMonth;                    
            }
            when LAST_3_MONTHS {
                startDate = firstOfThisMonth.addMonths(-3);      
                endDate = firstOfThisMonth;                   
            }
            when LAST_12_MONTHS {
                startDate = firstOfThisMonth.addMonths(-12);     
                endDate = firstOfThisMonth;                    
            }
        }

        List<Map<String, Object>> filtered = new List<Map<String, Object>>();
        for (Map<String, Object> t : txs) {
            Datetime ts = (Datetime) t.get('timestamp');
            if (ts == null) continue;

            Date txDate = ts.date();
            if (txDate >= startDate && txDate < endDate) {
                filtered.add(t);
            }
        }

        System.debug('filtered -- ' + filtered.size());

        Decimal pendingSum = 0;
        for (Map<String, Object> t : filtered) {
            String status = (String) t.get('status');
            if (status != null && status.equalsIgnoreCase('Pending')) {
                Decimal amt = (Decimal) t.get('amount');
                pendingSum += (amt != null ? amt : 0);
            }
        }

        TransactionsSummary out = new TransactionsSummary();
        out.transactions     = filtered;
        out.currentPending   = pendingSum;
        out.effectiveBalance = (bc.Balance__c != null ? bc.Balance__c : 0) - pendingSum;
        return out;
    }

    private static TxFilter parseFilter(String key) {
        if (String.isBlank(key)) return TxFilter.THIS_MONTH;
        key = key.trim().toUpperCase();
        if (key == 'LAST_MONTH')      return TxFilter.LAST_MONTH;
        if (key == 'LAST_3_MONTHS')   return TxFilter.LAST_3_MONTHS;
        if (key == 'LAST_12_MONTHS')  return TxFilter.LAST_12_MONTHS;
        return TxFilter.THIS_MONTH;
    }
}