public class TrueLinkConnectionsResponseWrapper {
    public List<cls_data> data;
    public List<cls_included> included;

    public class cls_data {
        public String type;
        public String id;
        public cls_attributes attributes;
        public cls_relationships relationships;
    }

    public class cls_attributes {
        public String firstName;
        public String lastName;
        public String mobile;
        public String email;
        public String companyName;
        public String notes;
        public Boolean isCommon;
        public String street1;
        public String street2;
        public String city;
        public String state;
        public String zip;
    }

    public class cls_relationships {
        public cls_reldata organization;
        public cls_reldata connectionRelationship;
    }

    public class cls_reldata {
        public cls_refdata data;
    }

    public class cls_refdata {
        public String type;
        public String id;
    }

    public class cls_included {
        public String type;
        public String id;
        public cls_included_attributes attributes;
    }

    public class cls_included_attributes {
        public List<String> relationshipTypes;
        public Boolean isStatementRecipient;
    }

    public static TrueLinkConnectionsResponseWrapper parse(String jsonStr) {
        return (TrueLinkConnectionsResponseWrapper) JSON.deserialize(jsonStr, TrueLinkConnectionsResponseWrapper.class);
    }
}