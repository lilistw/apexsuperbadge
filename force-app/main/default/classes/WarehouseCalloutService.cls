public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext context) {
        // makes a callout to the external service used for warehouse inventory management. 
        // This service receives updated values in the external system 
        // and updates the related records in Salesforce.
        // Replacement part (this should be set to true for all records that come in from the warehouse system)
        Http h = new Http();
        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('GET');
        httpReq.setHeader('Content-Type','application/json'); 
        httpReq.setEndpoint(WAREHOUSE_URL);
        HttpResponse res = h.send(httpReq);
        List<Map<String, String>> results = (List<Map<String, String>>)JSON.deserialize(res.getBody(), List<Map<String, String>>.class);
        System.debug(results.size());
        List<Product2> equipment = new List<Product2>();
        for (Map<String, String> entry : results) {
            Product2 p = new Product2();
            p.Warehouse_SKU__c = String.valueOf(entry.get('_id'));
            p.Replacement_Part__c = true;
            p.QuantityUnitOfMeasure = String.valueOf(entry.get('quantity'));
            p.Name = String.valueOf(entry.get('name'));
            p.Maintenance_Cycle__c = Decimal.valueOf(entry.get('maintenanceperiod'));
            p.Lifespan_Months__c = Decimal.valueOf(entry.get('lifespan'));
            p.Cost__c = Decimal.valueOf(entry.get('cost'));
            p.StockKeepingUnit = String.valueOf(entry.get('sku'));

            equipment.add(p);
        } 
        if (!equipment.isEmpty()) {
            upsert equipment Warehouse_SKU__c;
        }
    }
}