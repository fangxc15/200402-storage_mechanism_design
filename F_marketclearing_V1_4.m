function Result = F_marketclearing_V1_4(Num,Para,availableESS,w,ESSschedule)
% 出清函数
% 需要能实现所有市场主体参与时的出清，部分主体参与时的出清
% 能计算出出清计划、能计算出每个人的payment和剩余，计算社会总福利
% 这个可以对每个随机性都出清一次
% 如果是均衡模型呢？但是均衡模型，社会福利损失来自两方面，一方面是，人为的持留， 另一方面是，信息不完全导致它必须相对保守
% 如果说，它试图无私的去做这个问题，这里或许能和出清模型一致（这里的出清模型，报价依旧是一个决策变量，它不知道自己的报价是多少）
% 没有必要合在一起做。 社会福利 应该等于 所有的对偶函数等 本质依旧是一个均衡模型
% V1_1，在V1的基础上，考虑了多场景，也考虑了可再生能源
% 201130，V1_2，要实现固定住ESSschedule,加在最后一个参数
% 计划，实现分block的竞价，且考虑ending SOC的valuation
% 201208, V1_3，实现尾部的ending SOC的差别
% 201209, V1_4，将储能的成本分block进行
generator = Para.generator;
storage = Para.storage;
branch = Para.branch;
demand = Para.demand;
    %% 定义决策变量，主要是Gexp和beta
    Var.QG = sdpvar(Num.I,Num.T,'full');
    Var.QD = sdpvar(Num.D,Num.T,'full');
    Var.delta = sdpvar(Num.N,Num.T,'full'); %相角
    Var.QESScha = sdpvar(Num.ESS,Num.T,'full');
    Var.QESSdis = sdpvar(Num.ESS,Num.T,'full');
    if isfield(Num,'ESScostblock')
        Var.QESSchab = sdpvar(Num.ESS,Num.T,Num.ESScostblock,'full');
        Var.QESSdisb = sdpvar(Num.ESS,Num.T,Num.ESScostblock,'full');
    end
    Var.Ql = sdpvar(Num.B,Num.T,'full');
    Var.SOC = sdpvar(Num.ESS,Num.T,'full');
    if isfield(Num,'ESSvalblock')
        Var.EndSOC = sdpvar(Num.ESS, Num.ESSvalblock,'full');
    end
    %% 写出目标函数

    obj_Duti = sum(sum(Para.scenario(w).Tdemandutility .* Var.QD));
    obj_Gcost = sum([generator.cost] * Var.QG);
    if isfield(Num,'ESScostblock')
        obj_ESScost = 0;
        for iESS = 1:Num.ESS
            for t = 1:Num.T
                obj_ESScost = obj_ESScost + storage(iESS).discost * reshape(Var.QESSdisb(iESS,t,:),Num.ESScostblock,1);
                obj_ESScost = obj_ESScost + storage(iESS).chacost * reshape(Var.QESSchab(iESS,t,:),Num.ESScostblock,1);
            end 
        end 
    else 
        obj_ESScost = sum([storage.chacost] * Var.QESScha) + sum([storage.discost] * Var.QESSdis);
    end 
    obj_Endval = 0;
    if isfield(Num,'ESSvalblock')
        for iESS = 1:Num.ESS
            obj_Endval = obj_Endval + sum(storage(iESS).val .* Var.EndSOC(iESS,:));
        end 
    end
    obj = obj_Duti - obj_Gcost - obj_ESScost + obj_Endval;
    % 写出约束
    Cons = [];
    for t = 1:Num.T
        %% 约束(2)，火电机组的发电上限
        for nng = 1:Num.I
            Cons = [Cons, Var.QG(nng,t) <= generator(nng).Pmax(t,w)];
            Dual.Gmax(nng,t) = length(Cons);
            Cons = [Cons,Var.QG(nng,t) >= generator(nng).Pmin(t,w)];
            Dual.Gmin(nng,t) = length(Cons);
        end 
 
        %% 约束(3)， 需求的用电上限
        for nnd = 1:Num.D
            Cons = [Cons, Var.QD(nnd,t) <= demand(nnd).Pmax(t,w)];
            Dual.Dmax(nnd,t) = length(Cons);
            Cons = [Cons,   Var.QD(nnd,t) >= demand(nnd).Pmin(t,w)];
            Dual.Dmin(nnd,t) = length(Cons);
        end
        
        %% 约束(4)(15)， ESS的充电速率约束
        for nnESS = 1:Num.ESS
            if isempty(find(availableESS == nnESS)) %说明ESS不可得到
                Cons = [Cons,Var.QESSdis(nnESS,t)==0];
                Cons = [Cons,Var.QESScha(nnESS,t)==0];
            elseif nargin == 5 %说明有的ESS要固定schedule了,ESSschedule的结构如下
                if ~isempty(ESSschedule(nnESS).scene)
                    Cons = [Cons, Var.QESSdis(nnESS,t) == ESSschedule(nnESS).scene(w).dis(t)];
                    Cons = [Cons, Var.QESScha(nnESS,t) == ESSschedule(nnESS).scene(w).cha(t)];
                end 
            end 
            %约束(4) 
            Cons = [Cons,Var.QESSdis(nnESS,t) <= storage(nnESS).Pdismax]; %在最早的V1_1里这里还有除一个效率
            Dual.taodismax(nnESS,t) = length(Cons);
            Cons = [Cons,Var.QESSdis(nnESS,t) >= storage(nnESS).Pdismin];
            Dual.taodismin(nnESS,t) = length(Cons);
            %约束(5)
            Cons = [Cons,Var.QESScha(nnESS,t)  <= storage(nnESS).Pchamax];
            Dual.taochamax(nnESS,t) = length(Cons);
            Cons = [Cons,Var.QESScha(nnESS,t)  >= storage(nnESS).Pchamin];
            Dual.taochamin(nnESS,t) = length(Cons);
            
            if isfield(Var,'QESSchab')
                Cons = [Cons, sum(Var.QESSdisb(nnESS,t,:)) == Var.QESSdis(nnESS,t)];
                Cons = [Cons, sum(Var.QESSchab(nnESS,t,:)) == Var.QESScha(nnESS,t)];
                for iblock = 1:Num.ESScostblock
                    Cons = [Cons,Var.QESSdisb(nnESS,t,iblock) <= storage(nnESS).Pdismaxb(iblock)];
                    Dual.taodismaxb(nnESS,t,iblock) = length(Cons);
                    Cons = [Cons,Var.QESSdisb(nnESS,t,iblock) >= storage(nnESS).Pdisminb(iblock)];
                    Dual.taodisminb(nnESS,t,iblock) = length(Cons);
                    
                    Cons = [Cons,Var.QESSchab(nnESS,t,iblock) <= storage(nnESS).Pchamaxb(iblock)];
                    Dual.taochamaxb(nnESS,t,iblock) = length(Cons);
                    Cons = [Cons,Var.QESSchab(nnESS,t,iblock) >= storage(nnESS).Pchaminb(iblock)];
                    Dual.taochaminb(nnESS,t,iblock) = length(Cons);
                end 
            end 
        end

        %% 约束(6)(7)(8)，ESS的SOC计算与上下限
        for nnESS = 1:Num.ESS
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis == Var.SOC(nnESS,t)];
            Cons = [Cons,Var.SOC(nnESS,t) >= storage(nnESS).Emin]; 
            Dual.taoSOCmin(nnESS,t) = length(Cons);
            Cons = [Cons,Var.SOC(nnESS,t) <= storage(nnESS).Emax];
            Dual.taoSOCmax(nnESS,t) = length(Cons);

        end
        

        %% 约束8，各节点功率平衡约束
        for nnode = 1:Num.N
    %       这条约束写错了
            nodeGset = Para.nodeinstrument(nnode).G;
            nodeDset = Para.nodeinstrument(nnode).D;
            nodeESSset = Para.nodeinstrument(nnode).ESS;

    %         Cons = [Cons, sum(Var.QG(:,t)) - sum(Var.QD(:,t)) + sum(Var.QESSdis(:,t)) - sum(Var.QESScha(:,t)) + Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Cons = [Cons, sum(Var.QG(nodeGset,t)) - sum(Var.QD(nodeDset,t)) + sum(Var.QESSdis(nodeESSset,t)) - sum(Var.QESScha(nodeESSset,t)) - Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Dual.LMP(nnode,t) = length(Cons);
        end
        
        %% 约束9，支路功率约束
        for nbranch = 1:Num.B
            startnode = branch(nbranch).Node1;
            endnode = branch(nbranch).Node2;
            Cons = [Cons, Var.Ql(nbranch,t) == (Var.delta(startnode,t) - Var.delta(endnode,t)) * branch(nbranch).Bvalue];
            Cons = [Cons, Var.Ql(nbranch,t) <= branch(nbranch).Pmax];
            Cons = [Cons, Var.Ql(nbranch,t) >= - branch(nbranch).Pmax];
        end

        %% 约束10，参考节点的相位约束
        Cons =[Cons,Var.delta(Para.refnode,t) == 0];

    end 

    %% 约束(11)，头尾能量相等约束,或者未必SOC计算约束
    if ~isfield(Var,'EndSOC')
        for nnESS = 1:Num.ESS
            Cons = [Cons, Var.SOC(nnESS,Num.T) - storage(nnESS).E0 >= 0];
            Dual.taoEndbal(nnESS) = length(Cons);
        end
    else
        for nnESS = 1:Num.ESS
            Cons = [Cons, Var.EndSOC(nnESS,:) <= storage(nnESS).valmax];
            Dual.taoEndpiecemax(nnESS) = length(Cons);
            Cons = [Cons, Var.EndSOC(nnESS,:) >= storage(nnESS).valmin];
            Dual.taoEndpiecemin(nnESS) = length(Cons);
            Cons = [Cons, sum(Var.EndSOC(nnESS,:)) <= Var.SOC(nnESS,Num.T) - storage(nnESS).E0];
            Dual.taoEndbal(nnESS) = length(Cons);
        end 
    end
    
    ops = sdpsettings('solver','gurobi','verbose',2);
    solution = optimize(Cons,-obj,ops);
    Result = [];
    %% 进行结果输出
        Result.QG = value(Var.QG);
        Result.QD = value(Var.QD);
        Result.QESScha = value(Var.QESScha);
        Result.QESSdis = value(Var.QESSdis);
        Result.delta = value(Var.delta);
        Result.Ql = value(Var.Ql);
        Result.SOC = value(Var.SOC);
        if isfield(Var,'EndSOC')
            Result.EndSOC = value(Var.EndSOC);
        end
        
        if isfield(Var,'QESSdisb')
            Result.QESSdisb = value(Var.QESSdisb);
            Result.QESSchab = value(Var.QESSchab);
        end
        Result.obj = value(obj);
        Result.obj_Duti = value(obj_Duti);
        Result.obj_Gcost = value(obj_Gcost);
        Result.obj_ESScost = value(obj_ESScost);
        Result.obj_Endval = value(obj_Endval);
        for t = 1:Num.T
            Result.LMP(:,t) = dual(Cons(Dual.LMP(:,t)));
        end
        if Para.dualresult == 1
            for t = 1:Num.T
                Result.taodismax(:,t) = dual(Cons(Dual.taodismax(:,t)));
                Result.taodismin(:,t) = dual(Cons(Dual.taodismin(:,t)));
                Result.taochamax(:,t) = dual(Cons(Dual.taochamax(:,t)));
                Result.taochamin(:,t)= dual(Cons(Dual.taochamin(:,t)));
                Result.taoSOCmax(:,t) = dual(Cons(Dual.taoSOCmax(:,t)));
                Result.taoSOCmin(:,t) = dual(Cons(Dual.taoSOCmin(:,t)));
            end
            Result.taoEndbal = dual(Cons(Dual.taoEndbal));
            if isfield(Var,'EndSOC') 
                for nnESS = 1:Num.ESS
                    Result.taoEndpiecemin(:,nnESS) = dual(Cons(Dual.taoEndpiecemin(nnESS)));
                    Result.taoEndpiecemax(:,nnESS) = dual(Cons(Dual.taoEndpiecemax(nnESS)));
                end
            end 

            if isfield(Var,'QESSdisb')
                for nnESS = 1:Num.ESS
                    for t = 1:Num.T
                        Result.taodismaxb(nnESS,t,:) = dual(Cons(reshape(Dual.taodismaxb(nnESS,t,:),1,Num.ESScostblock)));
                        Result.taodisminb(nnESS,t,:) = dual(Cons(reshape(Dual.taodisminb(nnESS,t,:),1,Num.ESScostblock)));
                        Result.taochamaxb(nnESS,t,:) = dual(Cons(reshape(Dual.taochamaxb(nnESS,t,:),1,Num.ESScostblock)));
                        Result.taochaminb(nnESS,t,:) = dual(Cons(reshape(Dual.taochaminb(nnESS,t,:),1,Num.ESScostblock)));
                    end 
                end 
            end 
        end 



    %     Result(w).price = Result(w).price(:)';
    %     Result(w).socialcost = value(obj);
    %     for nnESS = 1:nESS
    %         Result(w).E(nnESS,t) = storage(nnESS).E0 + sum(Result(w).Pcha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
    %                 sum(Result(w).Pdis(nnESS,1:t)) / storage(nnESS).eff_dis;
    %     end
    % end
        % model = export(Cons,obj,ops);
        % params.QCPDual = 1;
        % resultCCPF = gurobi(model, params);
        % 计算社会福利
end
