function Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent)
    for i = 1:length(falseagent)
        agentno = falseagent(i);
        Para.storage(agentno).val =  Para.storage(agentno).val * falserate_SOC;
    end 
end 