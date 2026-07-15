public with sharing class BulkEmailTemplateManagerController {
    public List<Id> selectedIds { get; set; }

    public BulkEmailTemplateManagerController(ApexPages.StandardSetController stdController) {
        selectedIds = new List<Id>();
        for (SObject sobj : stdController.getSelected()) {
            selectedIds.add(sobj.Id);
        }
    }

    // Return as comma-separated string for Visualforce or JS
    //public String getRecordIds() {
        //return String.join(selectedIds, ',');
    //}
}