public class AccountTriggerHandler {
    public static final Map<String, String> RECORD_TYPE_PREFIXES = new Map<String, String>{
        'Retail' => 'MED-R00',
        'Corporation' => 'MED-C00',
        'Distributor' => 'MED-D00',
        'Wholesaler' => 'MED-W00',
        'Head_Office' => 'MHQ-H00'
    };

    public static void assignAutoIncrementingAccountCodes(List<Account> insertingAccounts) {
        if (insertingAccounts.isEmpty()) return;

        Map<Id, String> recordTypeIdToName = new Map<Id, String>();
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName IN :RECORD_TYPE_PREFIXES.keySet()
        ]) {
            recordTypeIdToName.put(rt.Id, rt.DeveloperName);
        }

        Set<String> recordTypeNames = new Set<String>();
        for (Account acc : insertingAccounts) {
            if (recordTypeIdToName.containsKey(acc.RecordTypeId)) {
                recordTypeNames.add(recordTypeIdToName.get(acc.RecordTypeId));
            }
        }

        // Get settings by record type
        Map<String, AccountCodes__c> settingsByName = new Map<String, AccountCodes__c>();
        for (AccountCodes__c setting : [
            SELECT Id, Name, Code__c
            FROM AccountCodes__c
            WHERE Name IN :recordTypeNames FOR UPDATE
        ]) {
            settingsByName.put(setting.Name, setting);
        }

        Map<String, Integer> currentCounters = new Map<String, Integer>();
        Map<String, Integer> maxCounters = new Map<String, Integer>();

        for (Account acc : insertingAccounts) {
            if (acc.RecordTypeId != null && recordTypeIdToName.containsKey(acc.RecordTypeId)) {
                String recordTypeName = recordTypeIdToName.get(acc.RecordTypeId);
                String prefix = RECORD_TYPE_PREFIXES.get(recordTypeName);

                if (prefix != null && settingsByName.containsKey(recordTypeName)) {
                    Integer counter = currentCounters.containsKey(recordTypeName)
                        ? currentCounters.get(recordTypeName)
                        : (settingsByName.get(recordTypeName).Code__c == null
                            ? 0
                            : settingsByName.get(recordTypeName).Code__c.intValue());

                    counter++;
                    currentCounters.put(recordTypeName, counter);
                    maxCounters.put(recordTypeName, counter);
                    
                    acc.Account_Code__c = prefix + String.valueOf(counter).leftPad(3, '0');
                }
            }
        }

        List<AccountCodes__c> settingsToUpdate = new List<AccountCodes__c>();
        for (String rtName : maxCounters.keySet()) {
            AccountCodes__c setting = settingsByName.get(rtName);
            setting.Code__c = maxCounters.get(rtName);
            settingsToUpdate.add(setting);
        }

        if (!settingsToUpdate.isEmpty()) {
            update settingsToUpdate;
        }
    }
}