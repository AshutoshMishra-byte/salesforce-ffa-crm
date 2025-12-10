public class AccountSharingHelper {

    public static void handleSharingOnInsertUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<AccountShare> sharesToCreate = new List<AccountShare>();
        List<AccountShare> sharesToDelete = new List<AccountShare>();

        for (Account acc : newAccounts) {
            Id newRep = acc.Sales_Rep__c;
            Id oldRep = oldMap != null && oldMap.containsKey(acc.Id) ? oldMap.get(acc.Id).Sales_Rep__c : null;

            Boolean changed = (oldRep != newRep);

            
            if (changed) {
               
                if (oldRep != null) {
                    List<AccountShare> oldShares = [
                        SELECT Id FROM AccountShare
                        WHERE AccountId = :acc.Id
                        AND UserOrGroupId = :oldRep
                        AND RowCause = :Schema.AccountShare.RowCause.Manual
                    ];
                    sharesToDelete.addAll(oldShares);
                }

                
                if (newRep != null) {
                    sharesToCreate.add(createShareRecord(acc.Id, newRep));
                }
            }
        }

        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }

        if (!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }

   public static void handleSharingOnDelete(List<Account> deletedAccounts) {
    // Collect AccountId -> Sales_Rep__c mappings
    Map<Id, Id> accountToRepMap = new Map<Id, Id>();
    for (Account acc : deletedAccounts) {
        if (acc.Sales_Rep__c != null) {
            accountToRepMap.put(acc.Id, acc.Sales_Rep__c);
        }
    }

    // Query all shares in a single SOQL using AccountId + UserOrGroupId
    List<AccountShare> sharesToDelete = [
        SELECT Id, AccountId, UserOrGroupId
        FROM AccountShare
        WHERE AccountId IN :accountToRepMap.keySet()
        AND RowCause = :Schema.AccountShare.RowCause.Manual
    ];

    // Filter only the ones that match both AccountId and UserId
    List<AccountShare> filteredShares = new List<AccountShare>();
    for (AccountShare share : sharesToDelete) {
        if (accountToRepMap.containsKey(share.AccountId) &&
            accountToRepMap.get(share.AccountId) == share.UserOrGroupId) {
            filteredShares.add(share);
        }
    }

    if (!filteredShares.isEmpty()) {
        Database.delete(filteredShares, false);
    }
}


    private static AccountShare createShareRecord(Id accountId, Id userId) {
        AccountShare share = new AccountShare();
        share.AccountId = accountId;
        share.UserOrGroupId = userId;
        share.AccountAccessLevel = 'Read';
        share.OpportunityAccessLevel = 'None';
        share.CaseAccessLevel = 'None';
        share.RowCause = Schema.AccountShare.RowCause.Manual;
        return share;
    }
}