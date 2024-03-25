function Result = F_marketclearing_V1_2(Num,Para,availableESS,w,ESSschedule)
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
    Var.Ql = sdpvar(Num.B,Num.T,'full');

    %% 写出目标函数

    obj = -sum(sum(Para.scenario(w).Tdemandutility .* Var.QD)) + sum([generator.cost] * Var.QG)...
    + sum([storage.chacost] * Var.QESScha) + sum([storage.discost] * Var.QESSdis);
    % 写出约束
    Cons = [];
    for t = 1:Num.T
        %约束(2)
        for nng = 1:Num.I
            Cons = [Cons, Var.QG(nng,t) <= generator(nng).Pmax(t,w)];
            Dual.Gmax(nng,t) = length(Cons);
            Cons = [Cons,Var.QG(nng,t) >= generator(nng).Pmin(t,w)];
            Dual.Gmin(nng,t) = length(Cons);
        end 
            
            
            
       

        %约束(3)
        for nnd = 1:Num.D
            Cons = [Cons, Var.QD(nnd,t) <= demand(nnd).Pmax(t,w)];
            Dual.Dmax(nnd,t) = length(Cons);
            Cons = [Cons,   Var.QD(nnd,t) >= demand(nnd).Pmin(t,w)];
            Dual.Dmin(nnd,t) = length(Cons);
        end

        for nnESS = 1:Num.ESS
            if isempty(find(availableESS == nnESS))
                Cons = [Cons,Var.QESSdis(nnESS,t)==0];
                Cons = [Cons,Var.QESScha(nnESS,t)==0];
            elseif nargin == 5 %说明有的ESS要固定schedule了
                if ~isempty(ESSschedule(nnESS).scene)
                    Cons = [Cons, Var.QESSdis(nnESS,t) == ESSschedule(nnESS).scene(w).dis(t)];
                    Cons = [Cons, Var.QESScha(nnESS,t) == ESSschedule(nnESS).scene(w).cha(t)];
                end 
            end 
            %约束(4)
            Cons = [Cons,Var.QESSdis(nnESS,t) <= storage(nnESS).Pdismax];
            Cons = [Cons,Var.QESSdis(nnESS,t) >= storage(nnESS).Pdismin];
            %约束(5)
            Cons = [Cons,Var.QESScha(nnESS,t)  <= storage(nnESS).Pchamax];
            Cons = [Cons,Var.QESScha(nnESS,t)  >= storage(nnESS).Pchamin];
        end

        %约束(6)(7)
        for nnESS = 1:Num.ESS
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis <= storage(nnESS).Emax];
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis >= storage(nnESS).Emin];
        end


        %约束8
        for nnode = 1:Num.N
    %       这条约束写错了
            nodeGset = Para.nodeinstrument(nnode).G;
            nodeDset = Para.nodeinstrument(nnode).D;
            nodeESSset = Para.nodeinstrument(nnode).ESS;

    %         Cons = [Cons, sum(Var.QG(:,t)) - sum(Var.QD(:,t)) + sum(Var.QESSdis(:,t)) - sum(Var.QESScha(:,t)) + Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Cons = [Cons, sum(Var.QG(nodeGset,t)) - sum(Var.QD(nodeDset,t)) + sum(Var.QESSdis(nodeESSset,t)) - sum(Var.QESScha(nodeESSset,t)) - Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Dual.LMP(nnode,t) = length(Cons);
        end
        %约束9
        for nbranch = 1:Num.B
            startnode = branch(nbranch).Node1;
            endnode = branch(nbranch).Node2;
            Cons = [Cons, Var.Ql(nbranch,t) == (Var.delta(startnode,t) - Var.delta(endnode,t)) * branch(nbranch).Bvalue];
            Cons = [Cons, Var.Ql(nbranch,t) <= branch(nbranch).Pmax];
            Cons = [Cons, Var.Ql(nbranch,t) >= - branch(nbranch).Pmax];
        end

        %约束10
        Cons =[Cons,Var.delta(Para.refnode) == 0];

    end 

    %约束(11)，头尾能量相等约束，取消
    for nnESS = 1:Num.ESS
%         Cons = [Cons, sum(Var.QESScha(nnESS,:)) * storage(nnESS).eff_cha - sum(Var.QESSdis(nnESS,:)) / storage(nnESS).eff_dis ==0];
    end


    ops = sdpsettings('solver','gurobi','verbose',1);
    solution = optimize(Cons,obj,ops);
    Result = [];
    %% 进行结果输出
        Result.QG = value(Var.QG);
        Result.QD = value(Var.QD);
        Result.QESScha = value(Var.QESScha);
        Result.QESSdis = value(Var.QESSdis);
        Result.delta = value(Var.delta);
        Result.Ql = value(Var.Ql);
        Result.obj = value(obj);
        for t = 1:Num.T
            Result.LMP(:,t) = dual(Cons(Dual.LMP(:,t)));
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
