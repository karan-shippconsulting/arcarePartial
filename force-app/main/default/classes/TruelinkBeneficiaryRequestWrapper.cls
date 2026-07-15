public class TruelinkBeneficiaryRequestWrapper {
    public Data data;
    public cls_included[] included;
    public class Data {
        public String type;
        public Attributes attributes;
        public Relationships relationships;
        public String id;
        public Meta meta;
        
        public Data() {
            type = 'trust_beneficiary';
        }
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
        public Boolean chargeSetupFee;
        public Boolean disallowDisbursementRequests;
        public Boolean mailStatement;
        public String beneficiaryId;
        public String trustBeneficiaryInternalId;
    }
    
    public class Meta{
        public Decimal totalAccountBalance{get; set;}
        public AvailableCashSum availableCashSum;
    }
    
    public class AvailableCashSum{
        public Decimal amount{get; set;}
        public String cash_currency{get; set;}

        public Map<String, Object> toMap() {
            return new Map<String, Object>{
                'amount' => amount,
                'currency' => cash_currency
            };
        }
    }
    
    public class Relationships {
        public AddressWrapper address;
        public PortfolioWrapper activePortfolio;
        public DisabilityDesignationWrapper disabilityDesignation;
        public cls_primaryCard primaryCard;
        public cls_organizationCard organizationCard;
        public AccountsWrapper accounts { get; set; }
        
        public Relationships() {
            this.address = new AddressWrapper();
            this.activePortfolio = new PortfolioWrapper();
            this.disabilityDesignation = new DisabilityDesignationWrapper();
        }
    }
    public class cls_included{
        public String id;	//string
		public String type;	//bank_account
        public cls_included_attributes attributes;
    }
    public class cls_included_attributes{
        public string lastFour;
		public string cardReference;
		public string program;
        public string status;
        public string expiryDate;
        public cls_balance balance;
        public boolean isBreached;
        public string breach;
        public string fraudBlockType;
    }

    public class cls_balance{
        public Decimal amount{get; set;}
        public String timestamp{get; set;}
    }

    public class cls_primaryCard{
        public cls_primaryCard_data data;
    }
    public class cls_organizationCard{
        public cls_organizationCard_data data;
    }

    public class cls_primaryCard_data{
        public String id;	//string
		public String type;	//bank_account
    }
    public class cls_organizationCard_data{
        public String id;	//string
		public String type;	//bank_account
    }
    public class AccountsWrapper {
        public List<AccountData> data { get; set; }
    }

    public class AccountData {
        public String type { get; set; }
        public String id { get; set; }
    }

    public class PortfolioData{
        public String type;
        public String id;
    }

    public class AddressWrapper {
        public AddressData data;
        
        public AddressWrapper() {
            this.data = new AddressData();
        }
    }
    
    public class PortfolioWrapper{
        public PortfolioData data;
        public PortfolioWrapper(){
            this.data = new PortfolioData();
        }
    }
    
    public class DisabilityDesignationWrapper{
        public DisabilityDesignationData data;
        public DisabilityDesignationWrapper(){
            this.data = new DisabilityDesignationData();
        }
    }
    
    public class DisabilityDesignationData{
        public String type;
        public String id;
    }
    
    public class AddressData {
        public String type;
        public String id;
        public AddressAttributes attributes;
        
        public AddressData() {
            type = 'address';
            attributes = new AddressAttributes();
        }
    }
    
    public class AddressAttributes {
        public String street1;
        public String street2;
        public String city;
        public String state;
        public String zip;
    }
    
    public TruelinkBeneficiaryRequestWrapper(){
        this.data = new Data();
        this.data.attributes = new Attributes();
        this.data.relationships = new Relationships();    
        this.data.meta = new Meta();
    }
    
    // Constructor to initialize default values and structures
    public TruelinkBeneficiaryRequestWrapper(Boolean isUpdate) {
        this.data = new Data();
        this.data.attributes = new Attributes(); 
        if(!isUpdate){
            this.data.relationships = new Relationships();    
        }
    }
}