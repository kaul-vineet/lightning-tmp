trigger EntitlementValidation on Entitlement__c (before insert) 
{
    for(Entitlement__c en:Trigger.NEW)
    {
        List<Entitlement__c> other_entitlements = [SELECT Id, Scheme_Slab__c, Scheme_Slab__r.Scheme__c, Early_Bird__c from Entitlement__c 
        where Scheme__c =: en.Scheme__c and Scheme_Slab__c =: en.Scheme_Slab__c];
    
        List<Scheme_Slab__c> other_schemes_slabs = [SELECT Id, Scheme__r.Inclusions__c, Scheme__r.Type__c from Scheme_Slab__c where Id =:en.Scheme_Slab__c];
            
        List<Entitlement_Article__c> current_article = [SELECT Id,Article_Type__c from Entitlement_Article__c where Id =: en.Entitlement_Article__c];
            
            
        if (en.Scheme_Slab__c != null) // Custom & Volume Schemes
        {
            if(other_schemes_slabs[0].Scheme__r.Type__c == 'Custom') // check for inclusions field for custom scheme 
            {
                String inclusions = other_schemes_slabs[0].Scheme__r.Inclusions__c;
                if (!inclusions.contains(current_article[0].Article_Type__c))
                {
                    en.Name.addError('Entitlement type not added to the scheme definition');
    
                }
            }
            else // check for inclusions field for fixed scheme 
            {
                current_article = [SELECT Id,Article_Type__c from Entitlement_Article__c where Id=:en.Entitlement_Article__c];
                //if(current_article[0].Article_Type__c != 'Goods'  && en.Scheme__c!=null)
                String mySSVal = Scheme_Settings__c.getInstance().Volume_Scheme_Entitlements__c;
                if (!mySSVal.contains(current_article[0].Article_Type__c))
                {
                    en.Name.addError('You can only have Entitlement Article of Type ' + mySSVal);
                }
            }
            
            // Check for single early bird
            if(other_schemes_slabs.size() > 0)
            {
                List<Entitlement__c> ens_eb = [SELECT Id from Entitlement__c where Scheme__c = :en.Scheme__c and Scheme_Slab__c=:en.Scheme_Slab__c and  Early_Bird__c = true ];
                if(ens_eb.size()>=1 && en.Early_Bird__c == true)
                 {
                     en.Name.addError('You can only have one Early Bird Entitlement with Scheme');
                 }
            }
        }
        else
        {
           // Check for single early bird
            if(other_schemes_slabs.size() == 0)
            {
                List<Entitlement__c> ens_eb = [SELECT Id from Entitlement__c where Scheme__c = :en.Scheme__c and  Early_Bird__c = true ];
                if(ens_eb.size()>=1 && en.Early_Bird__c == true)
                 {
                     en.Name.addError('You can only have one Early Bird Entitlement with Scheme');
                 }
            }
            
            if(other_schemes_slabs.size() == 0)
            {
                other_entitlements = [SELECT Id from Entitlement__c where Scheme__c = :en.Scheme__c and  Early_Bird__c = false ];
                if(other_entitlements.size()>=1 && en.Early_Bird__c == false)
                {
                    en.Name.addError('You can only have one Non-Early Bird Entitlement with Scheme');
                }
            }
            
            if(other_schemes_slabs.size() == 0)
            {
                current_article = [SELECT Id,Article_Type__c from Entitlement_Article__c where Id=:en.Entitlement_Article__c];
                //if(current_article[0].Article_Type__c != 'Goods'  && en.Scheme__c!=null)
                String mySSVal = Scheme_Settings__c.getInstance().Fixed_Scheme_Entitlements__c;
                if (!mySSVal.contains(current_article[0].Article_Type__c))
                {
                    en.Name.addError('You can only have Entitlement Article of Type ' + mySSVal);
                }
            }
        }
    }
}