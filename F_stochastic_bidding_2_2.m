function Result = F_stochastic_bidding_2_2(Para,agent,Num)
% 输入的应该是Price scenario，Para.scenario.price
% 可以通过agent，索引Para.storage(agent)得到相应数据
% 价格接受者，提交price-quantity pairs
% 201130 V2_1,实现头尾不均等的valuation function，主要是32行的约束改变了
% 201210 V2_2,把cost funtion等都建模进去

    ESSno = length(agent);
    Var.chargeprice = sdpvar(Num.T,ESSno);
    Var.dischargeprice = sdpvar(Num.T,ESSno);
    Var.chargemax = sdpvar(Num.T,ESSno);
    Var.dischargemax = sdpvar(Num.T,ESSno);
    storage = Para.storage;

    Cons = [];
    % 投标规则刻画
    for i = 1:ESSno
        for t = 1:Num.T
%             Cons = [Cons, Var.chargeprice(t,i) <= Var.dischargeprice(t,i)];
            Cons = [Cons, Var.chargemax(t,i) >= Para.storage(agent(i)).Pchamin];
            Cons = [Cons, Var.dischargemax(t,i) >= Para.storage(agent(i)).Pdismin];
            Cons = [Cons, Var.chargemax(t,i) <= Para.storage(agent(i)).Pchamax];
            Cons = [Cons, Var.dischargemax(t,i) <= Para.storage(agent(i)).Pdismax];
        end 
    end 
    
    % 出清刻画
    
    for w = 1:Num.S
        Var.scene(w).bcha = binvar(Num.T,ESSno);
        Var.scene(w).bdis = binvar(Num.T,ESSno);
        Var.scene(w).charging = sdpvar(Num.T,ESSno);
        Var.scene(w).discharging = sdpvar(Num.T,ESSno);
        Var.scene(w).Elevel = sdpvar(Num.T,ESSno);
