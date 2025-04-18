global with sharing class CredentialVerificationService {
    
    webservice static String verifyCredential(String contactLastName, String credentialId) {
        try {
            // Input validation
            if (String.isBlank(credentialId) || String.isBlank(contactLastName)) {
                System.debug('Credential ID or contactLastName is null or empty.');
                return 'No record found';
            }
            
            // Sanitize inputs
            contactLastName = String.escapeSingleQuotes(contactLastName.trim());
            credentialId = String.escapeSingleQuotes(credentialId.trim());
            
            // Query the contact case-insensitive
            List<Contact> contacts = [
                SELECT Id, LastName 
                FROM Contact 
                WHERE LastName = :contactLastName 
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                System.debug('No contact found with the last name: ' + contactLastName);
                return 'No record found';
            }
            
            // Query certifications
            List<Contact_Certification__c> certifications = [
                SELECT Id, Name, isActive__c, Contact__c 
                FROM Contact_Certification__c 
                WHERE Name = :credentialId 
                AND Contact__c = :contacts[0].Id 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            if (certifications.isEmpty()) {
                return 'No record found';
            }

            return certifications[0].isActive__c ? 'Valid' : 'Needs Renewal';
            
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return 'Error processing request';
        }
    }
}