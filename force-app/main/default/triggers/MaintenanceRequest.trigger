trigger MaintenanceRequest on Case (before update, after update) {
    if (Trigger.isAfter) {
        MaintenanceRequestHelper.updateWorkOrders(Trigger.new, Trigger.oldMap);
    }
}