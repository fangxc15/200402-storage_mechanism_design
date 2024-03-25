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
    
% 240101 V6,去进行尝试优化结算函数


clear
choose_scenario = 0;
S_datainput;
falserate = 1; %表明虚高报价的倍数
falseagent = 1:Num.ESS; %表示虚高报价的agent,1,5
falserate_SOC = 1; %表明虚高报SOC valuation的倍数
Para.dualresult = 0;


%% 设定合适的available ESS
availableESS = 1:Num.ESS;% 只有第一个ESS是available的

Para.maxSW = 8.3067e+06;
%% 以degredation cost进行出清
% [Result1,time_clear] = F_getresult(Num,Para,availableESS);
 for w = 1:Num.S 
        t0 = cputime;
        Para = F_modifyESScost(Para,Num,falserate,falseagent);
        Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent);
        Resulttemp = F_marketclearing_V1_4(Num,Para,availableESS,w);    
        Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
        Para = F_modifyESSvaluation(Para,Num,1/falserate_SOC,falseagent);
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
%% 考虑分段的参数和出清
Num.P = 20;
Setting.storage.discost_max = 15;
Setting.storage.chacost_max = 15;
Setting.storage.addval_min = 0;
Setting.storage.minusval_max = 90;
clear newPara
for pno = 0:Num.P
    newPara(pno+1) = F_ESS_temppara(Para,Num,pno,falseagent,Setting);
end
for pno = 0:Num.P
    Para.modify_ESS.discost_Point(:,pno+1) = [newPara(pno+1).storage.discost]';
    Para.modify_ESS.chacost_Point(:,pno+1) = [newPara(pno+1).storage.chacost]';
    Para.modify_ESS.val_Point(:,pno+1) = [newPara(pno+1).storage.val]';
end
Para.modify_ESS.all_Point = [Para.modify_ESS.discost_Point;Para.modify_ESS.discost_Point;...
    Para.modify_ESS.val_Point];
Para.modify_ESS.Interval_len = Para.modify_ESS.all_Point(:,1:Num.P) - Para.modify_ESS.all_Point(:,2:Num.P+1);

% 考虑分段的出清
clear Result_pno
for w = 1:Num.S 
    for pno = 0:Num.P
        Resulttemp = F_marketclearing_V1_4(Num,newPara(pno+1),availableESS,w);
        Result_pno(w,pno+1)= Resulttemp;
    end
end
%%
Setting.kIC = 0;
Setting.kIR = 0;
choose_ESS = 1:Num.ESS;
Result_matrix = [];
Result_ESS_matrix = [];
for chooseIC = 0:0.001:0.06
    Setting.kIC=chooseIC;
    Result_temp = F_cal_IC_welfare(Result_pno,Result1,Para,Num,1,Setting,choose_ESS);
    if chooseIC == 0
        Result1 = Result_temp;
    end
    % Result1.IC_cal.welfare.ESS_choose
    % sum(Result1.cal.welfare.ESS)
%     sum(Result1.cal.welfare.ESS) - Result1.IC_cal.welfare.ESS_choose;
    Result_matrix = [Result_matrix;chooseIC sum(Result1.cal.welfare.ESS) - Result_temp.IC_cal.welfare.ESS_choose];
    Result_ESS_matrix = [Result_ESS_matrix; ...
            chooseIC Result_temp.IC_cal.welfare.ESS_choose Result_temp.IC_cal.income.ESS_choose ...
                      Result_temp.IC_cal.real_welfare.ESS_choose]; 
end

%% 画图
% load('240129//IC_test_FalseCost_1.mat')
version_suffix =  '_newICver';            
Picture_root_folder = ['Picture', version_suffix];  
mkdir(Picture_root_folder);

Picture_folder = Picture_root_folder;
mkdir(Picture_folder);

F_plot_Pareto(1,Result_matrix, Para,Picture_folder) %1719.05是收支不平衡量
%% 

sum(Result1(1).cal.welfare.ESS)
sum(Result1(1).cal.income.ESS)
Result1(1).IC_cal.welfare.ESS_choose
Result1(1).IC_cal.income.ESS_choose


% LMP机制下储能的welfare为874.67, 收入为29173
% 在IC=0的时候，储能的welfare为2410.7，收入为30709

% VCG机制下计算的主体支付为30741,这个和IC=0情况下的支付近乎一致
%%
 % 考虑计算储能的收益
mkdir('240102')
save('240102\\Pareto_test') %这个数据已经可能是不对的数据了！



% time_ANB + time_clear + time_wholeVCG
% time_clear + time_distributeVCG
