public class TrueLinkPartyTriggerHandler {
    @future (callout=true)
    public static void createTrustBeneficiary(String partyId, String trustPartyId){
        TrueLinkApiHandler.createTrustBeneficiary(partyId, trustPartyId);
    }
    
    @future(callout=true)
    public static void updateTrustBeneficiary(String partyId,String trustPartyId, String beneficaryId){
        TrueLinkApiHandler.updateTrustBeneficiary(partyId,trustPartyId,beneficaryId);
    }
    
    @future(callout=true)
    public static void updateAddress(String partyId,String trustAddressId){ 
        TrueLinkApiHandler.updateTrustBeneficiaryAddress(partyId,trustAddressId);
    }
    
    @future(callout=true)
    public static void createAddress(String partyId,String trueLinkID){ 
		TrueLinkApiHandler.createTrustBeneficiaryAddress(partyId, trueLinkID);
    }
    
    @future(callout=true)
    public static void updateTrust(String trustId, String trustTruelinkId){
        TrueLinkApiHandler.updateTrust(trustId,trustTruelinkId);
    }
    
    @future(callout=true)
    public static void updateTrustForEinAndBid(String trustId, String trustTruelinkId){
        TrueLinkApiHandler.updateTrustForEinAndBid(trustId,trustTruelinkId);
    }
}