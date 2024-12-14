trigger MaintenanceRequest on Case (before update, after update) {
    if (Trigger.isAfter) {
        // List to track cases that have just been closed and meet our criteria
        List<Case> newlyClosedRequests = new List<Case>();
        
        // Identify Cases that are now closed and were previously not closed, 
        // and have Type as either 'Repair' or 'Routine Maintenance'.
        for (Case currentRequest : Trigger.new) {
            Case oldRequest = Trigger.oldMap.get(currentRequest.Id);
            Boolean justClosed = currentRequest.Status == 'Closed' && oldRequest.Status != 'Closed';
            Boolean eligibleType = (currentRequest.Type == 'Repair' || currentRequest.Type == 'Routine Maintenance');
            
            if (justClosed && eligibleType) {
                newlyClosedRequests.add(currentRequest);
            }
        }

        if (!newlyClosedRequests.isEmpty()) {
            MaintenanceRequestHelper.updateWorkOrders(newlyClosedRequests);
        }
        
    }
}