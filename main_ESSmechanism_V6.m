%% 对于储能而言，除了有一个基础的以外边际/VCG定价外，还需要有别的。


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

% 201130 V5,进行一系列修改，包括框架架构的修改
    % 计算VCG机制之下ESS的profit
    % 各个Result Structure的说明
    % Result1 代表储能参与的情况
    % Result2 代表所有储能不参与的情况
    % Resulttemp 有一个ESS退出的情况

% 240129 用来进行博士论文的调试工作
clear
choose_scenario = 0;
S_datainput;
falseagent = 1:Num.ESS; %表示虚高报价的agent,1,5
falserate = 1; %表明虚高报价的倍数
falserate_SOC = 1; %表明虚高报SOC valuation的倍数
Para.dualresult = 0;
%% 设定合适的available ESS
availableESS = 1:Num.ESS;% 只有第一个ESS是available的


%% 以degredation cost进行出清,考虑了它在说假话下的情况
% [Result1,time_clear] = F_getresult(Num,Para,availableESS);
 for w = 1:Num.S 
     t0 = cputime;
        Para = F_modifyESScost(Para,Num,falserate,falseagent);
        Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent)
        Resulttemp = F_marketclearing_V1_4(Num,Para,availableESS,w);    
        Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
        Para = F_modifyESSvaluation(Para,Num,1/falserate_SOC,falseagent)
        Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
        Result1(w) = Resulttemp;
        time_clear(w) = cputime - t0;
 end 
%  save data_mystrucutre
%% 如何生成ESSschedule
for nnESS = 1:Num.ESS
    for w = 1:Num.S
        ESSschedule(nnESS).scene(w).dis = Result1(w).QESSdis(nnESS,:);
        ESSschedule(nnESS).scene(w).cha = Result1(w).QESScha(nnESS,:);
    end 
end 

% for w = 1:Num.S
%     t0 = cputime;
%     time_degradation(w) = cputime - t0;
%     ESSschedule(w).cha = Result1(w).rawdata.QESScha;
%     ESSschedule(w).dis = Result1(w).rawdata.QESSdis;
% end
% for w = 1:Num.S
%     ESSrevenue1(w,:) = (Result1(w).welfare.ESS)';
% end 
%% 去除所有储能进行出清, 计算VCG 
% ESSschedule.cha = Result1.QESScha;
% ESSschedule.dis = Result1.QESSdis;
% 去掉所有储能，计算VCG payment，根据此时得到的社会福利大小，也需要得到节点电价
 % 计时开始处
availableESS = [];
excludeESS = setdiff(1:Num.ESS,availableESS);

for w = 1:Num.S
    t0 = cputime;
    Para = F_modifyESScost(Para,Num,falserate,falseagent);
    Resulttemp = F_marketclearing_V1_4(Num,Para,availableESS,w);
    Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Result2(w) = Resulttemp;
    % 这里想要计算的是储能的总体支付
    VCG(w).totalpayment = - Result2(w).cal.welfare.GD + Result1(w).cal.welfare.GD; %不含储能的社会福利增量
    VCG(w).LMPpayment = sum(Result1(w).cal.income.ESS(excludeESS)); %这是给所有ESS的LMP payment还有它们的福利
    time_wholeVCG(w) = cputime - t0;
end 
% save('210315\\FalseSOC_1_3')

%% 在储能内部，根据Nash Bargaining进行分配。首先计算d，然后计算F，然后计算alpha
for w = 1:Num.S
    t0 = cputime;
    %确定disagreement point
    VCG(w).d = Result1(w).cal.income.ESS; 
    %确定alpha值
    for nnESS = 1:Num.ESS
        ESSnode = Para.storage(nnESS).Bus;
%         VCG(w).alpha(nnESS) = max(0,sum((Result1(w).LMP(ESSnode,:) + Result2(w).LMP(ESSnode,:)) .*...
%         (Result1(w).QESSdis(nnESS,:) - Result1(w).QESScha(nnESS,:)))/2);
          VCG(w).alpha(nnESS) = sum((Result1(w).LMP(ESSnode,:) + Result2(w).LMP(ESSnode,:)) .*...
               (Result1(w).QESSdis(nnESS,:) - Result1(w).QESScha(nnESS,:)))/2
    end 
    %确定最终的每个ESS的payment
    if sum(VCG(w).alpha)~=0
        VCG(w).ESSincome = VCG(w).d + (VCG(w).totalpayment - VCG(w).LMPpayment) * VCG(w).alpha/sum(VCG(w).alpha);
    else 
        VCG(w).ESSincome = 0;
    end
    VCG(w).ESSwelfare = VCG(w).ESSincome - Result1(w).cal.cost.ESS + Result1(w).cal.utility.ESS; % 计算VCG机制之下ESS的profit
    %% 对于G和D，根据社会福利的变化进行分配
    VCG(w).Gwelfaredelta = Result1(w).cal.welfare.generator - Result2(w).cal.welfare.generator;
    VCG(w).Dwelfaredelta = Result1(w).cal.welfare.demand - Result2(w).cal.welfare.demand;
    VCG(w).Gallocateindex = max(VCG(w).Gwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Dallocateindex = max(VCG(w).Dwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Gpayment = VCG(w).Gallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
    VCG(w).Dpayment = VCG(w).Dallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
    time_ANB(w) = cputime - t0; %计算ANB的时间
    %还可以定义一下VCG机制之下各主体相应的总支付/总利润
end
%%
% 这些都是结算结果。出清结果呢？
ESSVCGwelfare = VCG(w).ESSwelfare; %修正版的VCG利润
ESSLMPwelfare = Result1(w).cal.welfare.ESS; %LMP利润
[sum(ESSVCGwelfare) sum(ESSLMPwelfare)]  %VCG利润，LMP利润，社会总福利
Result2(w).cal.welfare.social  %所有储能不参与的情况
Result1(w).LMP(1,:);  %LMP分布
ESSVCGincome = VCG(w).ESSincome;   %VCG收入

% ESScontribution = VCG(w).ESScontribution;%VCG贡献
% ESSLMPincome = Result1(w).cal.income.ESS(excludeESS); %LMP收入
%
%% 如果要看出清结果，那就是Result1
% 还可以展现峰谷价差(这里虽然利用了118节点，但是根本就没有拓扑)
max(Result1.LMP(1,:)) - min(Result1.LMP(1,:))
% 储能的充放电量
sum(sum(Result1.QESScha)) + sum(sum(Result1.QESSdis))
% 峰负荷
max(Para.sumnetdemand + sum(Result1.QESScha)' - sum(Result1.QESSdis)')

%%
% save('210315\\Time_Test')
% time_ANB + time_clear + time_wholeVCG
% time_clear + time_distributeVCG
