({
	userAction : function(cmp, evtName, message) {
		cmp.set("v.actionClicked" , true);        
        var action = cmp.get("c.vfPageSelector");
        action.setParams({ 
			selectedRecords : cmp.get("v.selectedOpportunity").split(';'),
             userActions : evtName
		});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                this.showToast('Success','success', message);
                setTimeout(()=>{
                    window.parent.location.href ="/lightning/o/Opportunity/list?filterName=__Recent";
                },100);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                 this.showToast('Error','error', cmp.get('v.actionErrorMsg'));
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    showToast : function(title ,type, msg) {
        console.log('demo call',msg)
        sforce.one.showToast({
            "title": title,
            "message": msg,
            "type":type
        });
	},
    
	userPrintPreviewAction : function(cmp, evtName, message) {
		cmp.set("v.actionClicked" , true);        
        var action = cmp.get("c.vfPageSelector");
        action.setParams({ 
			selectedRecords : cmp.get("v.selectedOpportunity").split(';'),
             userActions : evtName
		});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.actionClicked" , false);
                setTimeout(()=>{
                    window.open(response.getReturnValue(),'_blank');
                },100);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                 this.showToast('Error','error', cmp.get('v.actionErrorMsg'));
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	},
})