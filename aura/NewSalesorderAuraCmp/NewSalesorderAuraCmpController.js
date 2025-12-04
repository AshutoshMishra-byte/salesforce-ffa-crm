({
    handleClose: function(component, event, helper) {
        var message = event.getParam('message');
        console.log(message);
        
        // Fire closeQuickAction event to close the quick action modal
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})