%         Var.scene(w).RTcharging = sdpvar(Num.T,ESSno);
%         Var.scene(w).RTdischarging = sdpvar(Num.T,ESSno); % 不要RT
%           charging了，说不清楚的
        if isfield(Num,'ESScostblock')
            Var.scene(w).chargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
            Var.scene(w).dischargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
        end
        if isfield(Num,'ESSvalblock')
            Var.scene(w).EndSOC = sdpvar(ESSno, Num.ESSvalblock);
        end 

        for i = 1:ESSno
            for t = 1:Num.T
                % 购电，如果中标，那么b = 1，不中标b=0
                Cons = [Cons,  Var.chargeprice(t,i) - Para.scenario(w).price(t,i) <= Para.bigM * Var.scene(w).bcha(t,i)]; % 如果购电价格大于售价，那么bcha 必然为 1；如果购电价格小于售价，也不影响
                Cons = [Cons,  -(1 -Var.scene(w).bcha(t,i)) * Para.bigM <= Var.chargeprice(t,i) - Para.scenario(w).price(t,i)]; % 此时左端也不影响。购电价格小于售价，bcha必然为0
                % 根据b对charging power进行判断
                % 最大功率 - 功率 >=0，中标，最大功率 - 功率 <=0
                Cons = [Cons,  0 <=  Var.chargemax(t,i) - Var.scene(w).charging(t,i)];
                Cons = [Cons,  Var.chargemax(t,i) - Var.scene(w).charging(t,i)  <= (1 -Var.scene(w).bcha(t,i)) * Para.bigM];
                % 功率大于0，不中标必然小于0，中标没有限制
                Cons = [Cons,  0 <= Var.scene(w).charging(t,i)];
                Cons = [Cons,  Var.scene(w).charging(t,i) <= Var.scene(w).bcha(t,i) * Para.bigM];
                
                % 售电 报价<价格才中标
                Cons = [Cons,  Var.dischargeprice(t,i) - Para.scenario(w).price(t,i) <= Para.bigM * (1 - Var.scene(w).bdis(t,i))]; %如果售电价格大于价格，那么必然不中标 bdis = 0；售电价格小于售价，不影响
                Cons = [Cons,  - Var.scene(w).bdis(t,i) * Para.bigM <= Var.dischargeprice(t,i) - Para.scenario(w).price(t,i)]; %这里不影响；售电价格小于价格，bdis 必然 为 
                Cons = [Cons,  0 <=  Var.dischargemax(t,i) - Var.scene(w).discharging(t,i)];
                Cons = [Cons,   Var.dischargemax(t,i)  - Var.scene(w).discharging(t,i)<= (1 -Var.scene(w).bdis(t,i)) * Para.bigM];
                Cons = [Cons,  0 <= Var.scene(w).discharging(t,i)];
                Cons = [Cons,  Var.scene(w).discharging(t,i) <= Var.scene(w).bdis(t,i) * Para.bigM];
                
                % 接下来还有中标分块，早知道这个写成函数
                if isfield(Num,'ESScostblock')
                    for iblock = 1:Num.ESScostblock
                        Cons = [Cons,Var.scene(w).chargingb(t,i,iblock) <= storage(agent(i)).Pchamaxb(iblock)];
                        Cons = [Cons,Var.scene(w).chargingb(t,i,iblock) >= storage(agent(i)).Pchaminb(iblock)];
                        Cons = [Cons,Var.scene(w).dischargingb(t,i,iblock) <= storage(agent(i)).Pdismaxb(iblock)];
                        Cons = [Cons,Var.scene(w).dischargingb(t,i,iblock) >= storage(agent(i)).Pdisminb(iblock)];
                    end 
                    Cons = [Cons, sum(Var.scene(w).chargingb(t,i,:)) == Var.scene(w).charging(t,i)];
                    Cons = [Cons, sum(Var.scene(w).dischargingb(t,i,:)) == Var.scene(w).discharging(t,i)];

                end
                
                if t >= 2
                    Cons = [Cons, Var.scene(w).Elevel(t,i) == Var.scene(w).Elevel(t-1,i) + (Var.scene(w).charging(t,i)) * ...
                    Para.storage(agent(i)).eff_cha - (Var.scene(w).discharging(t,i)) / ...
                    Para.storage(agent(i)).eff_dis];
                else
                    Cons = [Cons, Var.scene(w).Elevel(t,i) == Para.storage(agent(i)).E0 + (Var.scene(w).charging(t,i)) * Para.storage(agent(i)).eff_cha - (Var.scene(w).discharging(t,i)) / ...
                    Para.storage(agent(i)).eff_dis];
                end 
                
%                 Cons = [Cons, Var.scene(w).RTcharging(t,i) >=0];
%                 Cons = [Cons, Var.scene(w).RTdischarging(t,i) >= 0];
%                 Cons = [Cons, Var.scene(w).RTcharging(t,i) + Var.scene(w).charging(t,i) <= Para.storage(agent(i)).Pchamax];
%                 Cons = [Cons, Var.scene(w).RTdischarging(t,i) + Var.scene(w).charging(t,i) <= Para.storage(agent(i)).Pdismax];
                
                Cons = [Cons, Var.scene(w).Elevel(t,i) >= Para.storage(agent(i)).Emin];
                Cons = [Cons, Var.scene(w).Elevel(t,i) <= Para.storage(agent(i)).Emax];
            end
            if ~isfield(Num,'ESSvalblock')
                Cons = [Cons, Var.scene(w).Elevel(Num.T,i) >= Para.storage(agent(i)).E0];
            else 
                Cons = [Cons, Var.scene(w).EndSOC(i,:) <= storage(agent(i)).valmax];
                Cons = [Cons, Var.scene(w).EndSOC(i,:) >= storage(agent(i)).valmin];
                Cons = [Cons, sum(Var.scene(w).EndSOC(i,:)) <= Var.scene(w).Elevel(Num.T,i) - storage(agent(i)).E0]; 
