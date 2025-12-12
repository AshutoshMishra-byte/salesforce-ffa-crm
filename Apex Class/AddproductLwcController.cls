public class  AddproductLwcController {
    @AuraEnabled(cacheable=true)    
    public static List<Product__c> getProductRecords(string recordId,String searchKeys) {
        system.debug('recordId======='+recordId);
        if(searchKeys == null || searchKeys ==''){ 
            Map<String,Order_Line_item__c> enqItemIdMap = new Map<String,Order_Line_item__c>();
            List<Sales_order__c> enqList = new List<Sales_order__c>();
            List<Order_Line_item__c> enqItemList = [Select Id, Product__c,Quantity__c	
                                                 from Order_Line_item__c where Sales_order__c =:recordId];
            List<Product__c> proReturnList = new List<Product__c>();
            for(Order_Line_item__c objEnqItem : enqItemList){
                enqItemIdMap.put(objEnqItem.Product__c,objEnqItem);
            }
            List<Product__c> proList = [Select Id,Name, Quantity__c From Product__c ];
            for(Product__c objProduct : proList){
                if(!enqItemIdMap.containsKey(objProduct.id)){
                    proReturnList.add(objProduct);
                }   
            }
            return proReturnList;
        }else{
            string keys='%'+searchKeys+'%';
            Map<String,Order_Line_item__c> enqItemIdMap1 = new Map<String,Order_Line_item__c>();
            List<Sales_order__c> enqList = new List<Sales_order__c>();
            List<Order_Line_item__c> enqItemList1 = [Select Id, Quantity__c , Product__c	from Order_Line_item__c where Sales_order__c =:recordId];
            List<Product__c> proReturnList1 = new List<Product__c>();
            for(Order_Line_item__c objEnqItem1 : enqItemList1){
                enqItemIdMap1.put(objEnqItem1.Product__c,objEnqItem1);
            }
            List<Product__c> proList1 = [Select Id,Name, Quantity__c From Product__c WHERE Name LIKE :keys];
            for(Product__c objProduct1 : proList1){
                if(!enqItemIdMap1.containsKey(objProduct1.id)){
                    proReturnList1.add(objProduct1);
                }   
            }
            return proReturnList1;
        }
    }
     @AuraEnabled
    public static List<Order_Line_item__c> getEnqItemRecords() {
        List<Order_Line_item__c> enqList = [Select Id,Quantity__c From Order_Line_item__c];
        return enqList;
    }
    public class MainWrapper{
        @AuraEnabled   public list<DropDownWrapper> dropDownList;
    }
    public class DropDownWrapper{
        public string label;
        public string fieldName;
        public Boolean editable;
        
    }
}