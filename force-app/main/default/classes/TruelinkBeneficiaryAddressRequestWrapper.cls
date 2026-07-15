public class TruelinkBeneficiaryAddressRequestWrapper {

	public Data data;

	public class Attributes {
		public String street1;
		public String street2;
		public String city;
		public String state;
		public String zip;
	}

	public class Data {
		public String type;
		public String id;
		public Attributes attributes;
	}
    
    public TruelinkBeneficiaryAddressRequestWrapper(){
        this.data = new Data();
        this.data.attributes = new Attributes();
    }
}