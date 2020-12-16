public class TPMBatchController { 
    @AuraEnabled
    public static String getBenefitsCustom(Id SchemeId){
        getBenefitsCustom bcn = new getBenefitsCustom(SchemeId) ;
        ID batchprocessid = Database.executeBatch(bcn, 2000);
        return batchprocessid;
    }
}