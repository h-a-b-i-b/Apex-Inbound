@IsTest(SeeAllData=true)
private class ProductZoningServiceTest{

    @isTest
    static void testValidProductZones(){
        // Create a mock request and response
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        req.addParameter('ProductCode', 'GC1060');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();

        // Set the request and response in the context
        RestContext.request = req;
        RestContext.response = res;

        
        // Call the method to test
        List<String> result = ProductZoningService.doGet();
        
        // Assert the response
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        System.assertNotEquals(null, result, 'Expected non-null result');
        System.assertEquals('Regulated', result[0], 'Expected fly zone to match');
    }

    @isTest
    static void testMissingProductCode() {
        // Create request without ProductCode
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        List<String> result = ProductZoningService.doGet();

        System.assertEquals(1, result.size(), 'Expected one error message');
        System.assertEquals('ProductCode is missing or doesn\'t exist', result[0], 'Expected error message for missing product code');
    }

    @isTest
    static void testInvalidProductCode() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        req.addParameter('ProductCode', 'INVALID_CODE');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        List<String> result = ProductZoningService.doGet();
        
        System.assertEquals(1, result.size(), 'Expected one error message');
        System.assertEquals('ProductCode is missing or doesn\'t exist', result[0], 'Expected error message for invalid product code');
    }

    @isTest
    static void testCheckLocalAuthorities() {

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'DE');
        req.addParameter('ProductCode', 'IN7080');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        List<String> result = ProductZoningService.doGet();
        
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        System.assertEquals(1, result.size(), 'Expected one result');
        System.assertEquals('Confirm with the local authorities', result[0], 'Expected local authorities message');
    }

    @isTest
    static void testDifferentCountryCode() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'CA');  // Testing with Canada
        req.addParameter('ProductCode', 'GC1060');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        List<String> result = ProductZoningService.doGet();
        
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        System.assertNotEquals(null, result, 'Expected non-null result');
    }

    @isTest
    static void testMissingCountryCode() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addParameter('ProductCode', 'GC1060');
        req.addHeader('Content-Type', 'application/json');
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        List<String> result = ProductZoningService.doGet();
        
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        System.assertNotEquals(null, result, 'Expected non-null result');
        // Should default to US as per the service implementation
    }
}