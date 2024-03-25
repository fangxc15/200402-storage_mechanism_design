function Result = F_marketclearing_V1_4(Num,Para,availableESS,w,ESSschedule)
% ���庯��
% ��Ҫ��ʵ�������г��������ʱ�ĳ��壬�����������ʱ�ĳ���
% �ܼ��������ƻ����ܼ����ÿ���˵�payment��ʣ�࣬��������ܸ���
% ������Զ�ÿ������Զ�����һ��
% ����Ǿ���ģ���أ����Ǿ���ģ�ͣ���ḣ����ʧ���������棬һ�����ǣ���Ϊ�ĳ����� ��һ�����ǣ���Ϣ����ȫ������������Ա���
% ���˵������ͼ��˽��ȥ��������⣬��������ܺͳ���ģ��һ�£�����ĳ���ģ�ͣ�����������һ�����߱���������֪���Լ��ı����Ƕ��٣�
% û�б�Ҫ����һ������ ��ḣ�� Ӧ�õ��� ���еĶ�ż������ ����������һ������ģ��
% V1_1����V1�Ļ����ϣ������˶ೡ����Ҳ�����˿�������Դ
% 201130��V1_2��Ҫʵ�̶ֹ�סESSschedule,�������һ������
% �ƻ���ʵ�ַ�block�ľ��ۣ��ҿ���ending SOC��valuation
% 201208, V1_3��ʵ��β����ending SOC�Ĳ��
% 201209, V1_4�������ܵĳɱ���block����
generator = Para.generator;
storage = Para.storage;
branch = Para.branch;
demand = Para.demand;
    %% ������߱�������Ҫ��Gexp��beta
    Var.QG = sdpvar(Num.I,Num.T,'full');
    Var.QD = sdpvar(Num.D,Num.T,'full');
    Var.delta = sdpvar(Num.N,Num.T,'full'); %���
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
    %% д��Ŀ�꺯��

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
    % д��Լ��
    Cons = [];
    for t = 1:Num.T
        %% Լ��(2)��������ķ�������
        for nng = 1:Num.I
            Cons = [Cons, Var.QG(nng,t) <= generator(nng).Pmax(t,w)];
            Dual.Gmax(nng,t) = length(Cons);
            Cons = [Cons,Var.QG(nng,t) >= generator(nng).Pmin(t,w)];
            Dual.Gmin(nng,t) = length(Cons);
        end 
 
        %% Լ��(3)�� ������õ�����
        for nnd = 1:Num.D
            Cons = [Cons, Var.QD(nnd,t) <= demand(nnd).Pmax(t,w)];
            Dual.Dmax(nnd,t) = length(Cons);
            Cons = [Cons,   Var.QD(nnd,t) >= demand(nnd).Pmin(t,w)];
            Dual.Dmin(nnd,t) = length(Cons);
        end
        
        %% Լ��(4)(15)�� ESS�ĳ������Լ��
        for nnESS = 1:Num.ESS
            if isempty(find(availableESS == nnESS)) %˵��ESS���ɵõ�
                Cons = [Cons,Var.QESSdis(nnESS,t)==0];
                Cons = [Cons,Var.QESScha(nnESS,t)==0];
            elseif nargin == 5 %˵���е�ESSҪ�̶�schedule��,ESSschedule�Ľṹ����
                if ~isempty(ESSschedule(nnESS).scene)
                    Cons = [Cons, Var.QESSdis(nnESS,t) == ESSschedule(nnESS).scene(w).dis(t)];
                    Cons = [Cons, Var.QESScha(nnESS,t) == ESSschedule(nnESS).scene(w).cha(t)];
                end 
            end 
            %Լ��(4) 
            Cons = [Cons,Var.QESSdis(nnESS,t) <= storage(nnESS).Pdismax]; %�������V1_1�����ﻹ�г�һ��Ч��
            Dual.taodismax(nnESS,t) = length(Cons);
            Cons = [Cons,Var.QESSdis(nnESS,t) >= storage(nnESS).Pdismin];
            Dual.taodismin(nnESS,t) = length(Cons);
            %Լ��(5)
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

        %% Լ��(6)(7)(8)��ESS��SOC������������
        for nnESS = 1:Num.ESS
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis == Var.SOC(nnESS,t)];
            Cons = [Cons,Var.SOC(nnESS,t) >= storage(nnESS).Emin]; 
            Dual.taoSOCmin(nnESS,t) = length(Cons);
            Cons = [Cons,Var.SOC(nnESS,t) <= storage(nnESS).Emax];
            Dual.taoSOCmax(nnESS,t) = length(Cons);

        end
        

        %% Լ��8�����ڵ㹦��ƽ��Լ��
        for nnode = 1:Num.N
    %       ����Լ��д����
            nodeGset = Para.nodeinstrument(nnode).G;
            nodeDset = Para.nodeinstrument(nnode).D;
            nodeESSset = Para.nodeinstrument(nnode).ESS;

    %         Cons = [Cons, sum(Var.QG(:,t)) - sum(Var.QD(:,t)) + sum(Var.QESSdis(:,t)) - sum(Var.QESScha(:,t)) + Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Cons = [Cons, sum(Var.QG(nodeGset,t)) - sum(Var.QD(nodeDset,t)) + sum(Var.QESSdis(nodeESSset,t)) - sum(Var.QESScha(nodeESSset,t)) - Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Dual.LMP(nnode,t) = length(Cons);
        end
        
        %% Լ��9��֧·����Լ��
        for nbranch = 1:Num.B
            startnode = branch(nbranch).Node1;
            endnode = branch(nbranch).Node2;
            Cons = [Cons, Var.Ql(nbranch,t) == (Var.delta(startnode,t) - Var.delta(endnode,t)) * branch(nbranch).Bvalue];
            Cons = [Cons, Var.Ql(nbranch,t) <= branch(nbranch).Pmax];
            Cons = [Cons, Var.Ql(nbranch,t) >= - branch(nbranch).Pmax];
        end

        %% Լ��10���ο��ڵ����λԼ��
        Cons =[Cons,Var.delta(Para.refnode,t) == 0];

    end 

    %% Լ��(11)��ͷβ�������Լ��,����δ��SOC����Լ��
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
    %% ���н�����
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
        % ������ḣ��
end
