@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
    @isTest
    static void testExecute() {
        List<Product2> equipment = [SELECT Id FROM Product2];
        System.assert(equipment.isEmpty(), 'Equipment already exists');
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        WarehouseCalloutService wcs = new WarehouseCalloutService();
        Id jobId = System.enqueueJob(wcs);
        Test.stopTest();
        // Validate that the job has run
        // by verifying that the records were created.
        equipment = [SELECT Id FROM Product2];
        System.assert(!equipment.isEmpty(), 'No equipment has been imported');
    }
}