%                 %%
%                 if w == 4
%                     Cons = [Cons, sum(Var.scene(4).EndSOC(i,1)) >= -4];
%                 end 
            end 
        end 
    end 

            
                        

%     obj = 0;
%     for w = 1:Num.S
%         obj_scenario(w) =  sum(sum(Para.scenario(w).price .* (Var.scene(w).discharging - Var.scene(w).charging))) + ...
%             sum(sum(0.97 * Para.scenario(w).price  .* Var.scene(w).RTdischarging)) -  sum(sum(1.03 * Para.scenario(w).price  .* Var.scene(w).RTcharging)) - ...
%             sum((Var.scene(w).discharging + Var.scene(w).RTdischarging)* [Para.storage(agent).discost]') - ...
%             sum((Var.scene(w).charging + Var.scene(w).RTcharging)* [Para.storage(agent).chacost]');
%         obj = obj + Para.scenario(w).prob * obj_scenario(w) ;
%     end 
    
    obj = 0;
    %每个场景应该都是一样的
    for w = 1:Num.S
        obj_LMPincome(w) = sum(sum(Para.scenario(w).price(:,agent) .* (Var.scene(w).discharging - Var.scene(w).charging)));
    end
    for w = 1:Num.S
        if isfield(Num,'ESScostblock')
            obj_tempcost = 0;
            for i = 1:ESSno
                for t = 1:Num.T
                    obj_tempcost = obj_tempcost + storage(agent(i)).discost * reshape(Var.scene(w).dischargingb(t,agent(i),:),Num.ESScostblock,1);
                    obj_tempcost = obj_tempcost + storage(agent(i)).chacost * reshape(Var.scene(w).chargingb(t,agent(i),:),Num.ESScostblock,1);
                end 
            end
        else 
            obj_tempcost = sum(Var.scene(w).discharging * [Para.storage(agent).discost]') + sum(Var.scene(w).charging * [Para.storage(agent).chacost]');
        end
        obj_cost(w) = obj_tempcost;
    end 
        
    
    for w = 1:Num.S
        obj_tempval = 0;
        if isfield(Num,'ESSvalblock')
            for i = 1:ESSno
                obj_tempval = obj_tempval + sum(storage(agent(i)).val .* Var.scene(w).EndSOC(i,:));
            end
        end
        obj_Endval(w) = obj_tempval;
    end 
    for w = 1:Num.S
        obj_scenario(w) = obj_LMPincome(w) - obj_cost(w)+ obj_Endval(w);       
        obj = obj + Para.scenario(w).prob * obj_scenario(w);
    end 

    
    ops = sdpsettings('solver','gurobi','verbose',1);
    solution = optimize(Cons,-obj,ops);
    
    
    

    
    
    Result.obj = value(obj);
    Result.obj_scenario = value(obj_scenario);
    Result.obj_Endval = value(obj_Endval);
    Result.obj_LMPincome = value(obj_LMPincome);
    Result.obj_cost = value(obj_cost);

    Result.chargeprice = value(Var.chargeprice);
    Result.dischargeprice = value(Var.dischargeprice);
    Result.chargemax = value(Var.chargemax);
    Result.dischargemax = value(Var.dischargemax);
    
    for w = 1:Num.S
        Result.scene(w).bcha = value(Var.scene(w).bcha);
        Result.scene(w).bdis = value(Var.scene(w).bdis);
        Result.scene(w).charging = value(Var.scene(w).charging);
        Result.scene(w).discharging = value(Var.scene(w).discharging);
        Result.scene(w).Elevel = value(Var.scene(w).Elevel);
        if isfield(Num,'ESScostblock')
            Result.scene(w).chargingb = value(Var.scene(w).chargingb); 
            Result.scene(w).dischargingb = value(Var.scene(w).dischargingb); 
        end
        if isfield(Num,'ESSvalblock')
            Result.scene(w).EndSOC = value(Var.scene(w).EndSOC);
        end 

    end 
end 

    
            
            
            
            

  



