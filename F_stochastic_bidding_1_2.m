function Result = F_stochastic_bidding_1_2(Para,agent,Num)
% 输入的应该是Price scenario，Para.scenario.price
% 可以通过agent，索引Para.storage(agent)得到相应数据
% 价格接受者，提前self-scheduling
% 201130 V1_1,实现头尾不均等的valuation function，主要是32行的约束改变了
% 201210 V1_2,一个完整的可用的版本
    storage = Para.storage;
    ESSno = length(agent);
    Var.charging = sdpvar(Num.T,ESSno);
    Var.discharging = sdpvar(Num.T,ESSno);
    if isfield(Num,'ESScostblock')
        Var.chargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
        Var.dischargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
    end
    if isfield(Num,'ESSvalblock')
        Var.EndSOC = sdpvar(ESSno, Num.ESSvalblock);
    end 
    Var.Elevel = sdpvar(Num.T,ESSno);
    Cons = [];
    for i = 1:ESSno
        for t = 1:Num.T
            Cons = [Cons, Var.charging(t,i) <= Para.storage(agent(i)).Pchamax];
            Cons = [Cons, Var.charging(t,i) >= Para.storage(agent(i)).Pchamin];
            Cons = [Cons, Var.discharging(t,i) <= Para.storage(agent(i)).Pdismax];
            Cons = [Cons, Var.discharging(t,i) >= Para.storage(agent(i)).Pdismin];
            if isfield(Var,'chargingb')
                for iblock = 1:Num.ESScostblock
                    Cons = [Cons,Var.chargingb(t,i,iblock) <= storage(agent(i)).Pchamaxb(iblock)];
                    Cons = [Cons,Var.chargingb(t,i,iblock) >= storage(agent(i)).Pchaminb(iblock)];
                    Cons = [Cons,Var.dischargingb(t,i,iblock) <= storage(agent(i)).Pdismaxb(iblock)];
                    Cons = [Cons,Var.dischargingb(t,i,iblock) >= storage(agent(i)).Pdisminb(iblock)];
                end 
                Cons = [Cons, sum(Var.chargingb(t,i,:)) == Var.charging(t,i)];
                Cons = [Cons, sum(Var.dischargingb(t,i,:)) == Var.discharging(t,i)];
            end 
            Cons = [Cons, Var.Elevel(t,i) <= Para.storage(agent(i)).Emax];
            Cons = [Cons, Var.Elevel(t,i) >= Para.storage(agent(i)).Emin];
            if t >= 2
                Cons = [Cons, Var.Elevel(t,i) == Var.Elevel(t-1,i) + Var.charging(t,i) * ...
                    Para.storage(agent(i)).eff_cha - Var.discharging(t,i) / ...
                    Para.storage(agent(i)).eff_dis];
            else
                Cons = [Cons, Var.Elevel(t,i) == Para.storage(agent(i)).E0 + Var.charging(t,i) * ...
                    Para.storage(agent(i)).eff_cha - Var.discharging(t,i) / ...
                    Para.storage(agent(i)).eff_dis];
            end 
        end 
        if ~isfield(Var,'EndSOC')
            Cons = [Cons, Var.Elevel(Num.T,i) >= Para.storage(agent(i)).E0];
        else          
            Cons = [Cons, Var.EndSOC(i,:) <= storage(agent(i)).valmax];
            Cons = [Cons, Var.EndSOC(i,:) >= storage(agent(i)).valmin];
            Cons = [Cons, sum(Var.EndSOC(i,:)) <= Var.Elevel(Num.T,i) - storage(agent(i)).E0];            
        end 
    end 
    obj = 0;
    %每个场景应该都是一样的
    for w = 1:Num.S
        obj_LMPincome(w) = sum(sum(Para.scenario(w).price(:,agent) .* (Var.discharging - Var.charging)));
    end 
    if isfield(Var,'chargingb')
        obj_tempcost = 0;
        for i = 1:ESSno
            for t = 1:Num.T
                obj_tempcost = obj_tempcost + storage(agent(i)).discost * reshape(Var.dischargingb(t,agent(i),:),Num.ESScostblock,1);
                obj_tempcost = obj_tempcost + storage(agent(i)).chacost * reshape(Var.chargingb(t,agent(i),:),Num.ESScostblock,1);
            end 
        end
    else 
        obj_tempcost = sum(Var.discharging * [Para.storage(agent).discost]') + sum(Var.charging * [Para.storage(agent).chacost]');
    end 
        
    
    
    obj_tempval = 0;
    if isfield(Var,'EndSOC')
        for i = 1:ESSno
            obj_tempval = obj_tempval + sum(storage(agent(i)).val .* Var.EndSOC(i,:));
        end
    end 
    for w = 1:Num.S
        obj_cost(w) = obj_tempcost;
        obj_Endval(w) = obj_tempval;

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
    
    Result.charging = value(Var.charging);
    Result.discharging = value(Var.discharging);
    Result.Elevel = value(Var.Elevel);
    for w = 1:Num.S
        Result.scene(w).charging = Result.charging;
        Result.scene(w).discharging = Result.discharging;
    end 
    
    
    if isfield(Var,'chargingb')
        Result.chargingb = value(Var.chargingb); 
        Result.dischargingb = value(Var.dischargingb); 
    end
    if isfield(Var,'EndSOC')
        Result.EndSOC = value(Var.EndSOC);
    end 
end 

    
            
            
            
            

  



