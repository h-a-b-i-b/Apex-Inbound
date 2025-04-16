@IsTest
private class AssetServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create a test account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        
        // Create test asset
        Asset testAsset = new Asset(
            Name = 'Test Device',
            Asset_Identifier__c = 'TEST123',
            ContactId = testContact.Id,
            AccountId = testAccount.Id
        );
        insert testAsset;
        
        // Create test insurance with comprehensive coverage
        Insurance__c activeInsurance = new Insurance__c(
            Asset__c = testAsset.Id,
            Coverage__c = 'Comprehensive',
            Active__c = true
        );
        insert activeInsurance;
    }
    
    @IsTest
    static void testReportLostDeviceWithValidCoverage() {
        // Get the test asset
        Asset testAsset = [SELECT Id, Asset_Identifier__c FROM Asset WHERE Asset_Identifier__c = 'TEST123'];
        
        // Create the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        String jsonBody = '{"assetIdentifier": "' + testAsset.Asset_Identifier__c + '"}';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        String result = AssetService.reportLostDevice(testAsset.Asset_Identifier__c);
        Test.stopTest();
        
        // Verify results
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Id = :testAsset.Id];
        Claim__c claim = [SELECT Id, Status__c, Type__c FROM Claim__c WHERE Asset__c = :testAsset.Id];
        
        System.assertNotEquals(null, result, 'Expected a claim number');
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be Lost');
        System.assertEquals('New', claim.Status__c, 'Claim status should be New');
        System.assertEquals('Loss', claim.Type__c, 'Claim type should be Loss');
    }
    
    @IsTest
    static void testReportLostDeviceWithoutCoverage() {
        // Get the test asset
        Asset testAsset = [SELECT Id, Asset_Identifier__c FROM Asset WHERE Asset_Identifier__c = 'TEST123'];
        
        // Update insurance to non-comprehensive
        Insurance__c insurance = [SELECT Id FROM Insurance__c WHERE Asset__c = :testAsset.Id];
        insurance.Coverage__c = 'Liability';
        update insurance;
        
        // Create the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        String jsonBody = '{"assetIdentifier": "' + testAsset.Asset_Identifier__c + '"}';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        String result = AssetService.reportLostDevice(testAsset.Asset_Identifier__c);
        Test.stopTest();
        
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Id = :testAsset.Id];
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :testAsset.Id];
        
        System.assertEquals('No coverage. Asset status adjusted to Lost.', result);
        System.assertEquals('Lost', updatedAsset.Status);
        System.assertEquals(0, claims.size(), 'No claim should be created');
    }
    
    @IsTest
    static void testInvalidAssetIdentifier() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        String jsonBody = '{"assetIdentifier": "INVALID_ID"}';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        String result = AssetService.reportLostDevice('INVALID_ID');
        Test.stopTest();
        
        System.assertEquals('No device found.', result);
    }

    @IsTest
    static void testInvalidTypeJsonRequest() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        String jsonBody = '"assetIdentifier": "INVALID_ID"';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        String result = AssetService.reportLostDevice('INVALID_ID');
        Test.stopTest();
        
        System.assertEquals('No device found.', result);
    }
    
    @IsTest
    static void testMalformedJsonRequest() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('invalid json');
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        String result = AssetService.reportLostDevice('');
        Test.stopTest();
        
        System.assertEquals('No device found.', result);
    }
    
    @IsTest
    static void testDuplicateClaim() {
        // Get the test asset
        Asset testAsset = [SELECT Id, Asset_Identifier__c FROM Asset WHERE Asset_Identifier__c = 'TEST123'];
        
        // Create an existing claim
        Claim__c existingClaim = new Claim__c(
            Asset__c = testAsset.Id,
            Status__c = 'New',
            Type__c = 'Loss'
        );
        insert existingClaim;
        
        // Create the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/lost';
        req.httpMethod = 'POST';
        String jsonBody = '{"assetIdentifier": "' + testAsset.Asset_Identifier__c + '"}';
        req.requestBody = Blob.valueOf(jsonBody);
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        String result = AssetService.reportLostDevice(testAsset.Asset_Identifier__c);
        Test.stopTest();
        
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :testAsset.Id];
        System.assertEquals(1, claims.size(), 'Should not create duplicate claim');
        System.assertNotEquals(null, result, 'Should return existing claim number');
    }
}