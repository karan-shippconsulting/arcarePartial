public with sharing class DocumentDetails {
  public static final Docsumo_Config__mdt configMetadata = [
    SELECT label, base_url__c, api_key__c
    FROM Docsumo_Config__mdt
    LIMIT 1
  ];

  public class DocsumoDocumentDetail {
    public String name;
    public String docId;
    public List<DocsumoFieldDetail> fieldDetails;
    public List<DocsumoTable> tables;

    public String getSFLabel() {
      return 'DS ' + this.name.replaceAll('[ /&_]+', ' ');
    }

    public String getSFObjectName() {
      return DocsumoUtils.buildSFObjectName(this.name);
    }
  }

  public class DocsumoFieldDetail {
    public String section;
    public String label;
    public String value;
    public String type;
    public String format;
    public Integer length;

    public String getSFLabel() {
      String fieldLabel = this.label;
      if (this.section != null) {
        String[] tokens = this.section.trim().split(' ');
        String prefix = '';
        for (String token : tokens) {
          prefix += token.subString(0, 1);
        }
        fieldLabel = prefix + ' ' + this.label;
      }
      if (fieldLabel.length() > 20) {
        fieldLabel = fieldLabel.substring(0, 20);
      }
      return fieldLabel.replaceAll('[ /&_]+', ' ');
    }

    public String getSFColumnName() {
      String fieldName = this.label;
      if (this.section != null && (this.section.trim() != '')) {
        String[] tokens = this.section.trim().split(' ');
        String prefix = '';
        for (String token : tokens) {
          prefix += token.subString(0, 1);
        }
        System.debug('section: ' + this.section + '\tprefix: ' + prefix);
        fieldName = prefix + ' ' + this.label;
      }
      System.debug('actual field name: ' + fieldName);

      return DocsumoUtils.sanitizeFieldName(fieldName).toLowerCase();
    }
  }

  public class DocsumoTable {
    public String section;
    public String label;
    public List<DocsumoHeaderCell> header;
    public List<DocsumoTableRow> rows;

    public String getSFObjectName() {
      String fieldName = this.label;
      if (this.section != null) {
        fieldName = this.section + ' ' + this.label;
      }
      System.debug('actual field name: ' + fieldName);

      return 'DS_' + DocsumoUtils.sanitizeFieldName(fieldName).toLowerCase();
    }

    public String getSFLabel() {
      String fieldLabel = this.label;
      if (this.section != null) {
        fieldLabel = this.section + ' ' + this.label;
      }
      return 'DS ' + fieldLabel.replaceAll('[ /&_]+', ' ');
    }
  }

  public class DocsumoHeaderCell {
    public String section;
    public String label;
    public String type;

    public String getSFLabel() {
      String fieldLabel = this.label;
      if (this.section != null) {
        fieldLabel = this.section + ' ' + this.label;
      }
      return fieldLabel.replaceAll('[ /&_]+', ' ');
    }

    public String getSFColumnName() {
      String fieldName = this.label;
      if (this.section != null) {
        String[] tokens = this.section.trim().split(' ');
        String prefix = '';
        for (String token : tokens) {
          prefix += token.charAt(0);
        }
        fieldName = prefix + ' ' + this.label;
      }
      System.debug('actual field name: ' + fieldName);

      return DocsumoUtils.sanitizeFieldName(fieldName).toLowerCase();
    }
  }

  public class DocsumoTableRow {
    public List<DocsumoFieldDetail> cells;
  }

  public static DocsumoDocumentDetail fetch(String docId, String docType) {
    DocsumoAPIDto.DetailResponse response = fetchData(docId);

    return mapResponse(response, docType, docId);
  }

  public static DocsumoAPIDto.DetailResponse fetchData(String docId) {
    String url =
      configMetadata.base_url__c +
      '/api/v2/pik/documents/' +
      docId +
      '/data/';

    String res = DocsumoAPIUtils.fetchApi(url);
    DocsumoAPIDto.DetailResponse response = (DocsumoAPIDto.DetailResponse) JSON.deserialize(
      res,
      DocsumoAPIDto.DetailResponse.class
    );
    return response;
  }

  public static DocsumoDocumentDetail mapResponse(
    DocsumoAPIDto.DetailResponse response,
    String docType,
    String docId
  ) {
    DocsumoDocumentDetail docDetail = new DocsumoDocumentDetail();
    docDetail.name = docType;
    docDetail.docId = docId;

    List<DocsumoFieldDetail> fieldDetails = new List<DocsumoFieldDetail>();
    List<DocsumoTable> tables = new List<DocsumoTable>();

    for (DocsumoAPIDto.Section section : response.data.sections) {
      for (DocsumoAPIDto.Child c : section.children) {
        if (c.type == 'line_item') {
          //NOTE: ignore multiple accounts for now
          if (c.label == 'Multiple Accounts') {
            continue;
          }
          DocsumoTable table = mapTable(section.title, c, docId);
          tables.add(table);
        } else {
          DocsumoFieldDetail fieldType = mapFieldDetail(section.title, c);
          fieldDetails.add(fieldType);
        }
      }
    }

    docDetail.fieldDetails = fieldDetails;
    docDetail.tables = tables;

    return docDetail;
  }

  private static DocsumoFieldDetail mapFieldDetail(
    String sectionTitle,
    DocsumoAPIDto.Child c
  ) {
    DocsumoFieldDetail fieldType = new DocsumoFieldDetail();
    fieldType.section = sectionTitle;
    fieldType.label = c.label;
    fieldType.type = c.type;
    fieldType.format = c.format;
    if (c.content != null) {
      fieldType.value = c.content.value;
    }
    return fieldType;
  }

  private static DocsumoTable mapTable(
    String sectionTitle,
    DocsumoAPIDto.Child c,
    String docId
  ) {
    DocsumoTable table = new DocsumoTable();
    table.section = sectionTitle;
    table.label = c.label;

    List<DocsumoHeaderCell> header = new List<DocsumoHeaderCell>();
    DocsumoHeaderCell docIdHeaderCell = createHeaderCell(
      'Doc Id',
      'string',
      null
    );
    header.add(docIdHeaderCell);

    List<DocsumoTableRow> rows = new List<DocsumoTableRow>();

    Boolean isHeader = true;
    for (List<List<DocsumoAPIDto.NestedChild>> grid : c.children) {
      for (List<DocsumoAPIDto.NestedChild> line : grid) {
        if (isHeader) {
          for (DocsumoAPIDto.NestedChild ns : line) {
            DocsumoHeaderCell hc = createHeaderCell(
              ns.label,
              ns.type,
              sectionTitle
            );
            header.add(hc);
          }
          isHeader = false;
        } else {
          DocsumoTableRow row = new DocsumoTableRow();
          List<DocsumoFieldDetail> cells = new List<DocsumoFieldDetail>();

          DocsumoFieldDetail docIdFieldCell = new DocsumoFieldDetail();
          docIdFieldCell.label = 'Doc Id';
          docIdFieldCell.type = 'string';
          docIdFieldCell.value = docId;

          cells.add(docIdFieldCell);
          for (DocsumoAPIDto.NestedChild ns : line) {
            //populate rows
            DocsumoFieldDetail fieldType = createFieldCell(sectionTitle, ns);

            cells.add(fieldType);
          }
          row.cells = cells;
          rows.add(row);
        }
      }
    }
    table.header = header;
    table.rows = rows;
    return table;
  }

  private static DocsumoFieldDetail createFieldCell(
    String sectionTitle,
    DocsumoAPIDto.NestedChild ns
  ) {
    DocsumoFieldDetail fieldType = new DocsumoFieldDetail();
    fieldType.section = sectionTitle;
    fieldType.label = ns.label;
    fieldType.type = ns.type;
    fieldType.format = ns.format;
    fieldType.value = ns.content.value;
    return fieldType;
  }

  private static DocsumoHeaderCell createHeaderCell(
    String label,
    String type,
    String sectionTitle
  ) {
    DocsumoHeaderCell hc = new DocsumoHeaderCell();
    hc.section = sectionTitle;
    hc.label = label;
    hc.type = type;
    return hc;
  }
}