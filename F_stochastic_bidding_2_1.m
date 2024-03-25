function Result = F_stochastic_bidding_2_1(Para,agent,Num)
% 输入的应该是Price scenario，Para.scenario.price
% 可以通过agent，索引Para.storage(agent)得到相应数据
% 价格接受者，提交price-quantity pairs
% 201130 V1_1,实现头尾不均等的valuation function，主要是32行的约束改变了

    ESSno = length(agent);
    Var.chargeprice = sdpvar(Num.T,ESSno);
    Var.dischargeprice = sdpvar(Num.T,ESSno);
    Var.chargemax = sdpvar(Num.T,ESSno);
    Var.dischargemax = sdpvar(Num.T,ESSno);
    
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
        Var.scene(w).RTcharging = sdpvar(Num.T,ESSno);
        Var.scene(w).RTdischarging = sdpvar(Num.T,ESSno);

        for i = 1:ESSno
            for t = 1:Num.T
                % 如果中标，那么b = 1，不中标b=0
                Cons = [Cons,  Var.chargeprice(t,i) - Para.scenario(w).price(t) <= Para.bigM * Var.scene(w).bcha(t,i)];
                Cons = [Cons,  -(1 -Var.scene(w).bcha(t,i)) * Para.bigM <= Var.chargeprice(t,i) - Para.scenario(w).price(t)];
                Cons = [Cons,  0 <= Var.scene(w).charging(t,i) - Var.chargemax(t,i)];
                Cons = [Cons,  Var.scene(w).charging(t,i) - Var.chargemax(t,i) <= (1 -Var.scene(w).bcha(t,i)) * Para.bigM];
                Cons = [Cons,  0 <= Var.scene(w).charging(t,i)];
                Cons = [Cons,  Var.scene(w).charging(t,i) <= Var.scene(w).bcha(t,i) * Para.bigM];
                
                Cons = [Cons,  Var.dischargeprice(t,i) - Para.scenario(w).price(t) <= Para.bigM * (1 - Var.scene(w).bdis(t,i))];
                Cons = [Cons,  - Var.scene(w).bdis(t,i) * Para.bigM <= Var.dischargeprice(t,i) - Para.scenario(w).price(t)];
                Cons = [Cons,  0 <= Var.scene(w).discharging(t,i) - Var.dischargemax(t,i)];
                Cons = [Cons,  Var.scene(w).discharging(t,i) - Var.dischargemax(t,i) <= (1 -Var.scene(w).bdis(t,i)) * Para.bigM];
                Cons = [Cons,  0 <= Var.scene(w).discharging(t,i)];
                Cons = [Cons,  Var.scene(w).discharging(t,i) <= Var.scene(w).bdis(t,i) * Para.bigM];
                
                if t >= 2
                    Cons = [Cons, Var.scene(w).Elevel(t,i) == Var.scene(w).Elevel(t-1) + (Var.scene(w).charging(t,i) + Var.scene(w).RTcharging(t,i)) * ...
                    Para.storage(agent(i)).eff_cha - (Var.scene(w).discharging(t,i) + Var.scene(w).RTdischarging(t,i)) / ...
                    Para.storage(agent(i)).eff_dis];
                else
                    Cons = [Cons, Var.scene(w).Elevel(t,i) == Para.storage(agent(i)).E0 + (Var.scene(w).charging(t,i) + ...
                        Var.scene(w).RTcharging(t,i)) * Para.storage(agent(i)).eff_cha - (Var.scene(w).discharging(t,i) + Var.scene(w).RTdischarging(t,i)) / ...
                    Para.storage(agent(i)).eff_dis];
                end 
                
                Cons = [Cons, Var.scene(w).RTcharging(t,i) >=0];
                Cons = [Cons, Var.scene(w).RTdischarging(t,i) >= 0];
                Cons = [Cons, Var.scene(w).RTcharging(t,i) + Var.scene(w).charging(t,i) <= Para.storage(agent(i)).Pchamax];
                Cons = [Cons, Var.scene(w).RTdischarging(t,i) + Var.scene(w).charging(t,i) <= Para.storage(agent(i)).Pdismax];
                
                Cons = [Cons, Var.scene(w).Elevel(t,i) >= Para.storage(agent(i)).Emin];
                Cons = [Cons, Var.scene(w).Elevel(t,i) <= Para.storage(agent(i)).Emax];
            end
            Cons = [Cons, Var.scene(w).Elevel(Num.T,i) >= Para.storage(agent(i)).E0];
        end 
    end 

            
                        

    obj = 0;
    for w = 1:Num.S
        obj_scenario(w) =  sum(sum(Para.scenario(w).price .* (Var.scene(w).discharging - Var.scene(w).charging))) + ...
            sum(sum(0.97 * Para.scenario(w).price  .* Var.scene(w).RTdischarging)) -  sum(sum(1.03 * Para.scenario(w).price  .* Var.scene(w).RTcharging)) - ...
            sum((Var.scene(w).discharging + Var.scene(w).RTdischarging)* [Para.storage(agent).discost]') - ...
            sum((Var.scene(w).charging + Var.scene(w).RTcharging)* [Para.storage(agent).chacost]');
        obj = obj + Para.scenario(w).prob * obj_scenario(w) ;
    end 
    
    ops = sdpsettings('solver','gurobi','verbose',0);
    solution = optimize(Cons,-obj,ops);
    
    Result.revenue = value(obj);
    Result.revenue_scenario = value(obj_scenario);
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
        Result.scene(w).RTcharging = value(Var.scene(w).RTcharging);
        Result.scene(w).RTdischarging = value( Var.scene(w).RTdischarging);
    end 
end 

    
            
            
            
            

  



