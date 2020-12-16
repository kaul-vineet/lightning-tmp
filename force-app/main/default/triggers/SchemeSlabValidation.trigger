trigger SchemeSlabValidation on Scheme_Slab__c (before insert) {

    for(Scheme_Slab__c ssc:Trigger.NEW)
    {
        Scheme_Settings__c sc = Scheme_Settings__c.getInstance();

        if(ssc.Upper_Limit_Value__c < ssc.Lower_Limit_Value__c)
        {
             ssc.Name.addError('Upper Limit should be greater than Lower Limit');
        }
        
        if(ssc.Upper_Limit_Volume__c < ssc.Lower_Limit_Volume__c)
        {
             ssc.Name.addError('Upper Limit should be greater than Lower Limit');            
        }

        System.debug('LOWER LIMIT VOLUME ' + Scheme_Settings__c.getOrgDefaults().Scheme_Lower_Limit__c);
        System.debug('UPPER LIMIT VOLUME ' + Scheme_Settings__c.getOrgDefaults().Scheme_Upper_Limit__c);
        
        
        //System.Assert (Integer.ValueOf(ssc.Upper_Limit_Volume__c) < Integer.ValueOf(Scheme_Settings__c.getOrgDefaults().Scheme_Upper_Limit__c), 'FALSE');
        
        if(Integer.ValueOf(ssc.Upper_Limit_Volume__c) > Integer.ValueOf(Scheme_Settings__c.getOrgDefaults().Scheme_Upper_Limit__c))
        {
            System.debug('COMPARISON ' + ssc.Upper_Limit_Volume__c + '-' + Scheme_Settings__c.getOrgDefaults().Scheme_Upper_Limit__c);
            ssc.Name.addError('Upper Limit Volume should be lesser than or equal to Scheme Upper Limit Settings.');                                    
        }
        
        if(ssc.Lower_Limit_Volume__c < Scheme_Settings__c.getOrgDefaults().Scheme_Lower_Limit__c)
        {
             System.debug('COMPARISON ' + ssc.Lower_Limit_Volume__c + '-' + Scheme_Settings__c.getOrgDefaults().Scheme_Lower_Limit__c);
             ssc.Name.addError('Lower Limit Volume should be greater than or equal to Scheme Lower Limit Settings.');                                                
        }
        List<Scheme_Slab__c> sscs=[SELECT Id,Lower_Limit_Volume__c,Upper_Limit_Volume__c from Scheme_Slab__c where Included_Products__c=:ssc.Included_Products__c and Scheme__c=:ssc.Scheme__c];
       List<Scheme_Slab__c> sscs1=[SELECT Id from Scheme_Slab__c where Included_Products__c=:ssc.Included_Products__c and (Lower_Limit_Value__c=:ssc.Lower_Limit_Value__c or Upper_Limit_Value__c=:ssc.Upper_Limit_Value__c)];
                    System.debug(sscs.size());
                    System.debug(ssc.Scheme__c);

        /*if(sscs.size()>=1 && ssc.Lower_Limit_Volume__c !=null)
        {
            
             ssc.Name.addError('Scheme Slab already defined with the Volume limits for the product');                                                            
        }*/
        for(Integer i=0;i<sscs.size();i++)
        {
            System.debug(i);
            if(ssc.Lower_Limit_Volume__c>=sscs[i].Lower_Limit_Volume__c && ssc.Lower_Limit_Volume__c<=sscs[i].Upper_Limit_Volume__c)
            {
                ssc.Name.addError('Scheme Slab already defined with the Volume limits for the product'); 
                break;
            }
        }
        if(sscs1.size()>=1 && ssc.Lower_Limit_Value__c !=null)
        {
             ssc.Name.addError('Scheme Slab already defined with the Value limits for the product');                                                            
        }
    }
}