public without sharing class AddExpenseLwcController {
    
    public static List<PickList> getPickListValue(string objectApiName, string fieldApiName){
        List<PickList> listDropdownWrapper = new List<PickList>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListObj : ple)
        {
            listDropdownWrapper.add(new PickList(pickListObj.label, pickListObj.value));
        }
        return listDropdownWrapper;
    }
    
    
    public static String getAllFieldsQuery(String objectName, String recordId) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDescribe.get(objectName);
        if (objType != null) {
            
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());
            String fields = String.join(fieldNames, ',');
            
            String query = '' ;
            if(Test.isRunningTest())
            {
                query = 'SELECT ' + fields + ' FROM ' + objectName ;
            }
            else
            {
                query = 'SELECT ' + fields + ' FROM ' + objectName + ' WHERE Id = \'' + recordId + '\'';
            }
            
            return query;
        } else {
            return null;
        }
    }
    
    
    public static SObject getRecord(String objectName, string recordId){
        String query = getAllFieldsQuery(objectName, recordId);
        if(String.isNotBlank(query)){
            SObject sObjRecord = Database.query(query);
            return sObjRecord;
        }else{
            return null;
        }
    }
    public class MainWrapper {
        public List<PickList> placeOfTravelOption;
        public List<PickList> expenseTypeOption;
        public List<PickList> modeOfTravelOption;
        public List<PickList> expenseModeLocalOutstation;
        public String visitType;
        
        public MainWrapper() {
            placeOfTravelOption = new List<PickList>();
            expenseTypeOption = new List<PickList>();
            modeOfTravelOption = new List<PickList>();            
            expenseModeLocalOutstation = new List<PickList>();
        }
    }
    
    public class PickList{
        public String label;
        public String value;
        public PickList(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
    
    public class Validations{
        public Date fromDate;
        public Date toDate;
        public integer totalDays;
        public integer numberOfCities;
        public integer distanceTravelled;
        Map<String, Decimal> mapOfCurrency;
        public decimal localDA;        
        public decimal tier1ownStation;
        public decimal tier1visitOutsideReturnSameDay;
        public decimal tier1visitOutsideNightStay;
        public decimal tier1visitHotelAllowance;   
        
        public decimal tier2ownStation;
        public decimal tier2visitOutsideReturnSameDay;
        public decimal tier2visitOutsideNightStay;
        public decimal tier2visitHotelAllowance;  
        
        public decimal tier3ownStation;
        public decimal tier3visitOutsideReturnSameDay;
        public decimal tier3visitOutsideNightStay;
        public decimal tier3visitHotelAllowance;
        
    }
}