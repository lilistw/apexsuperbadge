public with sharing class MaintenanceRequestHelper {
    
    /**
     * Updates Work Orders based on the status of given Cases.
     * If a Case is newly closed and is of type Repair or Routine Maintenance, 
     * we create follow-up Routine Maintenance Requests.
     *
     * @param newRequests   The list of Cases after an update operation.
     * @param oldMapRequests A map of Cases before the update operation, keyed by Id.
     */
    public static void updateWorkOrders(List<Case> newRequests, Map<Id, Case> oldMapRequests) {
        // List to track cases that have just been closed and meet our criteria
        List<Case> newlyClosedRequests = new List<Case>();
        
        // Identify Cases that are now closed and were previously not closed, 
        // and have Type as either 'Repair' or 'Routine Maintenance'.
        for (Case currentRequest : newRequests) {
            Case oldRequest = oldMapRequests.get(currentRequest.Id);
            Boolean justClosed = currentRequest.Status == 'Closed' && oldRequest.Status != 'Closed';
            Boolean eligibleType = (currentRequest.Type == 'Repair' || currentRequest.Type == 'Routine Maintenance');
            
            if (justClosed && eligibleType) {
                newlyClosedRequests.add(currentRequest);
            }
        }
        
        // If we have any newly closed requests that qualify, retrieve them with their related items
        if (!newlyClosedRequests.isEmpty()) {
            // Query each closed Case, including related Equipment Maintenance Items ordered by Maintenance Cycle
            Map<Id, Case> closedRequestsWithItems = new Map<Id, Case>(
                [SELECT Id, Vehicle__c,
                    (SELECT Id, Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c, Equipment__c, Quantity__c
                     FROM Equipment_Maintenance_Items__r
                     ORDER BY Equipment__r.Maintenance_Cycle__c ASC)
                 FROM Case
                 WHERE Id IN :newlyClosedRequests]
            );
            
            // Insert follow-up Routine Maintenance Requests based on these closed Cases
            insertRoutineMaintenanceRequests(closedRequestsWithItems);
        }
    }
    
    /**
     * Inserts Routine Maintenance Requests (child Cases) for the given closed Cases,
     * sets their due dates based on the minimum maintenance cycle, and clones their equipment items.
     *
     * @param closedRequests A map of closed Case records keyed by Id, each with related Equipment_Maintenance_Items__r.
     */
    private static void insertRoutineMaintenanceRequests(Map<Id, Case> closedRequests) {
        List<Case> newMaintenanceRequests = new List<Case>();
        
        // Create a new Routine Maintenance case for each closed request
        for (Case closedRequest : closedRequests.values()) {
            newMaintenanceRequests.add(createMaintenanceRequest(closedRequest));
        }
        
        // Insert all new maintenance requests at once
        insert newMaintenanceRequests;
        
        // Clone the equipment items from the closed requests to the new maintenance requests
        List<Equipment_Maintenance_Item__c> clonedItems = new List<Equipment_Maintenance_Item__c>();
        for (Case newMaintReq : newMaintenanceRequests) {
            // Retrieve the old items from the original (parent) case
            List<Equipment_Maintenance_Item__c> oldItems = closedRequests.get(newMaintReq.ParentId).Equipment_Maintenance_Items__r;
            
            // Clone each old item and link it to the new maintenance request
            for (Equipment_Maintenance_Item__c oldItem : oldItems) {
                Equipment_Maintenance_Item__c newItem = oldItem.clone();
                newItem.Maintenance_Request__c = newMaintReq.Id;
                clonedItems.add(newItem);
            }
        }
        
        // Insert all cloned equipment items
        insert clonedItems;
    }

    private static Case createMaintenanceRequest(Case closedRequest) {
        Case newMaintRequest = new Case();
        newMaintRequest.ParentId = closedRequest.Id;
        newMaintRequest.Vehicle__c = closedRequest.Vehicle__c;
        newMaintRequest.Type = 'Routine Maintenance';
        newMaintRequest.Subject = 'Routine Maintenance';
        newMaintRequest.Date_Reported__c = Date.today();
        
        // Attempt to set the Date_Due__c based on the first item’s maintenance cycle.
        // If there's no item or an error occurs, we just skip setting Date_Due__c.
        try {
            Integer minMaintCycle = (Integer)closedRequest.Equipment_Maintenance_Items__r[0].Equipment__r.Maintenance_Cycle__c;
            newMaintRequest.Date_Due__c = Date.today().addDays(minMaintCycle);
        } catch (Exception e) {
            System.debug('Cannot add Date Due: ' + e.getMessage());
        }
        return newMaintRequest;
    }
}