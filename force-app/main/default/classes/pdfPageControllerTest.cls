@isTest
public class pdfPageControllerTest {
	@isTest
    static void validateMethod(){
        Account obj = new Account(Name ='Test');
        insert obj;
        PageReference pageRef = Page.renderPDF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('recId', String.valueOf(obj.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(obj);
    	pdfPageController pdf = new pdfPageController(sc);
		pdfPageController pdf1 = new pdfPageController();
    }
}