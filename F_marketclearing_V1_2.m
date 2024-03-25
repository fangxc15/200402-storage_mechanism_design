function Result = F_marketclearing_V1_2(Num,Para,availableESS,w,ESSschedule)
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
    Var.Ql = sdpvar(Num.B,Num.T,'full');

    %% д��Ŀ�꺯��

    obj = -sum(sum(Para.scenario(w).Tdemandutility .* Var.QD)) + sum([generator.cost] * Var.QG)...
    + sum([storage.chacost] * Var.QESScha) + sum([storage.discost] * Var.QESSdis);
    % д��Լ��
    Cons = [];
    for t = 1:Num.T
        %Լ��(2)
        for nng = 1:Num.I
            Cons = [Cons, Var.QG(nng,t) <= generator(nng).Pmax(t,w)];
            Dual.Gmax(nng,t) = length(Cons);
            Cons = [Cons,Var.QG(nng,t) >= generator(nng).Pmin(t,w)];
            Dual.Gmin(nng,t) = length(Cons);
        end 
            
            
            
       

        %Լ��(3)
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
            elseif nargin == 5 %˵���е�ESSҪ�̶�schedule��
                if ~isempty(ESSschedule(nnESS).scene)
                    Cons = [Cons, Var.QESSdis(nnESS,t) == ESSschedule(nnESS).scene(w).dis(t)];
                    Cons = [Cons, Var.QESScha(nnESS,t) == ESSschedule(nnESS).scene(w).cha(t)];
                end 
            end 
            %Լ��(4)
            Cons = [Cons,Var.QESSdis(nnESS,t) <= storage(nnESS).Pdismax];
            Cons = [Cons,Var.QESSdis(nnESS,t) >= storage(nnESS).Pdismin];
            %Լ��(5)
            Cons = [Cons,Var.QESScha(nnESS,t)  <= storage(nnESS).Pchamax];
            Cons = [Cons,Var.QESScha(nnESS,t)  >= storage(nnESS).Pchamin];
        end

        %Լ��(6)(7)
        for nnESS = 1:Num.ESS
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis <= storage(nnESS).Emax];
            Cons = [Cons,storage(nnESS).E0 + sum(Var.QESScha(nnESS,1:t)) * storage(nnESS).eff_cha - ...
                sum(Var.QESSdis(nnESS,1:t)) / storage(nnESS).eff_dis >= storage(nnESS).Emin];
        end


        %Լ��8
        for nnode = 1:Num.N
    %       ����Լ��д����
            nodeGset = Para.nodeinstrument(nnode).G;
            nodeDset = Para.nodeinstrument(nnode).D;
            nodeESSset = Para.nodeinstrument(nnode).ESS;

    %         Cons = [Cons, sum(Var.QG(:,t)) - sum(Var.QD(:,t)) + sum(Var.QESSdis(:,t)) - sum(Var.QESScha(:,t)) + Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Cons = [Cons, sum(Var.QG(nodeGset,t)) - sum(Var.QD(nodeDset,t)) + sum(Var.QESSdis(nodeESSset,t)) - sum(Var.QESScha(nodeESSset,t)) - Para.Bmatrix(nnode,:) * Var.delta(:,t) >= 0];
            Dual.LMP(nnode,t) = length(Cons);
        end
        %Լ��9
        for nbranch = 1:Num.B
            startnode = branch(nbranch).Node1;
            endnode = branch(nbranch).Node2;
            Cons = [Cons, Var.Ql(nbranch,t) == (Var.delta(startnode,t) - Var.delta(endnode,t)) * branch(nbranch).Bvalue];
            Cons = [Cons, Var.Ql(nbranch,t) <= branch(nbranch).Pmax];
            Cons = [Cons, Var.Ql(nbranch,t) >= - branch(nbranch).Pmax];
        end

        %Լ��10
        Cons =[Cons,Var.delta(Para.refnode) == 0];

    end 

    %Լ��(11)��ͷβ�������Լ����ȡ��
    for nnESS = 1:Num.ESS
%         Cons = [Cons, sum(Var.QESScha(nnESS,:)) * storage(nnESS).eff_cha - sum(Var.QESSdis(nnESS,:)) / storage(nnESS).eff_dis ==0];
    end


    ops = sdpsettings('solver','gurobi','verbose',1);
    solution = optimize(Cons,obj,ops);
    Result = [];
    %% ���н�����
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
        % ������ḣ��
end
