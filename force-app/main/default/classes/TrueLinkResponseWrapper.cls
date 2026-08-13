public class TrueLinkResponseWrapper {

	public class Relationships {
		public Accounts accounts;
		public Address address;
		public DisabilityDesignations disabilityDesignation;
		public Accounts governmentBenefitsTrustBeneficiary;
		public Address organization;
		public Address trust;
		public Address activePortfolio;
	}
    
    Public class DisabilityDesignations{
        public Data_Z data;
    }

	public class Data_Y {
		public String type;
		public String id;
		public Attributes attributes;
		public Relationships relationships;
	}

	public class Data_Z {
		public String type;
		public String id;
	}

	public Data_Y data;

	public class Address {
		public Data_Z data;
	}

	public class Attributes {
		public String prefix;
		public String firstName;
		public String middleName;
		public String lastName;
		public String suffix;
		public String mobile;
		public String email;
		public String externalId;
		public String ein;
		public String taxIdNumberType;
		public Integer age;
		public String dob;
		public String gender;
		public String trustBeneficiaryInternalId;
		public String maritalStatus;
		public String livingSituation;
		public String status;
        Boolean chargeSetupFee;
        public Boolean disallowDisbursementRequests;
	}

	public class Data {
	}

	public class Accounts {
		public List<Data> data;
	}

	
	public static TrueLinkResponseWrapper parse(String json) {
		return (TrueLinkResponseWrapper) System.JSON.deserialize(json, TrueLinkResponseWrapper.class);
	}
}