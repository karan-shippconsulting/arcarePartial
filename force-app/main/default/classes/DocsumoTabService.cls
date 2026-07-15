public class DocsumoTabService {
  public static Boolean doesTabExist(String objectAPIName) {
    // Get the current list of tabs
    List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();

    boolean tabExists = false;
    // Iterate through the tab sets
    for (DescribeTabSetResult tsr : tabSetDesc) {
      // Get the tabs for the current tab set
      List<Schema.DescribeTabResult> tabDesc = tsr.getTabs();

      // Check if the custom object tab already exists
      for (DescribeTabResult tr : tabDesc) {
        if (tr.getSobjectName() == objectAPIName) {
          tabExists = true;
          break;
        }
      }
    }

    return tabExists;
  }


  public static void createTab(MetadataService.MetadataPort service, String objectAPIName) {
    MetadataService.CustomTab customTab = new MetadataService.CustomTab();
    customTab.fullName = objectAPIName;
    customTab.label = objectAPIName.removeEnd('__c').replace('_', ' ');
    customTab.mobileReady = true;
    customTab.customObject = true;
    customTab.motif = 'Custom20:Airplane';

    // Add the custom tab to the list of tabs
    try {
      List<MetadataService.SaveResult> results = service.createMetadata(
        new List<MetadataService.Metadata>{ customTab }
      );
    } catch (Exception ex) {
      System.assert(false, ex);
    }
  }
}