function Result = F_stochastic_bidding_1_1(Para,agent,Num)
% �����Ӧ����Price scenario��Para.scenario.price
% ����ͨ��agent������Para.storage(agent)�õ���Ӧ����
% �۸�����ߣ���ǰself-scheduling
% 201130 V1_1,ʵ��ͷβ�����ȵ�valuation function����Ҫ��32�е�Լ���ı���
% 201210 V1_2,һ�������Ŀ��õİ汾

    ESSno = length(agent);
    Var.charging = sdpvar(Num.T,ESSno);
    Var.discharging = sdpvar(Num.T,ESSno);
    Var.Elevel = sdpvar(Num.T,ESSno);
    Cons = [];
    for i = 1:ESSno
        for t = 1:Num.T
            Cons = [Cons, Var.charging(t,i) <= Para.storage(agent(i)).Pchamax];
            Cons = [Cons, Var.charging(t,i) >= Para.storage(agent(i)).Pchamin];
            Cons = [Cons, Var.discharging(t,i) <= Para.storage(agent(i)).Pdismax];
            Cons = [Cons, Var.discharging(t,i) >= Para.storage(agent(i)).Pdismin];
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
        
        Cons = [Cons, Var.Elevel(Num.T,i) >= Para.storage(agent(i)).E0];
    
    end 
    obj = 0;
    for w = 1:Num.S
        obj_scenario(w) =  sum(sum(Para.scenario(w).price .* (Var.discharging - Var.charging))) - ...
            sum(Var.discharging * [Para.storage(agent).discost]') - sum(Var.charging * [Para.storage(agent).chacost]');
        obj = obj + Para.scenario(w).prob * obj_scenario(w) ;
    end 
    
    ops = sdpsettings('solver','gurobi','verbose',0);
    solution = optimize(Cons,-obj,ops);
    
    Result.revenue = value(obj);
    Result.revenue_scenario = value(obj_scenario);
    Result.charging = value(Var.charging);
    Result.discharging = value(Var.discharging);
    Result.Elevel = value(Var.Elevel);
end 

    
            
            
            
            

  



