@isTest
public with sharing class WarehouseSyncScheduleTest {
    // Dummy CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 3 9 ? 2042';

    @isTest
    static void testExecute() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        WarehouseSyncSchedule sch = new WarehouseSyncSchedule();
        String jobId = System.schedule('Test', CRON_EXP, sch);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2042-09-03 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('WarehouseSyncSchedule', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');

        // Check Queueable is in the job list
        jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one queueable job');
        System.assertEquals('WarehouseCalloutService', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
    }
}