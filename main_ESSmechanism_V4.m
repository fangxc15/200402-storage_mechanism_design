% 200403 当部分储能离开市场时，其余储能按原计划参与市场
%       其他按原计划参与市场(clearing1)/其他储能参与市场(clearing2)，这两件事是不一样的，后者允许其他储能进行计划调整，前者不允许

% 200516 还存在一个缺陷!不能考虑一个主体拥有多个ESS
% 本脚本做了如下事情
    % 计算全员参与时的出清与福利，计算所有ESS不参与时的出清与福利，确定VCG的payment（都是采用Market Clearing 1)
    % 根据Asymmetric NB计算每个ESS的福利
    % 在ESS之间进行分摊
    % 考虑fairness index，计算每个机组的marginal contribution


    
% 需要实现如下目标，比较VCG payment和LMP payment,VCG payment比LMP
    % payment多很多，应该是按照主体计算，对吧？
% 比较VCG payment 和 modified VCG payment，两者比较接近？足够公平？耗时少？

% 200518 修正为case118的读入

% 200519 V4,计算VCG payment


clear
Para.bigM = 100000;
mpc = case118;
Num.D = 118;
Filename = 'IEEE118_V1';

S_uncertainty_process; %生成的随机性场景
Num.T = 24;
%% sheet读入，读入储能信息
ESSsheet = 'ESS2.0'; % 
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
%% 读入demand信息
for d = 1 : Num.D
    for t = 1:Num.T
        for w = 1:Num.S
            Para.demand(d).Pmax(t,w) = Para.scenario(w).normD(t) * mpc.bus(d,3);
            Para.demand(d).Pmin(t,w) = 0;
            Para.demand(d).Utility(t,w) = 1000;
        end 
    %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %这个好像有点问题；
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



%% 读入Generator信息
% Num.T = 6;
% Num.S = 2; %把P1.2的高峰期和低谷期反了一下

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
%  补充读入renewable的信息，主要是出力

% Num.I = size(mpc.gen,1); %可以加可再生能源
% for i = 1:Num.I
%     Para.generator(i).GNum = i;
%     Para.generator(i).FNum = i;
%     Para.generator(i).type = 1; %代表火电
%     Para.generator(i).bus =  mpc.gen(i,1);
%     Para.generator(i).Cmax = mpc.gen(i,9);
%     Para.generator(i).Cmin = mpc.gen(i,10);
%     Para.generator(i).Pmax =  Para.generator(i).Cmax * ones(Num.T,1);
%     Para.generator(i).Pmin =  Para.generator(i).Cmin * ones(Num.T,1);
%     Para.generator(i).cost = mpc.gencost(i,5);
% end
% Para.generator(2).cost = 30;
% Para.generator(3).cost = 14;
%% Renewable的出力
Para.sumrenewable = Para.generator(55).Pmax + Para.generator(56).Pmax;
Para.sumdemand = sum(mpc.bus(:,3)) * [Para.scenario.normD];
%% 读入拓扑
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
availableESS = 1:8;% 只有第一个ESS是available的
%% 以degredation cost进行出清
for w = 1:Num.S
    t0 = cputime;
    Result1(w).rawdata = F_marketclearing_V1_1(Num,Para,availableESS,w);
    [Result1(w).welfare,Result1(w).income,Result1(w).cost,Result1(w).utility] = F_calculatewel_inc_V2(Para,Result1(w).rawdata,Num,w);
    time_degradation(w) = cputime - t0;
    ESSschedule(w).cha = Result1(w).rawdata.QESScha;
    ESSschedule(w).dis = Result1(w).rawdata.QESSdis;
end
for w = 1:Num.S
    ESSrevenue1(w,:) = (Result1(w).welfare.ESS)';
end 
%% 计算VCG 

% ESSschedule.cha = Result1.QESScha;
% ESSschedule.dis = Result1.QESSdis;
% 去掉所有储能，计算VCG payment，根据此时得到的社会福利大小，也需要得到节点电价
 % 计时开始处
 availableESS = [];
for w = 1:Num.S
    t0 = cputime;

    Result2(w).rawdata = F_marketclearing_V1_1(Num,Para,availableESS,w);
    [Result2(w).welfare,Result2(w).income,Result2(w).cost,Result2(w).utility] = F_calculatewel_inc_V2(Para,Result2(w).rawdata,Num,w);
 % 计时结束处
    VCG(w).totalpayment = - Result2(w).welfare.GD + Result1(w).welfare.GD; %这是给所有ESS的VCG payment
    VCG(w).LMPpayment = sum(Result1(w).income.ESS); %这是给所有ESS的LMP payment
    time_wholeVCG(w) = cputime - t0;
