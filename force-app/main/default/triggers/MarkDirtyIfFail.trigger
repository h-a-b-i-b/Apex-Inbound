trigger MarkDirtyIfFail on BatchApexErrorEvent (after insert) {

    System.debug('MarkDirtyIfFail Trigger');

    Set<Id> asyncApexJobIds = new Set<Id>();
    for(BatchApexErrorEvent evt:Trigger.new){
        asyncApexJobIds.add(evt.AsyncApexJobId);
    }
    
    Map<Id,AsyncApexJob> jobs = new Map<Id,AsyncApexJob>(
        [SELECT id, ApexClass.Name FROM AsyncApexJob WHERE Id IN :asyncApexJobIds]
    );
    
    List<Error_Log__c> errorLogs = new List<Error_Log__c>();
    for(BatchApexErrorEvent evt:Trigger.new){

        // debugging
        System.debug('AsyncApexJobId: ' + evt.AsyncApexJobId);
        System.debug('JobScope: ' + evt.JobScope);
        System.debug('Message: ' + evt.Message);
        System.debug('StackTrace: ' + evt.StackTrace);
        System.debug('ExceptionType: ' + evt.ExceptionType);
        System.debug('Phase: ' + evt.Phase);
        System.debug('ApexClass.Name: ' + jobs.get(evt.AsyncApexJobId).ApexClass.Name);

        //only handle events for the job(s) we care about
        if(jobs.get(evt.AsyncApexJobId).ApexClass.Name == 'PilotRatingBatch'){
            // for (String item : evt.JobScope.split(',')) {
            Error_Log__c a = new Error_Log__c(
                Async_Apex_Job_Id__c = evt.AsyncApexJobId,
                Name = 'PilotRatingBatch',
                Job_Scope__c = evt.JobScope,
                Message__c = evt.Message,
                Stacktrace__c = evt.StackTrace,
                Type__c = evt.ExceptionType,
                Location__c = evt.Phase
            );
            errorLogs.add(a);
            // }
        }
    }
    insert errorLogs;
}