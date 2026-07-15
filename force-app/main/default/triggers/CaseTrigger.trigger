trigger CaseTrigger on Case (after insert, after update) {
	if (TriggerHelper.isTriggerProcessed) {
        return;
    }
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        if (!System.isBatch() && !System.isFuture()) {
            List<Id> caseIdsToProcess = new List<Id>();
            
            for (Case newCase : Trigger.new) {
                if (newCase.Enter_to_TrueLink_now__c == 'Yes') {
                    caseIdsToProcess.add(newCase.Id);
                }
            }
            
            if (!caseIdsToProcess.isEmpty()) {
                CreateTruelinkBeneficiary batch = new CreateTruelinkBeneficiary(caseIdsToProcess);
                Database.executeBatch(batch, 80);
            }
        }
    }
    TriggerHelper.isTriggerProcessed = true;
}