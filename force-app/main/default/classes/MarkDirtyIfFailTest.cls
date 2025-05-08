@IsTest
private class MarkDirtyIfFailTest {
    
    @TestSetup
    static void createTestData() {
        // Create a pilot contact
        Contact pilot = new Contact(
            LastName = 'TestPilot',
            Pilot_Rating__c = 5.0
        );
        insert pilot;
        
        // Create a Mission__c that will fail in the batch (missing Pilot__r.Pilot_Rating__c in query)
        Mission__c m = new Mission__c(
            Status__c           = 'Complete',
            Subject__c         = 'Test Mission',
            Pilot__c            = pilot.Id,
            Completion_Rating__c = 4.0,
            Overall_Rating__c    = 4.0,
            Safety_Incidents__c  = 1
        );
        insert m;
    }
    
    @IsTest
    static void testBatchErrorEventsProduceErrorLog() {
        // Start the test context so the platform event fires during stopTest()
        try {
            Test.startTest();
            Database.executeBatch(new PilotRatingBatch(), 200);
            Test.stopTest();
            // Batch Apex job executes here
        } catch(Exception e) {
            // Catch any exceptions thrown in the batch job
            System.debug('Exception caught: ' + e.getMessage());
        }

        // The batch job fires BatchApexErrorEvent if it fails, so deliver the event.
        Test.getEventBus().deliver();
        
        // After stopTest(), the standard BatchApexErrorEvent trigger should have inserted Error_Log__c
        List<Error_Log__c> logs = [
            SELECT 
                Async_Apex_Job_Id__c,
                Name,
                Job_Scope__c,
                Message__c,
                Stacktrace__c,
                Type__c,
                Location__c
            FROM Error_Log__c
        ];

        // Debug the logs for verification
        for (Error_Log__c log : logs) {
            System.debug('Log: ' + log);
            System.debug('Async_Apex_Job_Id__c: ' + log.Async_Apex_Job_Id__c);
            System.debug('Name: ' + log.Name);
            System.debug('Job_Scope__c: ' + log.Job_Scope__c);
            System.debug('Message__c: ' + log.Message__c);
            System.debug('Stacktrace__c: ' + log.Stacktrace__c);
            System.debug('Type__c: ' + log.Type__c);
            System.debug('Location__c: ' + log.Location__c);
        }
        
        // Assert that at least one log record was created
        System.assert(!logs.isEmpty(), 'Expected at least one Error_Log__c record');
        
        // Verify key fields on the first log
        Error_Log__c log = logs[0];
        System.assertEquals('PilotRatingBatch', log.Name, 'Name should match the Apex class');
        System.assert(
            log.Message__c.contains('SObject row was retrieved'),
            'Message should reference the missing‐field error'
        );
        System.assertEquals('execute', log.Location__c.toLowerCase(), 'Phase should be "execute"');
        // System.assertEquals('System.SObjectException', log.Type__c.substringBefore(':'), 'Type should indicate a batch error event');
    }
}