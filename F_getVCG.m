function [Result2,VCG,time_VCG] = F_getVCG(Num,Para,availableESS,Baseresult)
excludeESS = setdiff(1:Num.ESS,availableESS);
[Result2,time_VCG] = F_getresult(Num,Para,availableESS);
    for w = 1:Num.S
        VCG(w).totalpayment = - Result2(w).welfare.GD + Baseresult(w).welfare.GD; %这是给所有ESS的VCG payment
        VCG(w).LMPpayment = sum(Baseresult(w).income.ESS(excludeESS)); %这是给所有ESS的LMP payment
    end 
end