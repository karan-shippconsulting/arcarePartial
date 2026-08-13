@isTest
public class TruelinkBeneficiaryRequestWrapperTest {
     
    @isTest
    static void testDefaultConstructor() {
       
        TruelinkBeneficiaryRequestWrapper wrapper = new TruelinkBeneficiaryRequestWrapper();
        
        System.assertNotEquals(null, wrapper.data);
        System.assertEquals('trust_beneficiary', wrapper.data.type);
        
        System.assertNotEquals(null, wrapper.data.attributes);
        
        
        System.assertNotEquals(null, wrapper.data.relationships);
        System.assertNotEquals(null, wrapper.data.relationships.address);
        System.assertNotEquals(null, wrapper.data.relationships.activePortfolio);
        
        
        System.assertNotEquals(null, wrapper.data.meta);
        
     
        System.assertNotEquals(null, wrapper.data.relationships.address.data);
        System.assertEquals('address', wrapper.data.relationships.address.data.type);
        System.assertNotEquals(null, wrapper.data.relationships.address.data.attributes);
        
        System.assertNotEquals(null, wrapper.data.relationships.activePortfolio.data);
    }
    
    @isTest
    static void testConstructorWithIsUpdateTrue() {
        TruelinkBeneficiaryRequestWrapper wrapper = new TruelinkBeneficiaryRequestWrapper(true);
        
        System.assertNotEquals(null, wrapper.data);
        System.assertEquals('trust_beneficiary', wrapper.data.type);
        
        System.assertNotEquals(null, wrapper.data.attributes);
        
        System.assertEquals(null, wrapper.data.relationships);
        
        
    }
    
    @isTest
    static void testConstructorWithIsUpdateFalse() {
        TruelinkBeneficiaryRequestWrapper wrapper = new TruelinkBeneficiaryRequestWrapper(false);
        
        System.assertNotEquals(null, wrapper.data);
        System.assertEquals('trust_beneficiary', wrapper.data.type);
        
        System.assertNotEquals(null, wrapper.data.attributes);
        
       
        System.assertNotEquals(null, wrapper.data.relationships);
        System.assertNotEquals(null, wrapper.data.relationships.address);
        System.assertNotEquals(null, wrapper.data.relationships.activePortfolio);
        
        
        System.assertNotEquals(null, wrapper.data.relationships.address.data);
        System.assertEquals('address', wrapper.data.relationships.address.data.type);
        System.assertNotEquals(null, wrapper.data.relationships.address.data.attributes);
        
        System.assertNotEquals(null, wrapper.data.relationships.activePortfolio.data);
    }

    @isTest
    static void testJsonDeserializationPopulatesMetaAccountsAndIncluded() {
        String jsonPayload = '{' +
            '"data": {' +
                '"type": "trust_beneficiary",' +
                '"id": "test-id",' +
                '"meta": {' +
                    '"totalAccountBalance": 500.25,' +
                    '"availableCashSum": {' +
                        '"amount": 100.5,' +
                        '"cash_currency": "USD"' +
                    '}' +
                '},' +
                '"relationships": {' +
                    '"accounts": {' +
                        '"data": [' +
                            '{"type": "account", "id": "acct-1"}' +
                        ']' +
                    '}' +
                '}' +
            '},' +
            '"included": [' +
                '{' +
                    '"id": "card-1",' +
                    '"type": "bank_account",' +
                    '"attributes": {' +
                        '"lastFour": "1234",' +
                        '"cardReference": "ref-1",' +
                        '"program": "prog",' +
                        '"status": "Active",' +
                        '"expiryDate": "2030-01-01",' +
                        '"isBreached": false,' +
                        '"breach": null,' +
                        '"fraudBlockType": null,' +
                        '"balance": {' +
                            '"amount": 25.5,' +
                            '"timestamp": "2026-01-01T00:00:00Z"' +
                        '}' +
                    '}' +
                '}' +
            ']' +
        '}';

        TruelinkBeneficiaryRequestWrapper wrapper =
            (TruelinkBeneficiaryRequestWrapper) JSON.deserialize(jsonPayload, TruelinkBeneficiaryRequestWrapper.class);

        System.assertEquals(500.25, wrapper.data.meta.totalAccountBalance);
        System.assertEquals(100.5, wrapper.data.meta.availableCashSum.amount);
        System.assertEquals('USD', wrapper.data.meta.availableCashSum.cash_currency);

        System.assertEquals(1, wrapper.data.relationships.accounts.data.size());
        System.assertEquals('acct-1', wrapper.data.relationships.accounts.data[0].id);
        System.assertEquals('account', wrapper.data.relationships.accounts.data[0].type);

        System.assertEquals(1, wrapper.included.size());
        System.assertEquals(25.5, wrapper.included[0].attributes.balance.amount);
        System.assertEquals('2026-01-01T00:00:00Z', wrapper.included[0].attributes.balance.timestamp);
    }

    @isTest
    static void testAvailableCashSumToMap() {
        TruelinkBeneficiaryRequestWrapper.AvailableCashSum cashSum = new TruelinkBeneficiaryRequestWrapper.AvailableCashSum();
        cashSum.amount = 42.5;
        cashSum.cash_currency = 'USD';

        Map<String, Object> result = cashSum.toMap();

        System.assertEquals(42.5, result.get('amount'));
        System.assertEquals('USD', result.get('currency'));
    }
}