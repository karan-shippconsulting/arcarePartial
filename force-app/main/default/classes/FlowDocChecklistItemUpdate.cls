public with sharing class FlowDocChecklistItemUpdate {

    public class Request {
        @InvocableVariable(required=false label='Document Checklist Item (single)')
        public DocumentChecklistItem item;

        @InvocableVariable(required=false label='Document Checklist Items (collection)')
        public List<DocumentChecklistItem> items;

        @InvocableVariable(required=false label='Record Id (update by Id only)')
        public Id recordId;
    }

    public class Result {
        @InvocableVariable(label='Record Id')
        public Id recordId;
    }

    @InvocableMethod(
        label='Create or Update Document Checklist Item'
        description='Apex workaround: Flows cannot create or update DocumentChecklistItem directly. If the item has no Id it is inserted; if it has an Id it is updated.'
        category='Documents'
    )
    public static List<Result> execute(List<Request> requests) {
        List<DocumentChecklistItem> toInsert = new List<DocumentChecklistItem>();
        List<DocumentChecklistItem> toUpdate = new List<DocumentChecklistItem>();

        for (Request req : requests) {
            if (req.items != null && !req.items.isEmpty()) {
                for (DocumentChecklistItem i : req.items) {
                    if (i.Id != null) toUpdate.add(i);
                    else              toInsert.add(i);
                }
            } else if (req.item != null) {
                if (req.item.Id != null) toUpdate.add(req.item);
                else                     toInsert.add(req.item);
            } else if (req.recordId != null) {
                toUpdate.add(new DocumentChecklistItem(Id = req.recordId));
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
        if (!toUpdate.isEmpty()) update toUpdate;

        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            if (req.items != null && !req.items.isEmpty()) {
                r.recordId = req.items[0].Id;
            } else if (req.item != null) {
                r.recordId = req.item.Id;
            } else {
                r.recordId = req.recordId;
            }
            results.add(r);
        }
        return results;
    }
}