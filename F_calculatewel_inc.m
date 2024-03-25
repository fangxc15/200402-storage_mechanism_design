function [welfare,income,cost,utility] = F_calculatewel_inc(Para,Result,Num)
%本函数用来计算某个LMP、出清计划下的社会福利
    generator = Para.generator;
    demand = Para.demand;
    storage = Para.storage;
    for i = 1:Num.I
        welfare.generator(i) = sum((Result.LMP(generator(i).bus,:) - generator(i).cost) .* Result.QG(i,:));
        income.generator(i) = sum(Result.LMP(generator(i).bus,:) .* Result.QG(i,:));
        cost.generator(i) = income.generator(i) - welfare.generator(i);
    end 
    for d = 1:Num.D
        welfare.demand(d) = sum((demand(d).Utility - Result.LMP(demand(d).Bus,:)) .* Result.QD(d,:)); 
        income.demand(d) = sum(( - Result.LMP(demand(d).Bus,:)) .* Result.QD(d,:));
        utility.demand(d) = -income.demand(d) + welfare.demand(d);
    end 
    for nnESS = 1:Num.ESS
        welfare.ESS(nnESS) = sum(Result.LMP(storage(nnESS).Bus,:) .* (Result.QESSdis(nnESS,:) - Result.QESScha(nnESS,:))) - ...
            sum(Result.QESSdis(nnESS,:) * storage(nnESS).discost) - sum(Result.QESScha(nnESS,:) * storage(nnESS).chacost);
        income.ESS(nnESS) = sum(Result.LMP(storage(nnESS).Bus,:) .* (Result.QESSdis(nnESS,:) - Result.QESScha(nnESS,:)));
        cost.ESS(nnESS) = income.ESS(nnESS) - welfare.ESS(nnESS);
    end 
    welfare.social =  sum(utility.demand) - sum(cost.generator) - sum(cost.ESS);
    welfare.GD = sum(utility.demand) - sum(cost.generator);
    for nnESS = 1:Num.ESS
        welfare.excludeESS(nnESS) = welfare.social + cost.ESS(nnESS);
    end 
end 