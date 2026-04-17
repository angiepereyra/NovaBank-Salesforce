({
    fetchData : function(component) {
        component.set("v.isLoading", true);
        var action = component.get("c.getBenefits");
 
        action.setParams({
            accountId: component.get("v.recordId")
        });
 
        action.setCallback(this, function(response) {
            component.set("v.isLoading", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.benefits", response.getReturnValue());
            } else {
                var errors = response.getError();
                console.error(errors);
            }
        });
        $A.enqueueAction(action);
    }
})