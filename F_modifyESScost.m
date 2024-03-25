function Para = F_modifyESScost(Para,Num,falserate,falseagent)
    for i = 1:length(falseagent)
        agentno = falseagent(i);
        Para.storage(agentno).discost =  Para.storage(agentno).discost * falserate;
        Para.storage(agentno).chacost =  Para.storage(agentno).chacost * falserate;
    end 
end 