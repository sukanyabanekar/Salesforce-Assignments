/*This class is used to get product information based on the Product and Home Country selected on Contact 
 * Also the contact should be related to case id from lightning component 
*/
public class ProductInformationController {
    @AuraEnabled
    public static map<String,map<String,String>>mapCostPerCalendar{get;set;}
    @AuraEnabled
    public static map<String,map<String,String>> mapATMFees{get;set;}
    @AuraEnabled
    public static map<String,map<String,String>>mapCardReplCost{get;set;}
    @AuraEnabled
    public static Boolean nocontactAssociated{get;set;}
    @AuraEnabled
    public static Boolean noinfofound{get;set;}
    @AuraEnabled(cacheable=true) 
    public static ProductInformationController productInformation(String caseId){
        ProductInformationController classInstance= new ProductInformationController();
        mapCostPerCalendar = new map<String,map<String,String>>();
        mapATMFees = new map<String,map<String,String>>();
        mapCardReplCost= new map<String,map<String,String>>();
        nocontactAssociated=false;
        noinfofound= true;
        //get Product and Home Country from Contact using case query
        List<Case> caseList= [SELECT Id,
                                     ContactId,
                                     Contact.Home_Country__c,
                                     Contact.Product__c
                                FROM Case 
                             WHERE Id=:caseId
                             AND ContactId <> NULL 
                             AND Contact.Product__c <> NULL
                             AND Contact.Home_Country__c <> NULL
                             LIMIT 1];
        if(caseList <> NULL && !caseList.isEmpty()){
            map<String,map<String,String>> mapPackageCost= new map<String,map<String,String>>();
            //get Product details from product using data from case
            Integer productLimit =  Limits.getLimitQueryRows() - Limits.getQueryRows();
            String countryCode= caseList[0].Contact.Home_Country__c;
            Map<String,Map<String,String>> mapCountry_Package_Cost = new Map<String,Map<String,String>>();
            for(Product_Information__mdt prodCustomMetadata : [SELECT ATM_Fee_in_other_currencies__c,
                                                                      Card_Replacement_Cost__c, 
                                                                      Cost_Per_Calendar_Month__c,
                                                                      Home_Country__c,
                                                                      Special_Packages__c
                                                               FROM Product_Information__mdt]){
                    map<String,String> mapTypeandCost= new map<String,String>();
                    String ConcateString= prodCustomMetadata.Home_Country__c+'-'+prodCustomMetadata.Special_Packages__c;
                    mapTypeandCost.put('ATM Fees', prodCustomMetadata.ATM_Fee_in_other_currencies__c);
                    mapTypeandCost.put('Card Replacement', prodCustomMetadata.Card_Replacement_Cost__c);
                    mapTypeandCost.put('Cost Calendar', prodCustomMetadata.Cost_Per_Calendar_Month__c);
                    mapPackageCost.put(ConcateString,new map<String,String>(mapTypeandCost)); // i have not checked containskey in this map as there would be only one entry in the metadata related to Country and Package
            }
            if(mapPackageCost <> NULL && !mapPackageCost.isEmpty()){
                for(Product2 productObject : [SELECT Special_Package__c
                                              FROM Product2
                                              WHERE Id=:caseList[0].Contact.Product__c 
                                              AND Home_Country__c=: countryCode
                                              AND Special_Package__c <> NULL 
                                              LIMIT :productLimit]){
               noinfofound=false;
               String concateProd = countryCode +'-'+productObject.Special_Package__c;
                   if(mapPackageCost.containsKey(concateProd)){
                       map<String,String> mapType_Cost = mapPackageCost.get(concateProd);
                       String CostCalendar= mapType_Cost.get('Cost Calendar');
                       String ATMFee= mapType_Cost.get('ATM Fees');
                       String CardReplace= mapType_Cost.get('Card Replacement');
                       mapCostPerCalendar.put(productObject.Special_Package__c,
                                              new Map<String,String>{countryCode => CostCalendar});
                       mapATMFees.put(productObject.Special_Package__c,
                                              new Map<String,String>{countryCode => ATMFee});
                       mapCardReplCost.put(productObject.Special_Package__c,
                                              new Map<String,String>{countryCode => CardReplace});
                    }
                }
            }
        }
        else{
            nocontactAssociated = true;
        }
        return classInstance;
    }
}