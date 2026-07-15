({
	printhandler : function(component, event, helper) {
		const evtName = event.target.name;
        helper.userPrintPreviewAction(component, evtName, component.get("v.printMsg"));
	},
    
    emailHandler : function(component, event, helper) {
		const evtName = event.target.name;
        helper.userAction(component, evtName, component.get("v.printMsg"));
	},
    
    printWithEmailHandler : function(component, event, helper) {
		const evtName = event.target.name;
        helper.userAction(component, evtName, component.get("v.emailMsg"));
	},
    closeModel : function(component, event, helper){
       window.parent.location.href ="/lightning/o/Opportunity/list?filterName=__Recent";
    }
    
})