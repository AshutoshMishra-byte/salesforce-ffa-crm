public class AchievedCollectionTriggerHandler {

    public static Boolean isTriggerActive() {
        TriggerSwitch__c setting = TriggerSwitch__c.getInstance('AchievedCollectionTrigger');
        return setting != null && setting.IsActive__c;
    }

    public static void beforeInsert(List<Achieved_Collection__c> newList) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> salesRepIds = new Set<Id>();
        Set<String> monthSet = new Set<String>();
        Set<String> yearSet = new Set<String>();

        for (Achieved_Collection__c ac : newList) {
            if (ac.Received_Date__c != null && ac.Account_Name__c != null && ac.Sales_Rep__c != null) {
                accountIds.add(ac.Account_Name__c);
                salesRepIds.add(ac.Sales_Rep__c);

                DateTime dt = DateTime.newInstance(ac.Received_Date__c, Time.newInstance(0, 0, 0, 0));
                String month = dt.format('MMMM').toLowerCase();
                String year = String.valueOf(ac.Received_Date__c.year());

                monthSet.add(month);
                yearSet.add(year);
            }
        }

        List<Collection__c> collectionList = [
            SELECT Id, OwnerId, Account__c, Month__c, Year__c
            FROM Collection__c
            WHERE Account__c IN :accountIds
              AND OwnerId IN :salesRepIds
              AND Month__c IN :monthSet
              AND Year__c IN :yearSet
        ];

        Map<String, Id> collectionKeyToIdMap = new Map<String, Id>();
        for (Collection__c col : collectionList) {
            String key = col.Account__c + '-' + col.OwnerId + '-' + col.Month__c.toLowerCase() + '-' + col.Year__c;
            collectionKeyToIdMap.put(key, col.Id);
        }

        for (Achieved_Collection__c ac : newList) {
            if (ac.Received_Date__c != null && ac.Account_Name__c != null && ac.Sales_Rep__c != null) {
                DateTime dt = DateTime.newInstance(ac.Received_Date__c, Time.newInstance(0, 0, 0, 0));
                String month = dt.format('MMMM').toLowerCase();
                String year = String.valueOf(ac.Received_Date__c.year());

                String key = ac.Account_Name__c + '-' + ac.Sales_Rep__c + '-' + month + '-' + year;

                if (collectionKeyToIdMap.containsKey(key)) {
                    ac.Collection__c = collectionKeyToIdMap.get(key);
                } else {
                    ac.addError('No matching Collection found for Received Date, Account, and Sales Rep.');
                }
            } else {
                ac.addError('Missing required field(s): Received Date, Account, or Sales Rep.');
            }
        }
    }
}