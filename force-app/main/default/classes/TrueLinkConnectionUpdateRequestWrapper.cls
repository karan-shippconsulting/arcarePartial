public class TrueLinkConnectionUpdateRequestWrapper {
    public cls_data data;

    public TrueLinkConnectionUpdateRequestWrapper(){
        data = new cls_data();
    }

    public class cls_data {
        public String type;
        public String id;
        public cls_attributes attributes;
        public cls_relationships relationships;

        cls_data(){
            type = 'connection';
            attributes = new cls_attributes();
            relationships = new cls_relationships();
        }
    }

    public class cls_attributes {
        public String firstName;
        public String lastName;
        public String mobile;
        public String email;
        public String companyName;
        public String notes;
        public String street1;
        public String street2;
        public String city;
        public String state;
        public String zip;
    }

    public class cls_relationships {
        public cls_connectionRelationship connectionRelationship;

        cls_relationships(){
            connectionRelationship = new cls_connectionRelationship();
        }
    }

    public class cls_connectionRelationship {
        public cls_connectionRelationshipData data;

        cls_connectionRelationship(){
            data = new cls_connectionRelationshipData();
        }
    }

    public class cls_connectionRelationshipData {
        public String type;
        public cls_connectionRelationshipAttributes attributes;

        cls_connectionRelationshipData(){
            type = 'connectionRelationship';
            attributes = new cls_connectionRelationshipAttributes();
        }
    }

    public class cls_connectionRelationshipAttributes {
        public List<String> relationshipTypes;
        public Boolean isStatementRecipient;
    }
}