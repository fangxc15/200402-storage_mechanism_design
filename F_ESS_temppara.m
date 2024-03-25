function Para = F_ESS_temppara(Para,Num,pno,falseagent,Setting)
    % 对ESS Para进行分段
    for i = 1:length(falseagent)
        agentno = falseagent(i);
%                 Para.Point = -(Para.xpara - Para.xworse)' * [0:Num.P]/Num.P + Para.xpara'; %这个是仅限spread决策法的时候;

        % 这个cost应该是越大越糟糕
        Para.storage(agentno).discost =  Para.storage(agentno).discost * (Num.P-pno)/Num.P ...
                                        + Setting.storage.discost_max * pno/Num.P;
        Para.storage(agentno).chacost =  Para.storage(agentno).chacost * (Num.P-pno)/Num.P ...
                                        + Setting.storage.chacost_max * pno/Num.P;
        addval_no = floor(Num.ESSvalblock/2+1):Num.ESSvalblock;
        minusval_no = 1:floor(Num.ESSvalblock/2);
        
        % 对于前两段，减少val的部分，相当于发电，显然是越大越糟糕；
        % 对于后两段，增加val的部分，相当于负荷，显然是越小越糟糕；
        Para.storage(agentno).val(addval_no) = Para.storage(agentno).val(addval_no) * (Num.P-pno)/Num.P ...
                                        + Setting.storage.addval_min * pno/Num.P;
        Para.storage(agentno).val(minusval_no) = Para.storage(agentno).val(minusval_no) *(Num.P-pno)/Num.P ...
                                        + Setting.storage.minusval_max * pno/Num.P;
    end 
end 