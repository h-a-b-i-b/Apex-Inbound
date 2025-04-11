@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
  
    @HttpGet
    global static List<String> doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        List<String> permisibleFlyZones = new List<String>();
        Product2 product = new Product2();

        // Get Country Code from the header
        String countryCode = req.headers.get('CountryCode') ?? 'US';
        // Get the Product Code from the URI
        String ProductCode = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);

        // Validate the Product Code, if it is null or empty return ProductCode is missing or doesn't exist in response.
        if (String.isBlank(ProductCode)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('ProductCode is missing or doesn\'t exist.');
            return null;
        }
        System.debug('ProductCode: ' + ProductCode);
        System.debug('CountryCode: ' + countryCode);
        
        try {
            // Get Product Family from Product2
            product = [SELECT Id, Family FROM Product2 WHERE ProductCode = :ProductCode LIMIT 1];
            System.debug('Product Family: ' + product.Family);
            
        } catch (QueryException e) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('ProductCode is missing or doesn\'t exist..');
            permisibleFlyZones.add('ProductCode is missing or doesn\'t exist...');
            return permisibleFlyZones;
        } catch (Exception e) {
            res.statusCode = 500;
            permisibleFlyZones.add('Internal Server Error');
            res.responseBody = Blob.valueOf('Internal Server Error');
            return permisibleFlyZones;
        }



        // Get the Permissible Fly Zone from Product Geo Mapping metadata
        List<Product_Geo_Mapping__mdt> productGeoMapping = [
            SELECT Id, Permissible_Fly_Zone__c 
            FROM Product_Geo_Mapping__mdt 
            WHERE Product_Family__c = :product.Family 
            AND Country_Code__c = :countryCode 
        ];

        if (productGeoMapping.isEmpty()) {
            permisibleFlyZones.add('Confirm with the local authorities');
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('Permissible Fly Zone not found');
            return permisibleFlyZones;
        }

        // Get the Permissible Fly Zone from Product Geo Mapping
        for (Product_Geo_Mapping__mdt mapping : productGeoMapping) {
            if (mapping.Permissible_Fly_Zone__c != null) {
                permisibleFlyZones.add(mapping.Permissible_Fly_Zone__c);
            } else {
                permisibleFlyZones.add('Confirm with the local authorities');
            }
        }
        
        return permisibleFlyZones;
    }
}