function Result = F_stochastic_bidding_2_2(Para,agent,Num)
% �����Ӧ����Price scenario��Para.scenario.price
% ����ͨ��agent������Para.storage(agent)�õ���Ӧ����
% �۸�����ߣ��ύprice-quantity pairs
% 201130 V2_1,ʵ��ͷβ�����ȵ�valuation function����Ҫ��32�е�Լ���ı���
% 201210 V2_2,��cost funtion�ȶ���ģ��ȥ

    ESSno = length(agent);
    Var.chargeprice = sdpvar(Num.T,ESSno);
    Var.dischargeprice = sdpvar(Num.T,ESSno);
    Var.chargemax = sdpvar(Num.T,ESSno);
    Var.dischargemax = sdpvar(Num.T,ESSno);
    storage = Para.storage;

    Cons = [];
    % Ͷ�����̻�
    for i = 1:ESSno
        for t = 1:Num.T
%             Cons = [Cons, Var.chargeprice(t,i) <= Var.dischargeprice(t,i)];
            Cons = [Cons, Var.chargemax(t,i) >= Para.storage(agent(i)).Pchamin];
            Cons = [Cons, Var.dischargemax(t,i) >= Para.storage(agent(i)).Pdismin];
            Cons = [Cons, Var.chargemax(t,i) <= Para.storage(agent(i)).Pchamax];
            Cons = [Cons, Var.dischargemax(t,i) <= Para.storage(agent(i)).Pdismax];
        end 
    end 
    
    % ����̻�
    
    for w = 1:Num.S
        Var.scene(w).bcha = binvar(Num.T,ESSno);
        Var.scene(w).bdis = binvar(Num.T,ESSno);
        Var.scene(w).charging = sdpvar(Num.T,ESSno);
        Var.scene(w).discharging = sdpvar(Num.T,ESSno);
        Var.scene(w).Elevel = sdpvar(Num.T,ESSno);
%         Var.scene(w).RTcharging = sdpvar(Num.T,ESSno);
%         Var.scene(w).RTdischarging = sdpvar(Num.T,ESSno); % ��ҪRT
%           charging�ˣ�˵�������
        if isfield(Num,'ESScostblock')
            Var.scene(w).chargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
            Var.scene(w).dischargingb = sdpvar(Num.T,ESSno,Num.ESScostblock);
        end
        if isfield(Num,'ESSvalblock')
            Var.scene(w).EndSOC = sdpvar(ESSno, Num.ESSvalblock);
        end 

        for i = 1:ESSno
            for t = 1:Num.T
                % ���磬����б꣬��ôb = 1�����б�b=0
                Cons = [Cons,  Var.chargeprice(t,i) - Para.scenario(w).price(t,i) <= Para.bigM * Var.scene(w).bcha(t,i)]; % �������۸�����ۼۣ���ôbcha ��ȻΪ 1���������۸�С���ۼۣ�Ҳ��Ӱ��
                Cons = [Cons,  -(1 -Var.scene(w).bcha(t,i)) * Para.bigM <= Var.chargeprice(t,i) - Para.scenario(w).price(t,i)]; % ��ʱ���Ҳ��Ӱ�졣����۸�С���ۼۣ�bcha��ȻΪ0
                % ����b��charging power�����ж�
                % ����� - ���� >=0���б꣬����� - ���� <=0
                Cons = [Cons,  0 <=  Var.chargemax(t,i) - Var.scene(w).charging(t,i)];
                Cons = [Cons,  Var.chargemax(t,i) - Var.scene(w).charging(t,i)  <= (1 -Var.scene(w).bcha(t,i)) * Para.bigM];
                % ���ʴ���0�����б��ȻС��0���б�û������
                Cons = [Cons,  0 <= Var.scene(w).charging(t,i)];
                Cons = [Cons,  Var.scene(w).charging(t,i) <= Var.scene(w).bcha(t,i) * Para.bigM];
                
                % �۵� ����<�۸���б�
                Cons = [Cons,  Var.dischargeprice(t,i) - Para.scenario(w).price(t,i) <= Para.bigM * (1 - Var.scene(w).bdis(t,i))]; %����۵�۸���ڼ۸���ô��Ȼ���б� bdis = 0���۵�۸�С���ۼۣ���Ӱ��
                Cons = [Cons,  - Var.scene(w).bdis(t,i) * Para.bigM <= Var.dischargeprice(t,i) - Para.scenario(w).price(t,i)]; %���ﲻӰ�죻�۵�۸�С�ڼ۸�bdis ��Ȼ Ϊ 
                Cons = [Cons,  0 <=  Var.dischargemax(t,i) - Var.scene(w).discharging(t,i)];
                Cons = [Cons,   Var.dischargemax(t,i)  - Var.scene(w).discharging(t,i)<= (1 -Var.scene(w).bdis(t,i)) * Para.bigM];
                Cons = [Cons,  0 <= Var.scene(w).discharging(t,i)];
                Cons = [Cons,  Var.scene(w).discharging(t,i) <= Var.scene(w).bdis(t,i) * Para.bigM];
                
                % �����������б�ֿ飬��֪�����д�ɺ���
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
    %ÿ������Ӧ�ö���һ����
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

    
            
            
            
            

  



