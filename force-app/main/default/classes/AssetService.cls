@RestResource(urlMapping='/lost')
global class AssetService {
    
    @HttpPost
    global static String reportLostDevice(String assetIdentifier) {
        
        RestRequest request = RestContext.request;
        String assetId = '';
        String claimNumber = '';
        String response = '';
        String errorMsg = 'No device found.';
        Id contactId;
        Insurance__c insurance;
        Asset asset;
        
        if (assetIdentifier != null) {
            assetId = assetIdentifier;
        }

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
        
        // Assign the contact ID from the asset
        contactId = (Id) asset.ContactId;

        List<Insurance__c> insurances = new List<Insurance__c>();

            
            insurances = [
                SELECT Id, Asset__c, Active__c, Coverage__c 
                FROM Insurance__c
                WHERE Asset__c = :asset.Id 
                AND Active__c = true
            ];
        if (insurances.isEmpty()) {
            // Updates the asset status to 'Lost'
            updateAssets(asset);
            return 'No coverage. Asset status adjusted to Lost.';
        } 
        insurance = insurances[0];
        
        // Creates a claim record if there is an active comprehensive insurance coverage
        if (insurance != null && insurance.Coverage__c == 'Comprehensive' && insurance.Active__c) {
            // Updates the asset status to 'Lost'
            updateAssets(asset);

            claimNumber = createClaimRecord(asset.Id, contactId, insurance.Id);
        } else {
            // Updates the asset status to 'Lost'
            updateAssets(asset);
            return 'No coverage. Asset status adjusted to Lost.';
        }

        response = claimNumber;
        
        return response;
    }
    
    // Helper method to updates the asset status to 'Lost'
    private static void updateAssets(Asset asset) {
        
        if (asset != null) {
            asset.Status = 'Lost';
            update asset;
        } else {
            System.debug('No asset found with the given identifier.');
        }
    }
    
    // Helper method to get the asset identifirer
    // private static String getAssetIdentifier(RestRequest request) {

    //     Map<String, Object> requestbody = new Map<String, Object>();
    //     try{    
    //         // Deserialize the JSON string into name-value pairs
    //         requestbody = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
    //     } catch (JSONException e) {
    //         System.debug('Error deserializing JSON request body: ' + e.getMessage());
    //         return null;
    //     } catch (TypeException e) {
    //         System.debug('Error deserializing JSON request body: ' + e.getMessage());
    //         return null;
    //     }
        
    //     String assetIdentifier = (String)requestbody?.get('assetIdentifier');
        
    //     return assetIdentifier ?? null;
    // }
    
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
            return existingClaims[0].Name + ' already filed.';
        }

        // Create a new claim record
        Claim__c claim = new Claim__c();
        claim.Asset__c = assetId;
        claim.Status__c = 'New';
        claim.Type__c = 'Loss';
        claim.Contact__c = contactId;
        claim.Insurance__c = insuranceId;
        
        // Insert the claim record
        insert claim;

        // Re-query the inserted record to get the auto-numbered Name
        claim = [SELECT Name FROM Claim__c WHERE Id = :claim.Id];

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