@RestResource(urlMapping='/lost')
global class AssetService extends a{
    
    @HttpGet
    global static String reportLostDevice(){
        
        RestRequest request = RestContext.request;
        String assetIdentifier = '';
        
        // Get the asset identifier from the request
        assetIdentifier = getAssetIdentifier(request);
        
        // Updates the asset status to 'Lost'
        updateAssets(assetIdentifier);
        
        // Creates a claim record if there is an active comprehensive insurance coverage
        
        
        
        // Return a success message
        return 'Asset with ID ' + assetIdentifier + ' has been reported as lost.';
    }
    
    // Helper method to updates the asset status to 'Lost'
    private static void updateAssets(String assetId) {
        List<Asset> assets = [SELECT Id, Asset_Identifier__c, Name, Status FROM Asset WHERE Asset_Identifier__c = :assetId];
        
        if (assets.size() > 0) {
            for (Asset asset : assets) {
                asset.Status = 'Lost';
            }
            update assets;
        } else {
            System.debug('No assets found with the given ID');
        }
    }
    
    // Helper method to get the asset identifirer
    private static String getAssetIdentifier(RestRequest request) {
        
        // Deserialize the JSON string into name-value pairs
        Map<String, Object> requestbody = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        
        // Log the request body
        log(requestbody);
        
        // Extract the asset identifier from the request body
        String assetIdentifier = (String)requestbody.get('assetIdentifier');
        
        if (String.isBlank(assetIdentifier)) {
            return null;
        }
        return assetIdentifier;
    }
    
    // Helper method to create a claim record
    private static String createClaimRecord(String assetId, Id contactId, Id insuranceId) {
        Claim__c claim = new Claim__c();
        claim.Asset__c = assetId;
        claim.Status__c = 'New';
        claim.Type__c = 'Loss';
        claim.Contact__c = contactId;
        claim.Insurance__c = insuranceId;
        
        // Insert the claim record
        try {
            insert claim;
        } catch (DmlException e) {
            System.debug('Error creating claim record: ' + e.getMessage());
            return null;
        }
        return claim.Name;
    }
}