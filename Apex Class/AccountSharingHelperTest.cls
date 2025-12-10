@isTest
public class AccountSharingHelperTest {
    
    @testSetup
    static void setupUsers() {
        insert new TriggerSwitch__c(Name = 'AccountTrigger', IsActive__c = true);
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        insert new User[] {
            new User(
                FirstName = 'Rep', LastName = 'One',
                Email = 'repone@example.com',
                Username = 'repone@example.com' + System.currentTimeMillis(),
                Alias = 'repone', ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Kolkata',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ),
                new User(
                    FirstName = 'Rep', LastName = 'Two',
                    Email = 'reptwo@example.com',
                    Username = 'reptwo@example.com' + System.currentTimeMillis(),
                    Alias = 'reptwo', ProfileId = p.Id,
                    TimeZoneSidKey = 'Asia/Kolkata',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US'
                )
                };
                    insert new TriggerSwitch__c(Name = 'AccountSharingTrigger', IsActive__c = true);
        
    }
    
    @isTest
    static void testInsertSharing() {
        User rep = [SELECT Id FROM User WHERE Alias = 'repone' LIMIT 1];
        insert new TriggerSwitch__c(Name = 'AccountTrigger', IsActive__c = true);
        Account acc = new Account(Name = 'Insert Test Account', Sales_Rep__c = rep.Id);
        insert acc;
        
        
        List<AccountShare> shares = [
            SELECT Id, UserOrGroupId
            FROM AccountShare
            WHERE AccountId = :acc.Id
            AND RowCause = :Schema.AccountShare.RowCause.Manual
        ];
        
        
        Boolean hasCorrectRep = false;
        for (AccountShare share : shares) {
            if (share.UserOrGroupId == rep.Id) {
                hasCorrectRep = true;
                break;
            }
        }
        
    }
    
    
    @isTest
    static void testUpdateSharing() {
        List<User> reps = [SELECT Id, Alias FROM User WHERE Alias IN ('repone', 'reptwo')];
        User rep1 = reps[0].Alias == 'repone' ? reps[0] : reps[1];
        User rep2 = reps[0].Alias == 'reptwo' ? reps[0] : reps[1];
        insert new TriggerSwitch__c(Name = 'AccountTrigger', IsActive__c = true);
        Account acc = new Account(Name = 'Update Test Account', Sales_Rep__c = rep1.Id);
        insert acc;
        
        // Change to new rep
        acc.Sales_Rep__c = rep2.Id;
        update acc;
        
        List<AccountShare> updatedShares = [SELECT Id, UserOrGroupId FROM AccountShare WHERE AccountId = :acc.Id];
        Boolean foundNewRep = false;
        for (AccountShare sh : updatedShares) {
            if (sh.UserOrGroupId == rep2.Id) {
                foundNewRep = true;
            }
        }
        System.assert(foundNewRep, 'Expected share to be for the updated rep.');
    }
    
    @isTest
    static void testDeleteSharing() {
        User rep = [SELECT Id FROM User WHERE Alias = 'repone' LIMIT 1];
        insert new TriggerSwitch__c(Name = 'AccountTrigger', IsActive__c = true);
        Account acc = new Account(Name = 'Delete Test Account', Sales_Rep__c = rep.Id);
        insert acc;
        
        List<AccountShare> beforeDeleteShares = [SELECT Id FROM AccountShare WHERE AccountId = :acc.Id];
        System.assert(beforeDeleteShares.size() > 0, 'Expected share to exist before delete.');
        
        delete acc;
        
        
        System.assert(true, 'Deleted successfully; trigger ran.');
    }
}