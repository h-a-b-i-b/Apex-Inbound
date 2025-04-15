@RestResource(urlMapping='/lost')
global class AssetService extends a{
    
    @HttpGet
    global static String reportLostDevice(){
        
        RestRequest request = RestContext.request;
        String assetId = '';
        String claimNumber = '';
        String response = '';
        String errorMsg = 'No device found.';
        Id contactId;
        Insurance__c insurance;
        Asset asset;
        
        // Get the asset identifier from the request
        assetId = getAssetIdentifier(request);

        // check if the asset identifier is null or empty
        if (String.isBlank(assetId)) {
            System.debug('Asset identifier is null or empty.');
            return errorMsg;
        }
        try {
            asset = queryAssets(assetId);
        } catch (QueryException e) {
            System.debug('Error querying asset: ' + e.getMessage());
            return errorMsg;
        }

        if (asset != null) {
            contactId = (Id) asset.ContactId;
            insurance = asset.Insurances__r[0];
        } else {
            System.debug('No asset found with the given identifier.');
            return errorMsg;
        }

        // log the asset details
        log(asset);
        log(contactId);
        log(insurance);

        // Updates the asset status to 'Lost'
        updateAssets(asset);
        
        // Creates a claim record if there is an active comprehensive insurance coverage
        if (insurance != null && insurance.Coverage__c == 'Comprehensive' && insurance.Active__c) {
            claimNumber = createClaimRecord(asset.Id, contactId, insurance.Id);

            // log the claim number
            log(claimNumber);
        }
        // log the claim number
        log(claimNumber);

        response = claimNumber;
        
        return response;
    }
    
    // Helper method to updates the asset status to 'Lost'
    private static void updateAssets(Asset asset) {
        
        if (asset != null) {
            asset.Status = 'Lost';
            try {
                update asset;
            } catch (DmlException e) {
                System.debug('Error updating asset status: ' + e.getMessage());
            }
        } else {
            System.debug('No asset found with the given identifier.');
        }
    }
    
    // Helper method to get the asset identifirer
    private static String getAssetIdentifier(RestRequest request) {

        Map<String, Object> requestbody = new Map<String, Object>();
        try{    
            // Deserialize the JSON string into name-value pairs
            requestbody = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        } catch (JSONException e) {
            System.debug('Error deserializing JSON request body: ' + e.getMessage());
            return null;
        } 
        
        // Log the request body
        log(requestbody);
        
        // Check if the assetIdentifier is provided in request body or empty
        if(requestbody == null || requestbody.isEmpty()) {
            System.debug('Request body is empty or null.');
            return null;
        }
        String assetIdentifier = (String)requestbody.get('assetIdentifier');
        
        if (String.isBlank(assetIdentifier)) {
            return null;
        }
        return assetIdentifier;
    }
    
    // Helper method to create a claim record
    private static String createClaimRecord(String assetId, Id contactId, Id insuranceId) {

        // Check if claim with type 'Loss' already exists
        List<Claim__c> existingClaims = [
            SELECT Id, Name 
            FROM Claim__c 
            WHERE Asset__c = :assetId 
            AND Type__c = 'Loss' 
            AND Status__c != 'Closed'
        ];
        if (!existingClaims.isEmpty()) {
            System.debug('Claim already exists for this asset.');
            return existingClaims[0].Name;
        }

        // Create a new claim record
        Claim__c claim = new Claim__c();
        claim.Asset__c = assetId;
        claim.Status__c = 'New';
        claim.Type__c = 'Loss';
        claim.Contact__c = contactId;
        claim.Insurance__c = insuranceId;
        
        // Insert the claim record
        try {
            insert claim;
    
            // Re-query the inserted record to get the auto-numbered Name
            claim = [SELECT Name FROM Claim__c WHERE Id = :claim.Id];
    
            // Log the claim name
            log(claim);
    
        } catch (DmlException e) {
            System.debug('Error creating claim record: ' + e.getMessage());
            return null;
        }
        return claim.Name;
    }

    // Helper method to query the asset
    private static Asset queryAssets(String assetId) {
        return [
            SELECT Id, Asset_Identifier__c, Name, Status, ContactId, (
                SELECT Id, Asset__c, Active__c, Coverage__c 
                FROM Insurances__r) 
            FROM Asset 
            WHERE Asset_Identifier__c = :assetId
        ];
    }
}