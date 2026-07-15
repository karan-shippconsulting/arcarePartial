public with sharing class DocsumoAPIDto {
  public class Content {
    public String value;
  }

  public class NestedChild {
    // field label
    public String label;
    // data type
    public String type;
    // data format
    public String format;

    public String grid_id;

    public Content content;
  }

  public class Child {
    // field label
    public String label;
    // data type
    public String type;
    // data format
    public String format;

    public Content content;

    public List<List<List<NestedChild>>> children;
  }

  public class Section {
    public String title;
    public List<Child> children;
  }

  public class Data {
    public List<Section> sections;
  }

  public class DetailResponse {
    public Data data;
  }
}