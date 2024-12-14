@isTest
public with sharing class MaintenanceRequestTriggerTest {
    @TestSetup
    static void makeData(){
        TestFactory.createDefaultData('New');
    }

    @isTest
    static void testMaintenanceRequestClosed() {
        // get maintenance request
        Case maintenanceRequest = [SELECT Id, Vehicle__c
            FROM Case 
            WHERE Status != 'Closed' AND Type = 'Routine Maintenance'
            LIMIT 1];

        Test.startTest();
        maintenanceRequest.status = 'Closed';
        update maintenanceRequest;
        Test.stopTest();
        // check whether new case has been created
        Case nextRoutineMaintenance = [SELECT Id, Vehicle__c 
            FROM Case
            WHERE ParentId = :maintenanceRequest.Id];
        System.assert(nextRoutineMaintenance != null, 'Next routine maintenance has not been created');
        System.assertEquals(MaintenanceRequest.Vehicle__c, nextRoutineMaintenance.Vehicle__c, 'Next routine maintenance shoud point to the same vehicle');
    }
}