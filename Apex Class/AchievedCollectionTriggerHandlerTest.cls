@isTest
public class AchievedCollectionTriggerHandlerTest {
    @isTest
    static void testBeforeInsert_PopulatesCollection_WithTriggerSwitch() {
        // Turn OFF AccountTrigger and ON AchievedCollectionTrigger
        insert new TriggerSwitch__c(Name = 'AccountTrigger', IsActive__c = false);
        insert new TriggerSwitch__c(Name = 'AchievedCollectionTrigger', IsActive__c = true);

        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User salesRep = new User(
            FirstName = 'Test',
            LastName = 'Rep',
            Email = 'salesrep@example.com',
            Username = 'salesrep' + DateTime.now().getTime() + '@test.com',
            Alias = 'srep',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert salesRep;

        // Create account
        Account acc = new Account(Name = 'Test Account', Sales_Rep__c = salesRep.Id );
        insert acc;

        // Create collection record for July 2025
        Collection__c collection = new Collection__c(
            Month__c = 'July',
            Year__c = '2025',
            Account__c = acc.Id,
            OwnerId = salesRep.Id
        );
        insert collection;

        // One record that should find matching collection
        Achieved_Collection__c ac1 = new Achieved_Collection__c(
            Received_Date__c = Date.newInstance(2025, 7, 10),
            Account_Name__c = acc.Id,
            Sales_Rep__c = salesRep.Id
        );

        // One record that should NOT find matching collection
        Achieved_Collection__c ac2 = new Achieved_Collection__c(
            Received_Date__c = Date.newInstance(2025, 8, 5),
            Account_Name__c = acc.Id,
            Sales_Rep__c = salesRep.Id
        );

        Test.startTest();
        Database.SaveResult[] results = Database.insert(new List<Achieved_Collection__c>{ ac1, ac2 }, false);
        Test.stopTest();

        // First record should succeed
        System.assertEquals(true, results[0].isSuccess(), 'First record should succeed');
        Achieved_Collection__c inserted = [SELECT Collection__c FROM Achieved_Collection__c WHERE Id = :ac1.Id];
        System.assertNotEquals(null, inserted.Collection__c, 'Collection__c should be populated');
    }
}