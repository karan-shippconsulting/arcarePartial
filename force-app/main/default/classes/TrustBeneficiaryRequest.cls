public class TrustBeneficiaryRequest {

	public class Relationships {
		public Address address;
		public ActivePortfolio activePortfolio;
		public ActivePortfolio disabilityDesignation;
	}

	public class Data_Y {
		public String type;
		public Attributes attributes;
		public Relationships relationships;
	}

	public class Data_Z {
		public String id;
		public String type;
	}

	public Data_Y data;

	public class Address {
		public Data data;
	}

	public class Attributes_Z {
		public String street1;
		public String street2;
		public String city;
		public String state;
		public String zip;
	}

	public class Attributes {
		public String prefix;
		public String firstName;
		public String middleName;
		public String lastName;
		public String suffix;
		public String email;
		public String mobile;
		public String externalId;
		public String ein;
		public String ssn;
		public String taxIdNumberType;
		public String dob;
		public String gender;
		public String maritalStatus;
		public String livingSituation;
        public Boolean mailStatement;
	}

	public class Data {
		public String type;
		public Attributes_Z attributes;
	}

	public class ActivePortfolio {
		public Data_Z data;
	}

	
	public static TrustBeneficiaryRequest parse(String json) {
		return (TrustBeneficiaryRequest) System.JSON.deserialize(json, TrustBeneficiaryRequest.class);
	}
}