function cal = F_calculatewel_inc_V3(Para,Result,Num,w)
%��������������ĳ��LMP������ƻ��µ���ḣ��
% V2�����������
% 201209V3 ������ending evaluation�ͷֶεı���
    generator = Para.generator;
    demand = Para.demand;
    storage = Para.storage;
    for i = 1:Num.I
        welfare.generator(i) = sum((Result.LMP(generator(i).bus,:) - generator(i).cost) .* Result.QG(i,:));
        income.generator(i) = sum(Result.LMP(generator(i).bus,:) .* Result.QG(i,:));
        cost.generator(i) = income.generator(i) - welfare.generator(i);
    end 
    for d = 1:Num.D
        welfare.demand(d) = sum((demand(d).Utility(:,w)' - Result.LMP(demand(d).Bus,:)) .* Result.QD(d,:)); 
        income.demand(d) = sum(( - Result.LMP(demand(d).Bus,:)) .* Result.QD(d,:));
        utility.demand(d) = -income.demand(d) + welfare.demand(d);
    end 
    for nnESS = 1:Num.ESS
%         welfare.ESS(nnESS) = sum(Result.LMP(storage(nnESS).Bus,:) .* (Result.QESSdis(nnESS,:) - Result.QESScha(nnESS,:))) - ...
%             sum(Result.QESSdis(nnESS,:) * storage(nnESS).discost) - sum(Result.QESScha(nnESS,:) * storage(nnESS).chacost);
        income.ESS(nnESS) = sum(Result.LMP(storage(nnESS).Bus,:) .* (Result.QESSdis(nnESS,:) - Result.QESScha(nnESS,:)));
        if isfield(Num,'ESScostblock')
            cost.ESS(nnESS) = 0;
            for t = 1:Num.T
                cost.ESS(nnESS) = cost.ESS(nnESS) + storage(nnESS).discost * reshape(Result.QESSdisb(nnESS,t,:),Num.ESScostblock,1);
                cost.ESS(nnESS) = cost.ESS(nnESS) + storage(nnESS).chacost * reshape(Result.QESSchab(nnESS,t,:),Num.ESScostblock,1);
            end 
        else 
            cost.ESS(nnESS) = sum(Result.QESSdis(nnESS,:) * storage(nnESS).discost) + sum(Result.QESScha(nnESS,:) * storage(nnESS).chacost);
        end
        
        if isfield(Num,'ESSvalblock')
            utility.ESS(nnESS) = sum(Result.EndSOC(nnESS,:) .* Para.storage(nnESS).val);
            welfare.ESS(nnESS) = income.ESS(nnESS) + utility.ESS(nnESS) - cost.ESS(nnESS);
        else 
            welfare.ESS(nnESS) = income.ESS(nnESS) - cost.ESS(nnESS);
        end 
        
           
    end 
    % welfare.social2��welfare.social�Ǽ����������ʽ
    welfare.social2 = sum(welfare.demand) + sum(welfare.generator) + sum(welfare.ESS); 
    welfare.social =  sum(utility.ESS) + sum(utility.demand) - sum(cost.generator) - sum(cost.ESS);
    % welfare.GD�ǲ������ܵ�welfare
    welfare.GD = sum(utility.demand) - sum(cost.generator);
    for nnESS = 1:Num.ESS
        % ����������ESS����ḣ��/������֤
        welfare.excludeESS(nnESS) = welfare.social + cost.ESS(nnESS) - utility.ESS(nnESS);
        welfare.excludeESS2(nnESS) = welfare.GD + sum(utility.ESS) - utility.ESS(nnESS) - (sum(cost.ESS) - cost.ESS(nnESS));
    end 
    cal.welfare = welfare;
    cal.income = income;
    cal.cost = cost;
    cal.utility = utility;
end 