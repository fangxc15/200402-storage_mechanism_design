% 200403 �����ִ����뿪�г�ʱ�����ഢ�ܰ�ԭ�ƻ������г�
%       ������ԭ�ƻ������г�(clearing1)/�������ܲ����г�(clearing2)�����������ǲ�һ���ģ����������������ܽ��мƻ�������ǰ�߲�����

% 200516 ������һ��ȱ��!���ܿ���һ������ӵ�ж��ESS
% ���ű�������������
    % ����ȫԱ����ʱ�ĳ����븣������������ESS������ʱ�ĳ����븣����ȷ��VCG��payment�����ǲ���Market Clearing 1)
    % ����Asymmetric NB����ÿ��ESS�ĸ���
    % ��ESS֮����з�̯
    % ����fairness index������ÿ�������marginal contribution


    
% ��Ҫʵ������Ŀ�꣬�Ƚ�VCG payment��LMP payment,VCG payment��LMP
    % payment��ܶ࣬Ӧ���ǰ���������㣬�԰ɣ�
% �Ƚ�VCG payment �� modified VCG payment�����߱ȽϽӽ����㹻��ƽ����ʱ�٣�

% 200518 ����Ϊcase118�Ķ���


clear
Para.bigM = 100000;
mpc = case118;
Num.D = 118;
Filename = 'IEEE118_V1';

S_uncertainty_process; %���ɵ�����Գ���
Num.T = 24;
%% sheet���룬���봢����Ϣ
ESSsheet = 'ESS1.0';
[Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
Num.ESS = max(Rawdata_ESS(:,1));
Para.storage = F_ESSstructBuild(Rawdata_ESS,Num);
% Demandsheet = 'D1.0';
% [Rawdata_Demand,Name_Demand] = xlsread(Filename,Demandsheet);
% Num.D = max(Rawdata_Demand(:,2));
Num.T = 24;
Num.N = 118;
% Para.storage(4).discost = 8;
% Para.storage(4).chacost = 8;
%% ����demand��Ϣ
for d = 1 : Num.D
    for t = 1:Num.T
        for w = 1:Num.S
            Para.demand(d).Pmax(t,w) = Para.scenario(w).normD(t) * mpc.bus(d,3);
            Para.demand(d).Pmin(t,w) = 0;
            Para.demand(d).Utility(t,w) = 1000;
        end 
    %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %��������е����⣻
       Para.demand(d).Bus = d;      
    end 
end
for w = 1:Num.S
    for t = 1:Num.T
        for d = 1:Num.D
            Para.scenario(w).Tdemandquant(d,t) = Para.demand(d).Pmax(t,w);
            Para.scenario(w).Tdemandutility(d,t) =  Para.demand(d).Utility(t,w);
        end 
    end 
end



%% ����Generator��Ϣ
% Num.T = 6;
% Num.S = 2; %��P1.2�ĸ߷��ں͵͹��ڷ���һ��

Gsheet = 'G2.0';
[Rawdata_Supply,Name_Supply] = xlsread(Filename,Gsheet);
Num.I = max(Rawdata_Supply(:,1));
Para.generator = F_GstructBuild(Num, Rawdata_Supply);

for i = 1:Num.I
    if Para.generator(i).type == 1
        Para.generator(i).Pmax =  Para.generator(i).Gmax * ones(Num.T,Num.S);
        Para.generator(i).Pmin =  Para.generator(i).Gmin * ones(Num.T,Num.S);
    elseif Para.generator(i).type == 3
        for w = 1:Num.S
            Para.generator(i).Pmax(:,w) =  Para.generator(i).Gmax  * Para.scenario(w).normW;
            Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);
        end 
    else
        for w = 1:Num.S
            Para.generator(i).Pmax(:,w) = Para.generator(i).Gmax  * Para.scenario(w).normS;
            Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);

        end 
    end 
end 
%  �������renewable����Ϣ����Ҫ�ǳ���

% Num.I = size(mpc.gen,1); %���Լӿ�������Դ
% for i = 1:Num.I
%     Para.generator(i).GNum = i;
%     Para.generator(i).FNum = i;
%     Para.generator(i).type = 1; %������
%     Para.generator(i).bus =  mpc.gen(i,1);
%     Para.generator(i).Cmax = mpc.gen(i,9);
%     Para.generator(i).Cmin = mpc.gen(i,10);
%     Para.generator(i).Pmax =  Para.generator(i).Cmax * ones(Num.T,1);
%     Para.generator(i).Pmin =  Para.generator(i).Cmin * ones(Num.T,1);
%     Para.generator(i).cost = mpc.gencost(i,5);
% end
% Para.generator(2).cost = 30;
% Para.generator(3).cost = 14;
%% Renewable�ĳ���
Para.sumrenewable = Para.generator(55).Pmax + Para.generator(56).Pmax;
Para.sumdemand = sum(mpc.bus(:,3)) * [Para.scenario.normD];
%% ��������
Num.B = size(mpc.branch,1);
for nbranch = 1:Num.B
    if mpc.branch(nbranch,6) ~=0
        Para.branch(nbranch).Pmax = mpc.branch(nbranch,6);
    else 
        Para.branch(nbranch).Pmax = Para.bigM;
    end 
   Para.branch(nbranch).LNum = nbranch;
   Para.branch(nbranch).Node1 = mpc.branch(nbranch,1);
   Para.branch(nbranch).Node2 = mpc.branch(nbranch,2);
   Para.branch(nbranch).Bvalue = 1/mpc.branch(nbranch,4);
end 
Para.Bmatrix = makeBdc(mpc);
for nnode = 1:Num.N
    Para.nodeinstrument(nnode).G = find([Para.generator.bus] == nnode);
    Para.nodeinstrument(nnode).D = find([Para.demand.Bus] == nnode);
    Para.nodeinstrument(nnode).ESS = find([Para.storage.Bus] == nnode);
end 
Para.refnode = find(mpc.bus(:,2) == 3);
%% 
availableESS = 1;% ֻ�е�һ��ESS��available��
%% ��degredation cost���г���
for w = 1:Num.S
    Result1(w).rawdata = F_marketclearing_V1_1(Num,Para,availableESS,w);
    [Result1(w).welfare,Result1(w).income,Result1(w).cost,Result1(w).utility] = F_calculatewel_inc_V2(Para,Result1(w).rawdata,Num,w);
    ESSschedule(w).cha = Result1(w).rawdata.QESScha;
    ESSschedule(w).dis = Result1(w).rawdata.QESSdis;
end
for w = 1:Num.S
    ESSrevenue1(w,:) = (Result1(w).welfare.ESS)';
end 
%% ����optimal bidding ��Ͷ��
for w = 1:Num.S
    Para.scenario(w).price = Result1(w).rawdata.LMP([Para.storage(availableESS).Bus],:);
end 
Result_selfschedule = F_stochastic_bidding_1(Para,availableESS,Num);

Result_economic  = F_stochastic_bidding_2(Para,availableESS,Num);

ESSrevenue_selfschedule = Result_selfschedule.revenue_scenario';
ESSrevenue_economic = Result_economic.revenue_scenario';

priceprofile = [];
for w = 1:Num.S
    priceprofile = [priceprofile;Para.scenario(w).price];
end

[Para.scenario.prob] * ESSrevenue_selfschedule
[Para.scenario.prob] * ESSrevenue_economic
[Para.scenario.prob] * ESSrevenue1

