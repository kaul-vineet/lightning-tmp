global class TPMFlowBatchController { 
    
    global class FlowInput {
        
        @InvocableVariable
        global Id SchemeId;
        
    }
    
    global class FlowOutput {
        
        @InvocableVariable
        global String ProcessId;
        
    }
   
   @InvocableMethod ( label='TPMFlowBatchController.getBenefitsCustom' description='Calculate benefits' )
    global static List<FlowOutput> getBenefitsCustom(List<FlowInput> inputs) {
        FlowInput objInput = inputs.get(0);
        List <FlowOutput> outputs = new List <FlowOutput>();
        FlowOutput objOutput = new FlowOutput();
        getBenefitsCustom bcn = new getBenefitsCustom(objInput.SchemeId);
        objOutput.ProcessId = Database.executeBatch(bcn, 2000);
        outputs.add (objOutput);
        return outputs;
    }
}