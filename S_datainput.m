Para.bigM = 100000;
mpc = case118;
Num.B = 1;
Num.D = size(mpc.bus,1);
Num.N = size(mpc.bus,1);
[Para,Num] = F_uncertainty_process(Para,Num,choose_scenario); 
%���ɵ�����Գ���, ���choose_scenario = 1 ��ʾ���г���, =0��ʾֻ���ǳ���1

%��excel�ж�����ļ�����sheet��
Filename = 'IEEE118_V4';
Gsheet = 'G2.0';
ESSsheet = 'ESS2.0'; % 


%% sheet���룬���봢����Ϣ
[Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
Num.ESS = max(Rawdata_ESS(:,1));
[Para.storage,Num] = F_ESSstructBuild(Rawdata_ESS,Num,Name_ESS);

%% �Դ��ܵĳɱ�������
% Para.storage(4).discost = 8;
% Para.storage(4).chacost = 8;
%% ����demand��Ϣ
for d = 1 : Num.D
    for t = 1:Num.T
        for w = 1:Num.S
            Para.demand(d).Pmax(t,w) = Para.scenario(w).normD(t) * mpc.bus(d,3);
            Para.demand(d).Pmin(t,w) = 0;
            Para.demand(d).Utility(t,w) = 100;
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

[Rawdata_Supply,Name_Supply] = xlsread(Filename,Gsheet);
Num.I = max(Rawdata_Supply(:,1));
Para.generator = F_GstructBuild(Num, Rawdata_Supply);
%% ���ɲ�ͬ�����µ�generation max
for i = 1:Num.I
    if Para.generator(i).type == 4
        for w = 1:Num.S
            Para.generator(i).Pmax(:,w) = Para.generator(i).Gmax  * Para.scenario(w).normS;
            Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);
        end

    elseif Para.generator(i).type == 3
        for w = 1:Num.S
            Para.generator(i).Pmax(:,w) =  Para.generator(i).Gmax  * Para.scenario(w).normW;
            Para.generator(i).Pmin(:,w) =  Para.generator(i).Gmin  * ones(Num.T,1);
        end 
    else
        Para.generator(i).Pmax =  Para.generator(i).Gmax * ones(Num.T,Num.S);
        Para.generator(i).Pmin =  Para.generator(i).Gmin * ones(Num.T,Num.S);
    end 
end 
%% Renewable�ĳ���ͳ��
Para.sumrenewable = Para.generator(55).Pmax + Para.generator(56).Pmax;
Para.sumdemand = sum(mpc.bus(:,3)) * [Para.scenario.normD];
Para.sumnetdemand = Para.sumdemand - Para.sumrenewable;
%% ��������
Num.B = size(mpc.branch,1);
for ibranch = 1:Num.B
    if mpc.branch(ibranch,6) ~=0
        Para.branch(ibranch).Pmax = mpc.branch(ibranch,6);
    else 
        Para.branch(ibranch).Pmax = Para.bigM;
    end 
   Para.branch(ibranch).LNum = ibranch;
   Para.branch(ibranch).Node1 = mpc.branch(ibranch,1);
   Para.branch(ibranch).Node2 = mpc.branch(ibranch,2);
   Para.branch(ibranch).Bvalue = 1/mpc.branch(ibranch,4);
end 
Para.Bmatrix = makeBdc(mpc);
for nnode = 1:Num.N
    Para.nodeinstrument(nnode).G = find([Para.generator.bus] == nnode);
    Para.nodeinstrument(nnode).D = find([Para.demand.Bus] == nnode);
    Para.nodeinstrument(nnode).ESS = find([Para.storage.Bus] == nnode);
end 
Para.refnode = find(mpc.bus(:,2) == 3);

