public class DocsumoUpsertRecords implements Queueable {
  final DocumentDetails.DocsumoDocumentDetail docsumoDocDetail;
  final Map<String, List<String>> existingFields;
  public DocsumoUpsertRecords(
    DocumentDetails.DocsumoDocumentDetail docsumoDocDetail,
    Map<String, List<String>> existingFields
  ) {
    this.docsumoDocDetail = docsumoDocDetail;
    this.existingFields = existingFields;
  }

  public void execute(QueueableContext context) {
    DocsumoRecordService.upsertRecord(docsumoDocDetail, existingFields);
  }
}