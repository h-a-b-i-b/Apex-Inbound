@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
    // Service dependency: can be overridden for unit testing
    public static ProductGeoMappingService mappingService = new ProductGeoMappingService();

    @HttpGet
    global static List<String> doGet() {
        // Retrieve the REST context objects
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Initialize the list to store results
        List<String> permissibleFlyZones = new List<String>();

        // Retrieve Country Code from the header or default to US
        String countryCode = req.headers.get('CountryCode');
        if (String.isBlank(countryCode)) {
            countryCode = 'US';
        }
        
        // Get the product code from query parameter "ProductCode", then fallback to path extraction.
        String productCode = req.params.get('ProductCode');
        if (String.isBlank(productCode)) {
            permissibleFlyZones.add('ProductCode is missing or doesn\'t exist');
            return permissibleFlyZones;
        }

        System.debug('county code: ' + countryCode);
        System.debug('product code: ' + productCode);
        
        // Retrieve the Product2 record by ProductCode
        Product2 product;
        try {
            product = [SELECT Id, Family FROM Product2 WHERE ProductCode = :productCode LIMIT 1];
            System.debug('Product Family: ' + product.Family);
        } catch (QueryException qe) {
            permissibleFlyZones.add('ProductCode is missing or doesn\'t exist');
            return permissibleFlyZones;
        }

        // Get custom metadata mappings for fly zones via the mapping service
        List<Product_Geo_Mapping__mdt> productGeoMappings;

        productGeoMappings = mappingService.getMappings(product.Family, countryCode);
        
        // If no metadata records are found, return a default response
        if (productGeoMappings.isEmpty()) {
            res.statusCode = 200;
            permissibleFlyZones.add('Confirm with the local authorities');
            return permissibleFlyZones;
        }

        // Process mappings to collect permissible fly zones
        for (Product_Geo_Mapping__mdt mapping : productGeoMappings) {
            String flyZone = mapping.Permissible_Fly_Zone__c;
            if (!String.isBlank(flyZone)) {
                permissibleFlyZones.add(flyZone);
            }
        }
        
        // Optional: set a success status code (e.g., 200) explicitly
        res.statusCode = 200;
        return permissibleFlyZones;
    }  
}