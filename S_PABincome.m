
Para_modify = F_modifyESScost(Para,Num,falserate,falseagent);
if exist('falserate_SOC')
    Para_modify = F_modifyESSvaluation(Para_modify,Num,falserate_SOC,falseagent);
end

storage = Para.storage;
modify_storage = Para_modify.storage;
  for nnESS = 1:Num.ESS
        income.ESS(nnESS) = sum(Result1.LMP(storage(nnESS).Bus,:) .* (Result1.QESSdis(nnESS,:) - Result1.QESScha(nnESS,:)));
        if isfield(Num,'ESScostblock')
            cost.ESS(nnESS) = 0;
            PABincome.ESS(nnESS) = 0;
            for t = 1:Num.T
                cost.ESS(nnESS) = cost.ESS(nnESS) + storage(nnESS).discost * reshape(Result1.QESSdisb(nnESS,t,:),Num.ESScostblock,1);
                cost.ESS(nnESS) = cost.ESS(nnESS) + storage(nnESS).chacost * reshape(Result1.QESSchab(nnESS,t,:),Num.ESScostblock,1);
                
                PABincome.ESS(nnESS) = PABincome.ESS(nnESS) + modify_storage(nnESS).discost * reshape(Result1.QESSdisb(nnESS,t,:),Num.ESScostblock,1);
                PABincome.ESS(nnESS) = PABincome.ESS(nnESS) + modify_storage(nnESS).chacost * reshape(Result1.QESSchab(nnESS,t,:),Num.ESScostblock,1);

            end 
        else 
            cost.ESS(nnESS) = sum(Result1.QESSdis(nnESS,:) * storage(nnESS).discost) + sum(Result1.QESScha(nnESS,:) * storage(nnESS).chacost);
            PABincome.ESS(nnESS) = sum(Result1.QESSdis(nnESS,:) * modify_storage(nnESS).discost) + sum(Result1.QESScha(nnESS,:) * modify_storage(nnESS).chacost);
        end
        
        if isfield(Num,'ESSvalblock')
            utility.ESS(nnESS) = sum(Result1.EndSOC(nnESS,:) .* storage(nnESS).val);
            PABincome_SOC.ESS(nnESS) = - sum(Result1.EndSOC(nnESS,:) .* modify_storage(nnESS).val);
            
            welfare.ESS(nnESS) = income.ESS(nnESS) + utility.ESS(nnESS) - cost.ESS(nnESS);
            PABwelfare.ESS(nnESS) = PABincome.ESS(nnESS) + PABincome_SOC.ESS(nnESS) + utility.ESS(nnESS) - cost.ESS(nnESS);
            
        else 
            welfare.ESS(nnESS) = income.ESS(nnESS) - cost.ESS(nnESS);   
            PABwelfare.ESS(nnESS) = PABincome.ESS(nnESS) - cost.ESS(nnESS);
        end 
  end
[sum(VCG(w).ESSwelfare) sum(welfare.ESS) sum(PABwelfare.ESS)]