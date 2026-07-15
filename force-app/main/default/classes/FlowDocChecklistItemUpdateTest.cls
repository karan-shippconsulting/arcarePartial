@isTest
private class FlowDocChecklistItemUpdateTest {

    private static DocumentChecklistItem createChecklist(Id parentId) {
        DocumentChecklistItem item = new DocumentChecklistItem();
        item.Name        = 'Test Doc';
        item.Status      = 'New';
        item.ParentRecordId = parentId;
        return item;
    }

    // ── Create via single item (no Id → insert) ───────────────────────────────
    @isTest
    static void testCreateSingleItem() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        DocumentChecklistItem item = createChecklist(acc.Id);

        FlowDocChecklistItemUpdate.Request req = new FlowDocChecklistItemUpdate.Request();
        req.item = item;

        Test.startTest();
        List<FlowDocChecklistItemUpdate.Result> results =
            FlowDocChecklistItemUpdate.execute(new List<FlowDocChecklistItemUpdate.Request>{ req });
        Test.stopTest();

    }

    // ── Update via single item (has Id → update) ──────────────────────────────
    @isTest
    static void testUpdateSingleItem() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        DocumentChecklistItem item = createChecklist(acc.Id);
        insert item;

        item.Name = 'Updated Doc';

        FlowDocChecklistItemUpdate.Request req = new FlowDocChecklistItemUpdate.Request();
        req.item = item;

        Test.startTest();
        List<FlowDocChecklistItemUpdate.Result> results =
            FlowDocChecklistItemUpdate.execute(new List<FlowDocChecklistItemUpdate.Request>{ req });
        Test.stopTest();
    }

    // ── Update via bare recordId ──────────────────────────────────────────────
    @isTest
    static void testUpdateByRecordId() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        DocumentChecklistItem item = createChecklist(acc.Id);
        insert item;

        FlowDocChecklistItemUpdate.Request req = new FlowDocChecklistItemUpdate.Request();
        req.recordId = item.Id;

        Test.startTest();
        List<FlowDocChecklistItemUpdate.Result> results =
            FlowDocChecklistItemUpdate.execute(new List<FlowDocChecklistItemUpdate.Request>{ req });
        Test.stopTest();

    }

    // ── Create and update via collection ─────────────────────────────────────
    @isTest
    static void testCollection() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        DocumentChecklistItem newItem = createChecklist(acc.Id);

        DocumentChecklistItem existingItem = createChecklist(acc.Id);
        insert existingItem;
        existingItem.Name = 'Collection Updated';

        FlowDocChecklistItemUpdate.Request req = new FlowDocChecklistItemUpdate.Request();
        req.items = new List<DocumentChecklistItem>{ newItem, existingItem };

        Test.startTest();
        FlowDocChecklistItemUpdate.execute(new List<FlowDocChecklistItemUpdate.Request>{ req });
        Test.stopTest();
    }
}