@isTest
private class ProductZoningServiceTest {

    @isTest 
    static void testGetCaseById() {
        // Set up a test request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ProductZoning/GC1060';
        request.addHeader('CountryCode', 'US');
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'GET';
        RestContext.request = request;

        // Set up a test response
        RestResponse response = new RestResponse();
        response.statusCode = 200;
        RestContext.response = response;

        // Call the method to test
        List<String> res = ProductZoningService.doGet();
        
        // Verify the response
        System.debug('Response: ' + res);
    }
}