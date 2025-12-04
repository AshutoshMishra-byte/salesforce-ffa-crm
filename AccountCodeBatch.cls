global class AccountCodeBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> accountIds;

    // Cache maps - preserved across execute() calls
    private Map<String, String> recordTypePrefixes = new Map<String, String>{
        'Retail' => 'MED-R00',
        'Corporation' => 'MED-C00',
        'Distributor' => 'MED-D00',
        'Wholesaler' => 'MED-W00',
        'Head_Office' => 'MED-H00'
    };

    private Map<Id, String> rtIdToName = new Map<Id, String>();
    private Map<String, AccountCodes__c> settingsByName = new Map<String, AccountCodes__c>();
    private Map<String, Integer> counters = new Map<String, Integer>();
    private Map<String, Integer> maxCounters = new Map<String, Integer>();

    global AccountCodeBatch(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, RecordTypeId
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        if (scope.isEmpty()) return;

        // Only load RecordType names once
        Set<Id> newRtIds = new Set<Id>();
        for (Account a : scope) {
            if (a.RecordTypeId != null && !rtIdToName.containsKey(a.RecordTypeId)) {
                newRtIds.add(a.RecordTypeId);
            }
        }

        if (!newRtIds.isEmpty()) {
            for (RecordType rt : [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE Id IN :newRtIds
            ]) {
                rtIdToName.put(rt.Id, rt.DeveloperName);
            }
        }

        // Get required record type names
        Set<String> neededRtNames = new Set<String>();
        for (Id rtId : newRtIds) {
            String name = rtIdToName.get(rtId);
            if (recordTypePrefixes.containsKey(name)) {
                neededRtNames.add(name);
            }
        }

        // Load AccountCodes__c settings only if not already cached
        if (!neededRtNames.isEmpty()) {
            for (AccountCodes__c ac : [
                SELECT Id, Name, Code__c 
                FROM AccountCodes__c 
                WHERE Name IN :neededRtNames
            ]) {
                settingsByName.put(ac.Name, ac);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : scope) {
            if (acc.RecordTypeId == null || !rtIdToName.containsKey(acc.RecordTypeId)) continue;

            String rtName = rtIdToName.get(acc.RecordTypeId);
            String prefix = recordTypePrefixes.get(rtName);

            if (prefix == null || !settingsByName.containsKey(rtName)) continue;

            Integer current = counters.containsKey(rtName)
                ? counters.get(rtName)
                : (settingsByName.get(rtName).Code__c == null ? 0 : settingsByName.get(rtName).Code__c.intValue());

            current++;
            counters.put(rtName, current);
            maxCounters.put(rtName, current);

            accountsToUpdate.add(new Account(
                Id = acc.Id,
                Account_Code__c = prefix + String.valueOf(current).leftPad(3, '0')
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Update AccountCodes__c with maxCounters
        List<AccountCodes__c> toUpdate = new List<AccountCodes__c>();
        for (String rtName : maxCounters.keySet()) {
            if (settingsByName.containsKey(rtName)) {
                AccountCodes__c ac = settingsByName.get(rtName);
                ac.Code__c = maxCounters.get(rtName);
                toUpdate.add(ac);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}