@IsTest
private class CredentialVerificationServiceTest {
    
    private static String activeCertNumber;
    private static String inactiveCertNumber;
    
    
    @TestSetup
    static void setupTestData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe'
        );
        insert testContact;
        
        // Create test certification record
        Certification__c cert = new Certification__c(
            Name = 'Test Certification'
        );
        insert cert;
        
        // Create active certification
        Contact_Certification__c activeCert = new Contact_Certification__c(
            Contact__c = testContact.Id,
            Certification__c = cert.Id,
            Issue_Date__c = Date.today(),
            isActive__c = true
        );
        insert activeCert;
        
        // Create inactive certification
        Contact_Certification__c inactiveCert = new Contact_Certification__c(
            Contact__c = testContact.Id,
            Certification__c = cert.Id,
            Issue_Date__c = Date.today().addMonths(-12),
            isActive__c = false
        );
        insert inactiveCert;
    }
    
    private static void setupCertNumbers() {
        if (activeCertNumber == null || inactiveCertNumber == null) {
            List<Contact_Certification__c> certs = [
                SELECT Name, isActive__c 
                FROM Contact_Certification__c 
                ORDER BY CreatedDate
            ];
            
            for (Contact_Certification__c cert : certs) {
                if (cert.isActive__c) {
                    activeCertNumber = cert.Name;
                } else {
                    inactiveCertNumber = cert.Name;
                }
            }
        }
    }
    
    @IsTest
    static void testValidActiveCertification() {
        setupCertNumbers();
        
        Test.startTest();
        String result = CredentialVerificationService.verifyCredential('Doe', activeCertNumber);
        Test.stopTest();
        
        System.assertEquals('Valid', result, 'Should return Valid for active certification');
    }
    
    @IsTest
    static void testInactiveCertification() {
        setupCertNumbers();
        
        Test.startTest();
        String result = CredentialVerificationService.verifyCredential('Doe', inactiveCertNumber);
        Test.stopTest();
        
        System.assertEquals('Needs Renewal', result, 'Should return Needs Renewal for inactive certification');
    }
    
    @IsTest
    static void testNonExistentContact() {
        setupCertNumbers();
        
        Test.startTest();
        String result = CredentialVerificationService.verifyCredential('NonExistent', activeCertNumber);
        Test.stopTest();
        
        System.assertEquals('No record found', result, 'Should return No record found for non-existent contact');
    }
    
    @IsTest
    static void testNonExistentCertification() {
        Test.startTest();
        String result = CredentialVerificationService.verifyCredential('Doe', 'INVALID-CERT');
        Test.stopTest();
        
        System.assertEquals('No record found', result, 'Should return No record found for non-existent certification');
    }
    
    @IsTest
    static void testNullInputs() {
        Test.startTest();
        String result1 = CredentialVerificationService.verifyCredential(null, 'CERT-001');
        String result2 = CredentialVerificationService.verifyCredential('Doe', null);
        String result3 = CredentialVerificationService.verifyCredential(null, null);
        Test.stopTest();
        
        System.assertEquals('No record found', result1, 'Should handle null lastName');
        System.assertEquals('No record found', result2, 'Should handle null credentialId');
        System.assertEquals('No record found', result3, 'Should handle all null inputs');
    }
    
    @IsTest
    static void testEmptyInputs() {
        Test.startTest();
        String result1 = CredentialVerificationService.verifyCredential('', 'CERT-001');
        String result2 = CredentialVerificationService.verifyCredential('Doe', '');
        String result3 = CredentialVerificationService.verifyCredential('', '');
        Test.stopTest();
        
        System.assertEquals('No record found', result1, 'Should handle empty lastName');
        System.assertEquals('No record found', result2, 'Should handle empty credentialId');
        System.assertEquals('No record found', result3, 'Should handle all empty inputs');
    }

    @IsTest
    static void testExceptionHandling() {
        // Create invalid data to force an exception
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Exception'
        );
        insert testContact;
        
        // Create certification with invalid data to trigger exception
        Contact_Certification__c invalidCert = new Contact_Certification__c(
            Contact__c = testContact.Id,
            Issue_Date__c = Date.today()
        );
        
        Test.startTest();
        try {
            // This should throw a DML exception due to missing required field
            insert invalidCert;
            String result = CredentialVerificationService.verifyCredential('Exception', invalidCert.Name);
            System.assert(false, 'Expected exception was not thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 
                'Expected required field missing exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testQueryExceptionHandling() {
        Test.startTest();
        // Force a QueryException by using an invalid SOQL query
        try {
            Database.query('SELECT Id FROM Invalid_Object__c');
            System.assert(false, 'Expected QueryException was not thrown');
        } catch (QueryException e) {
            String result = CredentialVerificationService.verifyCredential('Doe', 'INVALID');
            System.assertEquals('No record found', result, 
                'Should handle query exceptions gracefully');
        }
        Test.stopTest();
    }
}