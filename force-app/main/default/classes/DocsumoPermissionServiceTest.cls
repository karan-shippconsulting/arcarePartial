@isTest
public class DocsumoPermissionServiceTest {

    @isTest
    static void testDefinePS() {
        // Setup: Create a permission set name and label
        String psName = 'TestPermissionSet';
        String psLabel = 'Test Permission Set Label';

        // Run: Call the method to define or retrieve the PermissionSet
        Test.startTest();
        String psId = DocsumoPermissionService.definePS(psName, psLabel);
        Test.stopTest();

        // Assert: Check that a PermissionSet is created or retrieved
        PermissionSet ps = [SELECT Id, Name FROM PermissionSet WHERE Id = :psId LIMIT 1];
        System.assertNotEquals(null, ps, 'PermissionSet should be created or found');
        System.assertEquals(psName, ps.Name, 'PermissionSet Name should match');
    }

    @isTest
    static void testDefineObjectPS() {
        // Setup: Create a PermissionSet and an object API name (e.g., Account)
        String psName = 'TestPermissionSet';
        String psLabel = 'Test Permission Set Label';
        String objectAPIName = 'Account';
        
        // Create PermissionSet record
        String psId = DocsumoPermissionService.definePS(psName, psLabel);

        // Run: Call the method to define object permissions
        Test.startTest();
        DocsumoPermissionService.defineObjectPS(objectAPIName, psId);
        Test.stopTest();

        // Assert: Check that ObjectPermissions is created
        List<ObjectPermissions> objPerms = [
            SELECT Id, ParentId, SobjectType FROM ObjectPermissions 
            WHERE ParentId = :psId AND SobjectType = :objectAPIName
        ];
        System.assertNotEquals(0, objPerms.size(), 'ObjectPermissions should be created');
    }

    @isTest
    static void testDefineFieldPermissions() {
        // Setup: Create a PermissionSet and an object API name (e.g., Account)
        String psName = 'TestPermissionSet';
        String psLabel = 'Test Permission Set Label';
        String objectAPIName = 'Account';
        
        // Create PermissionSet record
        String psId = DocsumoPermissionService.definePS(psName, psLabel);

        // Run: Call the method to define field permissions
        Test.startTest();
        DocsumoPermissionService.defineFieldPermissions(objectAPIName, psId);
        Test.stopTest();

        // Assert: Check that FieldPermissions is created for Account fields
        List<FieldPermissions> fieldPerms = [
            SELECT Id, ParentId, SobjectType, Field 
            FROM FieldPermissions 
            WHERE ParentId = :psId AND SobjectType = :objectAPIName
        ];
        System.assertNotEquals(0, fieldPerms.size(), 'FieldPermissions should be created for fields of Account');
    }

    @isTest
    static void testAssignPSToCurrentUser() {
        // Setup: Create a PermissionSet
        String psName = 'TestPermissionSet';
        String psLabel = 'Test Permission Set Label';
        String psId = DocsumoPermissionService.definePS(psName, psLabel);

        // Run: Call the method to assign the PermissionSet to the current user
        Test.startTest();
        DocsumoPermissionService.assignPSToCurrentUser(psId);
        Test.stopTest();

        // Assert: Check that the PermissionSetAssignment exists for the current user
        List<PermissionSetAssignment> psaList = [
            SELECT Id, AssigneeId, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :psId
        ];
        System.assertNotEquals(0, psaList.size(), 'PermissionSetAssignment should be assigned to the current user');
    }
}