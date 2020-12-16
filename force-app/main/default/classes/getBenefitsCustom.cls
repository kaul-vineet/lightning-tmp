global class getBenefitsCustom implements Database.Batchable<sObject>, Database.stateful {

  private Integer counterSS = 0;
  
  global Integer recordsProcessed = 0;
  global Map<Integer, Scheme_Slab__c> Scheme_Slab = new Map<Integer, Scheme_Slab__c>();
  global Map<Integer, List<Entitlement__c>> Entitlement = new Map<Integer, List<Entitlement__c>>();
  global Map<Id, Entitlement_article__c> Entitlement_article = new Map<Id, Entitlement_article__c>();
  global Scheme__c schemeProcessed; 
   
  global String setMultiSelect (String value, String new_value)
  {
      if (String.isNotEmpty(value))
      {
          value = value + ';' + new_value;
          return value;
      }
      else
      {
          return new_value;
      }
  }
  global getBenefitsCustom (Id schemeId){
    List<Id> entilement_article_Ids= new List<Id>();
    List<Entitlement__c> entitlement_for_slab = new List<Entitlement__c>();
    
    schemeProcessed = [SELECT  Title__c,  Product_Group__c,  Start_Date__c,  End_Date__c FROM Scheme__c WHERE Id =:schemeId];
    
    counterSS = 0;
    for(Scheme_Slab__c objSS : [Select Id, Lower_Limit_Volume__c, Upper_Limit_Volume__c From Scheme_Slab__c WHERE Scheme__c =:schemeId]){
        Scheme_Slab.put(counterSS, objSS); 
        System.debug('>>>> SCHEME SLAB INITIATION ' + Scheme_Slab);
        entitlement_for_slab = [SELECT  Entitlement_Article__c,  Early_Bird__c,  Early_Bird_End_Date__c,  Scheme_Slab__c FROM Entitlement__c WHERE Scheme_Slab__c = :Scheme_Slab.get(counterSS).Id];
        Entitlement.put(counterSS,entitlement_for_slab);
        
        for(Entitlement__c  idValue : entitlement_for_slab){
            entilement_article_Ids.add(idValue.Entitlement_Article__c);
         }
         
         for(Entitlement_Article__c objEA : [SELECT  Name,  Article_Type__c,  Compensation__c,  Goods__c FROM Entitlement_article__c WHERE Id IN :entilement_article_Ids]){
             Entitlement_article.put(objEA.Id, objEA);
         }
     counterSS = counterSS + 1;     
     } 
  }
  
  // The batch job starts 
  global Database.Querylocator start(Database.BatchableContext bc){
    String soql = 'SELECT  Date__c,  Product_Group__c,  Amount__c, Incentive_Value__c, Incentive_Goods__c, Distributor__c FROM TPM_Sales_Summary__c WHERE Date__c >= ' +  String.ValueOf(schemeProcessed.Start_Date__c).left(10)  + 
    ' AND Date__c <= ' + String.ValueOf(schemeProcessed.End_Date__c).left(10) +  
    ' AND Product_Group__c = ' + '\'' + schemeProcessed.Product_Group__c + '\'';
    
    System.debug('SOQL ' + soql);
    
    //String soql = 'SELECT  Date__c, Distributor__c, Product_Group__c,  Amount__c, Incentive_Value__c, Incentive_Goods__c FROM TPM_Sales_Summary__c WHERE Product_Group__c = ' + '\'' + schemeProcessed.Product_Group__c + '\''; //+ ' LIMIT 40000';
    System.debug('>>>> execute ' + soql);
    return Database.getQuerylocator(soql);
    } 
  
  // The batch job executes and operates on one batch of records
  global void execute(Database.BatchableContext bc, List<TPM_Sales_Summary__c> scope){
    Decimal Calculated_Incentive_Value;
    List<Id> Qualified_Distributor_List = new List<Id>();
    TPM_Incentives__c Incentive_Updates;
    Map<Id, TPM_Incentives__c> Qualified_Entitlement = new Map<Id, TPM_Incentives__c>(); 
    
    for(TPM_Sales_Summary__c qualified_orders : scope)
     {
        qualified_orders.Incentive_Value__c = 0;
        qualified_orders.Incentive_Goods__c = '';
        Calculated_Incentive_Value = 0;
        // Create a distinct 
        if (!Qualified_Distributor_List.contains(qualified_orders.Distributor__c))
        {
            Qualified_Distributor_List.add(qualified_orders.Distributor__c);
        }
        //System.debug('>>>> QUALIFIED DEALERS ' + Qualified_Distributor_List);
        //System.debug('>>>> SCHEME SLAB ' + Scheme_Slab);
        for (Integer key : Scheme_Slab.keySet())
        {
            //System.debug ('ID ' + qualified_orders.Id + ' has $' + qualified_orders.Amount__c + ' inv. amount with slab lower: ' + Scheme_Slab.get(key).Lower_Limit_Volume__c + ' and slab higher' + Scheme_Slab.get(key).Upper_Limit_Volume__c); 
            if (qualified_orders.Amount__c >= Scheme_Slab.get(key).Lower_Limit_Volume__c && qualified_orders.Amount__c <= Scheme_Slab.get(key).Upper_Limit_Volume__c)
            {
                 for (Entitlement__c current_entitlement : Entitlement.get(key))
                 {
                     if ((current_entitlement.Early_Bird__c == false) || (current_entitlement.Early_Bird__c == true && qualified_orders.Date__c <= current_entitlement.Early_Bird_End_Date__c))
                     {
                         if (Entitlement_article.get(current_entitlement.Entitlement_Article__c).Article_Type__c == 'Compensation')
                         {
                             // compensation processing:
                             Calculated_Incentive_Value = Calculated_Incentive_Value + (qualified_orders.Amount__c * (Entitlement_article.get(current_entitlement.Entitlement_Article__c).Compensation__c)/100);
                             qualified_orders.Incentive_Value__c = Calculated_Incentive_Value;
                             qualified_orders.Incentive_Goods__c = setMultiSelect(qualified_orders.Incentive_Goods__c, Entitlement_article.get(current_entitlement.Entitlement_Article__c).Name);
                             System.debug ('ID ' + qualified_orders.Id + ' has $' + qualified_orders.Incentive_Value__c);       
                         }
                         else
                         {
                             // non-compensation processing:
                             qualified_orders.Incentive_Goods__c = setMultiSelect(qualified_orders.Incentive_Goods__c, Entitlement_article.get(current_entitlement.Entitlement_Article__c).Name);
                         } 
                     }
                 }
            }
        }
     }
     
     for (TPM_Incentives__c objCS : [SELECT Id, Incentive_Value__c, Incentive_Goods__c, Invoice_Amount__c, Distributor__c FROM TPM_Incentives__c WHERE  Scheme__c =: schemeProcessed.Id AND Distributor__c IN :Qualified_Distributor_List]){
         objCS.Incentive_Goods__c = '';
         objCS.Incentive_Value__c = 0;
         objCS.Invoice_Amount__c = 0;
         Qualified_Entitlement.put(objCS.Distributor__c, objCS);
     }
        
     //System.debug('>>>> Size Of Qualified Entitlement (TPM_Incentives__c) ' + Qualified_Entitlement.size());
     if (!Qualified_Entitlement.isEmpty())
     {
         //System.debug('>>>> Qualified Entitlement (TPM_Incentives__c) IS NOT EMPTY');
         for(TPM_Sales_Summary__c qualified_orders : scope)  
         {
             if (Qualified_Entitlement.containsKey(qualified_orders.Distributor__c))
             {
                 System.debug('>>>> Qualified Entitlement (TPM_Incentives__c) UNDER PROCESS ' + Qualified_Entitlement.get(qualified_orders.Distributor__c));
                 Incentive_Updates = Qualified_Entitlement.get(qualified_orders.Distributor__c);
                 Incentive_Updates.Incentive_Value__c = Incentive_Updates.Incentive_Value__c + qualified_orders.Incentive_Value__c;
                 Incentive_Updates.Invoice_Amount__c = Incentive_Updates.Invoice_Amount__c + qualified_orders.Amount__c;
                 System.debug('>>>> AMOUNT FOR DIS ' + Incentive_Updates.Distributor__c + ' IS ' + Incentive_Updates.Invoice_Amount__c );
                 
                 
                 if(String.isEmpty(Incentive_Updates.Incentive_Goods__c))
                 {
                     Incentive_Updates.Incentive_Goods__c = '';
                 }
                 
                 
                 //Incentive_Updates.Incentive_Goods__c = '';
                 System.debug('>>>> COMPARISON -OUT ' + Incentive_Updates.Incentive_Goods__c + '*--*' + qualified_orders.Incentive_Goods__c);
                 System.debug('>>>> RESULT -OUT ' + Incentive_Updates.Incentive_Goods__c.contains(qualified_orders.Incentive_Goods__c));
                
                
                 List<String> multi_select_element = qualified_orders.Incentive_Goods__c.split(';');
                 for(String element : multi_select_element)
                 {
                    if (!Incentive_Updates.Incentive_Goods__c.contains(element))
                     {
                         System.debug('>>>> COMPARISON -IN' + Incentive_Updates.Incentive_Goods__c + '*--*' + element);
                         System.debug('>>>> RESULT -IN' + Incentive_Updates.Incentive_Goods__c.contains(element));
                         Incentive_Updates.Incentive_Goods__c = setMultiSelect(Incentive_Updates.Incentive_Goods__c, element);
                     }
                 }
                 
                 Qualified_Entitlement.remove(qualified_orders.Distributor__c);
                 Qualified_Entitlement.put(qualified_orders.Distributor__c, Incentive_Updates);
             }
         }
         
         Database.SaveResult[] lsr = Database.update(Qualified_Entitlement.values());
         for (Database.SaveResult SR : lsr) {
            if (!SR.isSuccess()) {
                System.debug('Record:' + SR.getErrors()[0].getMessage() + '<br/>');
            }
         }
     }

     update (scope);
     recordsProcessed  = recordsProcessed  + scope.size();
  }
  // The batch job finishes
  global void finish(Database.BatchableContext bc){
  // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.    
  // Query the AsyncApexJob object to retrieve the current job's information.  

      AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors, JobItemsProcessed,
      TotalJobItems, CreatedBy.Email
      from AsyncApexJob where Id =:BC.getJobId()];
        
       
       
      // Send an email to the Apex job's submitter notifying of job completion.  
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      String[] toAddresses = new String[] {a.CreatedBy.Email};
      mail.setToAddresses(toAddresses);
      mail.setSubject('Incentive Calculations ' + a.Status);
      mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
      ' batches with '+ a.NumberOfErrors + ' failures. ' + recordsProcessed + ' invoices processed for incentive payout.');
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
}