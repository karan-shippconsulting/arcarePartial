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
}