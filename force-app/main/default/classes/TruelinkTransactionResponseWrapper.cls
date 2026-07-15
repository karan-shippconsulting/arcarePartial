public class TruelinkTransactionResponseWrapper{
	public cls_data[] data;
    public cls_included[] included;
	public class cls_data {
		public String id;	//string
		public String type;	//bank_account
		public cls_attributes attributes;
        public cls_relationships relationships;
        public cls_meta meta;
	}
    public class cls_meta{
        public String displayCategory;
    }
	public class cls_attributes {
		public String firstName;	//`
		public String lastName;	//string
		public String email;	//string
		public boolean siteAdmin;
		public String clearedDate;
		public String deliveryDate;
        public String processedDate;
		public String paymentMethod;
		public String status;
		public String requestorDescription;
		public String requestedBySignature;
		public String payeeName;
		public String payeeDescription;
        public String payeeDisposition;
		public Integer postageCode;
		public String postageType;
		public String checkNum;
		public String checkMemoLine;
		public String payeeMemo;
		public String payeeSpecialInstructions;
		public String payeeSwiftCode;
		public String merchant; // Deposit api
		public cls_amount amount;
		public cls_payeeBankAccount payeeBankAccount;
		public cls_payeeAddress payeeAddress;
        public String notes;
        public String paymentId;
        public Boolean fromRecurring;
		public String merchantName;
		public String location;
		public Boolean settled;
		public DateTime timestamp;
	}
	public class cls_amount {
		public Double amount;	//0
		public String field_currency;	//USD
	}
	public class cls_payeeAddress {
		public String street1;	//string
		public String street2;	//string
		public String city;	//string
		public String state;	//string
		public String zip;	//string
	}
	public class cls_payeeBankAccount {
		public String accountNumber;	//string
		public String routingNumber;	//string
	}
    public class cls_relationships{
        public cls_categoryAmounts categoryAmounts;
		public cls_attachments attachments;
		public cls_recurringDisbursements recurringDisbursement;
    }
    public class cls_categoryAmounts{
        public cls_categoryAmounts_data[] data;
    }
	public class cls_recurringDisbursements{
        public cls_recurringDisbursement_data data;
    }
	public class cls_attachments{
		public cls_attachments_data[] data;
	}
    public class cls_categoryAmounts_data{
        public String id;	//string
		public String type;	//bank_account
    }
	public class cls_recurringDisbursement_data{
        public String id;	//string
		public String type;	//bank_account
    }
	public class cls_attachments_data{
        public String id;	//string
		public String type;	//bank_account
    }
    public class cls_included{
        public String id;	//string
		public String type;	//bank_account
        public cls_included_attributes attributes;
    }
    public class cls_included_attributes{
        public string notes;
		public string recurringType;
		public integer frequency;
    }
    public TruelinkTransactionResponseWrapper(){
        this.data = new list<cls_data>();
    }
	public TruelinkTransactionResponseWrapper parse(String json){
		return (TruelinkTransactionResponseWrapper) System.JSON.deserialize(json, TruelinkTransactionResponseWrapper.class);
	}
}