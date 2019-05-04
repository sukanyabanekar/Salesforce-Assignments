({
    getProductInfo : function(component,event) {
        // create a one-time use instance of the serverEcho action
        // in the server-side controller
        var action = component.get("c.productInformation");
        action.setParams({ caseId : component.get("v.recordId") });
        
        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var classInstance = response.getReturnValue();
                var costCalendarList = [], ATMFeesList=[], CostReplList=[];
                if(!classInstance.nocontactAssociated  && 
                   !classInstance.noinfofound){
                    debugger;
                    // prepare map for ATM Fees
                    for (var key in classInstance.mapATMFees) {
                        var category = key;                        
                        for(var country in classInstance.mapATMFees[key]){
                            var cost=classInstance.mapATMFees[key][country];
                            ATMFeesList.push({category:key,country:country,cost:cost});
                        }
                    }
                    // prepare map for cost per calendar
                    for (var key in classInstance.mapCostPerCalendar) {
                        var category = key;                        
                        for(var country in classInstance.mapCostPerCalendar[key]){
                            var cost=classInstance.mapCostPerCalendar[key][country];
                            costCalendarList.push({category:key,country:country,cost:cost});
                        }
                    }
                    
                    // prepare map for Cost Replacement
                    for (var key in classInstance.mapCardReplCost) {
                        var category = key;                        
                        for(var country in classInstance.mapCardReplCost[key]){
                            var cost=classInstance.mapCardReplCost[key][country];
                            CostReplList.push({category:key,country:country,cost:cost});
                        }
                    }
                    component.set("v.costCalendarList",costCalendarList);
                    component.set("v.ATMFeesList",ATMFeesList);
                    component.set("v.CostReplList",CostReplList);
                }
                else if(classInstance.nocontactAssociated){
                    component.set("v.noContactAssociate",true);
                }
                    else{
                        component.set("v.noinfometadata",true);
                    }
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
                else if (state === "ERROR") {
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
        
        // optionally set storable, abortable, background flag here
        
        // A client-side action could cause multiple events, 
        // which could trigger other events and 
        // other server-side action calls.
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
    }
})