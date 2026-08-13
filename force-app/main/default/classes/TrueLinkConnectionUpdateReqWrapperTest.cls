@isTest
private class TrueLinkConnectionUpdateReqWrapperTest {

    @isTest
    static void testConstructorInitializesNestedStructure() {
        TrueLinkConnectionUpdateRequestWrapper wrapper = new TrueLinkConnectionUpdateRequestWrapper();

        System.assertNotEquals(null, wrapper.data);
        System.assertEquals('connection', wrapper.data.type);
        System.assertNotEquals(null, wrapper.data.attributes);

        System.assertNotEquals(null, wrapper.data.relationships);
        System.assertNotEquals(null, wrapper.data.relationships.connectionRelationship);
        System.assertNotEquals(null, wrapper.data.relationships.connectionRelationship.data);
        System.assertEquals('connectionRelationship', wrapper.data.relationships.connectionRelationship.data.type);
        System.assertNotEquals(null, wrapper.data.relationships.connectionRelationship.data.attributes);
    }

    @isTest
    static void testFieldAssignmentAndSerializationRoundTrip() {
        TrueLinkConnectionUpdateRequestWrapper wrapper = new TrueLinkConnectionUpdateRequestWrapper();
        wrapper.data.id = 'connection-123';
        wrapper.data.attributes.firstName = 'John';
        wrapper.data.attributes.lastName = 'Doe';
        wrapper.data.attributes.mobile = '9876543210';
        wrapper.data.attributes.email = 'john.doe@example.com';
        wrapper.data.attributes.companyName = 'Acme Co';
        wrapper.data.attributes.notes = 'Some notes';
        wrapper.data.attributes.street1 = '123 Main St';
        wrapper.data.attributes.street2 = 'Apt 1';
        wrapper.data.attributes.city = 'Anytown';
        wrapper.data.attributes.state = 'CA';
        wrapper.data.attributes.zip = '12345';
        wrapper.data.relationships.connectionRelationship.data.attributes.relationshipTypes = new List<String>{'Sibling', 'Guardian'};
        wrapper.data.relationships.connectionRelationship.data.attributes.isStatementRecipient = true;

        String jsonStr = JSON.serialize(wrapper, true);

        System.assert(jsonStr.contains('"id":"connection-123"'), 'Serialized JSON should include the connection id: ' + jsonStr);
        System.assert(jsonStr.contains('"firstName":"John"'), 'Serialized JSON should include attributes: ' + jsonStr);
        System.assert(jsonStr.contains('"type":"connection"'), 'Serialized JSON should include the top-level type: ' + jsonStr);
        System.assert(jsonStr.contains('"type":"connectionRelationship"'), 'Serialized JSON should include the relationship type: ' + jsonStr);
        System.assert(jsonStr.contains('"relationshipTypes":["Sibling","Guardian"]'), 'Serialized JSON should include relationship types: ' + jsonStr);
        System.assert(jsonStr.contains('"isStatementRecipient":true'), 'Serialized JSON should include isStatementRecipient: ' + jsonStr);

        TrueLinkConnectionUpdateRequestWrapper deserialized =
            (TrueLinkConnectionUpdateRequestWrapper) JSON.deserialize(jsonStr, TrueLinkConnectionUpdateRequestWrapper.class);

        System.assertEquals('connection-123', deserialized.data.id);
        System.assertEquals('John', deserialized.data.attributes.firstName);
        System.assertEquals('Doe', deserialized.data.attributes.lastName);
        System.assertEquals('12345', deserialized.data.attributes.zip);
        System.assertEquals(2, deserialized.data.relationships.connectionRelationship.data.attributes.relationshipTypes.size());
        System.assertEquals(true, deserialized.data.relationships.connectionRelationship.data.attributes.isStatementRecipient);
    }
}