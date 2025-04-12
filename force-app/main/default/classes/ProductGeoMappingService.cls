public virtual class ProductGeoMappingService {
    public virtual List<Product_Geo_Mapping__mdt> getMappings(String productFamily, String countryCode) {
        return [
            SELECT Id, Permissible_Fly_Zone__c 
            FROM Product_Geo_Mapping__mdt 
            WHERE Product_Family__c = :productFamily 
            AND Country_Code__c = :countryCode
        ];
    }
}