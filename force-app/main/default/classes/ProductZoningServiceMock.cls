@isTest
global class ProductZoningServiceMock implements HttpCalloutMock {
    private String productCode;
    private Integer statusCode;
    private String responseBody;

    public ProductZoningServiceMock(String productCode, Integer statusCode, String responseBody) {
        this.productCode = productCode;
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        // Handle different scenarios based on productCode
        switch on this.productCode {
            when 'GC1060' {
                res.setBody('{"permissibleFlyZones": ["Regulated"]}');
                res.setStatusCode(200);
            }
            when 'ABC123' {
                res.setBody('{"error": "ProductCode is missing or doesn\'t exist"}');
                res.setStatusCode(404);
            }
            when '' {
                res.setBody('{"error": "ProductCode is required"}');
                res.setStatusCode(400);
            }
            when 'ABC500' {
                res.setBody('{"error": "Internal Server Error"}');
                res.setStatusCode(500);
            }
            when else {
                // Use the constructor-provided values for custom scenarios
                res.setBody(this.responseBody);
                res.setStatusCode(this.statusCode);
            }
        }
        
        return res;
    }

    // Helper method to create mock requests
    public static void setupMockRequest(String productCode, String countryCode) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/ProductZoning/' + productCode;
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', countryCode);
        
        RestContext.request = req;
        RestContext.response = res;
    }
}