end 
 save VCGdata
%% 在储能内部，根据Nash Bargaining进行分配。首先计算d，然后计算F，然后计算alpha
for w = 1:Num.S
    t0 = cputime;
    VCG(w).d = Result1(w).income.ESS; %确定disagreement point

%确定alpha值
    for nnESS = 1:Num.ESS
        ESSnode = Para.storage(nnESS).Bus;
        VCG(w).alpha(nnESS) = max(0,sum((Result1(w).rawdata.LMP(ESSnode,:) + Result2(w).rawdata.LMP(ESSnode,:)) .*...
        (Result1(w).rawdata.QESSdis(nnESS,:) - Result1(w).rawdata.QESScha(nnESS,:)))/2);
    end 

    %确定最终的每个ESS的payment
    if sum(VCG(w).alpha)~=0
        VCG(w).ESSincome = VCG(w).d + (VCG(w).totalpayment - VCG(w).LMPpayment) * VCG(w).alpha/sum(VCG(w).alpha);
    else 
        VCG(w).ESSincome = 0;
    end
    
%     VCG(w).ESSprofit = VCG(w).ESSincome - Result2(w)
    time_ANB(w) = cputime - t0;
    %% 对于G和D，根据社会福利的变化进行分配
    VCG(w).Gwelfaredelta = Result1(w).welfare.generator - Result2(w).welfare.generator;
    VCG(w).Dwelfaredelta = Result1(w).welfare.demand - Result2(w).welfare.demand;
    VCG(w).Gallocateindex = max(VCG(w).Gwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Dallocateindex = max(VCG(w).Dwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Gpayment =VCG(w).Gallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
    VCG(w).Dpayment =VCG(w).Dallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
%% 定义公平性指标，看ANB得到的分配结果怎么样。每个人创造出的好处和所有人创造的是不一样的
% 这是单独拿掉一个ESS，看社会福利的减少量
    t0 = cputime;
    for nnESS = 1:Num.ESS
        tempavailESS = 1:Num.ESS;
        tempavailESS(nnESS)= [];
    %     Resulttemp = F_marketclearing_V2(Num,Para,tempavailESS,ESSschedule);
        % 计时开始点
        Resulttemp.rawdata = F_marketclearing_V1_1(Num,Para,tempavailESS,w);
        % 计时结束点
        [Resulttemp.welfare,Resulttemp.income] = F_calculatewel_inc_V2(Para,Resulttemp.rawdata,Num,w);
        VCG(w).ESScontribution(nnESS) = Result1(w).welfare.excludeESS(nnESS) - Resulttemp.welfare.social;
    end 
    time_distributeVCG(w) = cputime - t0;
    %% 计算Fariness index
%     VCG(w).Fairnessindex = 0;
%     for nnESS = 1:Num.ESS
%         VCG(w).Fairnessindex = VCG(w).Fairnessindex + (VCG(w).ESScontribution(nnESS)/VCG(w).ESSincome(nnESS) - mean(VCG(w).ESScontribution./VCG(w).ESSincome))^2;
%     end 
%     VCG(w).Fairnessindex = VCG(w).Fairnessindex/Num.ESS;
    VCG(w).Fairnessindex = 0;
    tempset = [];
    for nnESS = 1:Num.ESS
        if abs(VCG(w).ESSincome(nnESS)) > 1e-4
            tempindex(nnESS) = VCG(w).ESScontribution(nnESS)/VCG(w).ESSincome(nnESS);
            tempset = [tempset nnESS];
        else 
            tempindex(nnESS) = 0;
        end 
    end 
    for nnESS = 1:Num.ESS
        if find(tempset == nnESS)
        VCG(w).Fairnessindex = VCG(w).Fairnessindex + ...
           (tempindex(nnESS) - mean(tempindex(tempset)))^2;
        end
    end 
    VCG(w).Fairnessindex = VCG(w).Fairnessindex/min(1,length(tempset));
end 


save distributedVCGdata
time_ANB + time_degradation + time_wholeVCG
time_degradation + time_distributeVCG
temp = [];
for i = 1:8
temp = [temp; sum(VCG(i).Gallocateindex) sum(VCG(i).Dallocateindex)];
end