@isTest
public with sharing class MaintenanceRequestHelperTest {
    // implement scheduled code here
    @TestSetup
    static void makeData(){
        TestFactory.createDefaultData('Closed');
    }

    @isTest
    static void testUpdateWorkOrders() {
        // get maintenance request
        List<Case> newlyClosedRequests = [SELECT Id, Vehicle__c
            FROM Case 
            WHERE Status = 'Closed' AND Type = 'Routine Maintenance'
            LIMIT 1];

        Test.startTest();
        MaintenanceRequestHelper.updateWorkOrders(newlyClosedRequests);
        Test.stopTest();
        // check whether new case has been created
        Case nextRoutineMaintenance = [SELECT Id, Vehicle__c 
            FROM Case
            WHERE ParentId = :newlyClosedRequests[0].Id];
        System.assert(nextRoutineMaintenance != null, 'Next routine maintenance has not been created');
        System.assertEquals(newlyClosedRequests[0].Vehicle__c, nextRoutineMaintenance.Vehicle__c, 'Next routine maintenance shoud point to the same vehicle');
    }
}