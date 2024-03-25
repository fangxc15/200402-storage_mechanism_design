% ¼ÆËãFariness Index
for w = 1:3
    VCG(w).Fairnessindex = 0;
    tempset = [];
    for nnESS = 1:Num.ESS
        if abs(VCG(w).ESSincome(nnESS)) > 1e-4
            tempindex(nnESS) = VCG(w).ESScontribution(nnESS)/VCG(w).ESSincome(nnESS);
            tempset = [tempset nnESS];
        else 
            tempindex(nnESS) = 0;
        end 
    end 
    for nnESS = 1:Num.ESS
        if find(tempset == nnESS)
        VCG(w).Fairnessindex = VCG(w).Fairnessindex + ...
           (tempindex(nnESS) - mean(tempindex(tempset)))^2;
        end
    end 
    VCG(w).Fairnessindex = VCG(w).Fairnessindex/min(1,length(tempset));
end
