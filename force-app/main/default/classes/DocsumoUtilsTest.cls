@isTest
public with sharing class DocsumoUtilsTest {
  @isTest
  static void testSanitizeString() {
    //given
    Map<String, String> testCases = new Map<String, String>{
      'hello' => 'hello__c',
      'hello world' => 'hello_world__c',
      'Seller Detail GST/ VAT Number' => 'seller_detail_gst_va__c',
      'some__field' => 'some_field__c',
      '123_field' => 'field__c',
      '123_test_field__' => 'test_field__c',
      '123_test_field___' => 'test_field__c'
    };
    for (String input : testCases.keySet()) {
      String expected = testCases.get(input);
      //when
      String output = DocsumoUtils.sanitizeFieldName(input);
      //then
      System.assertEquals(expected, output);
    }
  }

  @isTest
  static void testParseDate() {
    //given
    Map<String, Date> testCases = new Map<String, Date>{
      '20/11/2020' => Date.newInstance(2020, 11, 20),
      '20/01/2020' => Date.newInstance(2020, 1, 20),
      '20/01/abc' => null
    };
    for (String input : testCases.keySet()) {
      Date expected = testCases.get(input);
      //when
      Date output = DocsumoUtils.parseDate(input);
      //then
      System.assertEquals(expected, output);
    }
  }

  @isTest
  static void testParseDecimal() {
    //given
    Map<String, Decimal> testCases = new Map<String, Decimal>{
      '1' => 1,
      '5' => 5,
      '$8' => 8,
      '' => 0,
      'abc' => 0
    };
    for (String input : testCases.keySet()) {
      Decimal expected = testCases.get(input);
      //when
      Decimal output = DocsumoUtils.parseDecimal(input);
      //then
      System.assertEquals(expected, output);
    }
  }

  @IsTest
  static void testFetchSFObjectDetails() {
      // Test with a valid object name
      List<String> objectDetails = DocsumoUtils.fetchSFObjectDetails('Account');
      System.assertNotEquals(null, objectDetails, 'Object details should not be null for a valid object name');

      // Test with an invalid object name
      List<String> invalidObjectDetails = DocsumoUtils.fetchSFObjectDetails('InvalidObject');
      System.assertEquals(null, invalidObjectDetails, 'Object details should be null for an invalid object name');
  }
}