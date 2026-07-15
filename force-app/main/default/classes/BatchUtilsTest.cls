@isTest
public class BatchUtilsTest {
    @isTest
    static void testrescheduleBatch(){
        TestSchedulable schedulableInstance = new TestSchedulable();
        BatchUtils.rescheduleBatch('Test',schedulableInstance);
    }
    
    public class TestSchedulable implements Schedulable {
        public void execute(SchedulableContext sc) {}
    }

}