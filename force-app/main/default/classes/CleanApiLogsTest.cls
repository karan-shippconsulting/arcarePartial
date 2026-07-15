@isTest
public class CleanApiLogsTest {
    @isTest
    static void testStart() {
        Test.startTest();
        BatchUtils.rescheduleBatch('CleanApiLogs',new CleanApiLogs());
        Test.stopTest();
    }    
}