public class DocsumoPermissionService {
  public static String definePS(String name, String label) {
    PermissionSet ps = new PermissionSet();
    ps.Name = name;
    ps.Label = label;
    // Query if PermissionSet already exists
    List<PermissionSet> existingPS = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :name
      LIMIT 1
    ];
    if (!existingPS.isEmpty()) {
      System.debug('exsting permission set found');
      return existingPS[0].Id;
    }

    System.debug('creating new permission set');
    insert ps;

    return ps.Id;
  }

  @future
  public static void defineObjectPS(String objAPIName, Id psId) {
    try {
      List<ObjectPermissions> existingPerms = [
        SELECT
          Id,
          ParentId,
          SobjectType,
          PermissionsRead,
          PermissionsCreate,
          PermissionsEdit,
          PermissionsDelete
        FROM ObjectPermissions
        WHERE ParentId = :psId AND SobjectType = :objAPIName
        LIMIT 1
      ];

      if (!existingPerms.isEmpty()) {
        System.debug('existing Object Permission found');
        return;
      }

      System.debug('creating new Object permission');
      Boolean objectExists = false;
      while (objectExists == false) {
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        if (globalDescribeMap.containsKey(objAPIName)) {
          objectExists = true; // Object exists
        }
      }

      ObjectPermissions objPs = new ObjectPermissions();
      System.debug('Object status ' + objectExists);
      if (objectExists == true) {
        objPs.ParentId = psId;
        objPs.SobjectType = objAPIName;
        objPs.PermissionsRead = true;
        objPs.PermissionsCreate = true;
        objPs.PermissionsEdit = true;
        objPs.PermissionsDelete = true;
        //objPs.PermissionsViewAllRecords = true;
        //objPs.PermissionsModifyAllRecords = true;

        // Insert the object permissions
        insert objPs;
      }
    } catch (Exception e) {
      throw e;
    }
  }

  @future
  public static void defineFieldPermissions(
    String objectApiName,
    Id permissionSetId
  ) {
    // List to hold the FieldPermissions records to be inserted
    List<FieldPermissions> fieldPermissionsList = new List<FieldPermissions>();

    // Retrieve the SObject type using the objectApiName
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
      .get(objectApiName);

    // Get the field map for the SObject
    Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

    // Iterate through all the fields of the SObject
    for (String fieldName : fieldMap.keySet()) {
      // Create a new FieldPermissions record for each field
      FieldPermissions fieldPermission = new FieldPermissions();
      fieldPermission.ParentId = permissionSetId; // Set the PermissionSet Id
      fieldPermission.SobjectType = objectApiName; // Set the Object API Name
      fieldPermission.Field = objectApiName + '.' + fieldName; // Set the Field Name
      fieldPermission.PermissionsRead = true; // Grant read access
      fieldPermission.PermissionsEdit = true; // Grant edit access

      // Add the FieldPermissions record to the list
      fieldPermissionsList.add(fieldPermission);
    }

    //System.assert(false, fieldPermissionsList);

    // Insert the FieldPermissions records in bulk
    if (!fieldPermissionsList.isEmpty()) {
      Database.insert(fieldPermissionsList, false);
    }
  }

  public static void assignPSToCurrentUser(Id psId) {
    // Assign the permission set to a user
    PermissionSetAssignment psa = new PermissionSetAssignment();
    psa.AssigneeId = UserInfo.getUserId();
    psa.PermissionSetId = psId;

    // Insert the permission set assignment
    Database.insert(psa, false);
  }
}