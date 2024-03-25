%% 这里在Pareto计算的基础上，额外增加了一项可以testIC的环节. 这个外部可以再做一个循环.

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
    
% 240101 根据IC的conclusion去计算结算函数
% 240102 去尝试验证激励相容性，所有的储能都被视作策略性主体


% clear
falserate = 1; %表明虚高报价的倍数
falserate_SOC = 1; %表明虚高报SOC valuation的倍数
choose_scenario = 0;
S_datainput;
falseagent = 1:Num.ESS; %表示虚高报价的agent,1,5
Para.dualresult = 0;

%% 设定合适的available ESS
availableESS = 1:Num.ESS;% 只有第一个ESS是available的

Para.maxSW = 8.3067e+06;

%% 设置一个真Para和假Para
Para_true = Para;
Para_false = Para;
Para_false = F_modifyESScost(Para_false,Num,falserate,falseagent);
Para_false = F_modifyESSvaluation(Para_false,Num,falserate_SOC,falseagent);

%% 以degredation cost进行出清.
% [Result1,time_clear] = F_getresult(Num,Para,availableESS);
 for w = 1:Num.S 
        t0 = cputime;
%         Para = F_modifyESScost(Para,Num,falserate,falseagent);
%         Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent);
        Resulttemp = F_marketclearing_V1_4(Num,Para_false,availableESS,w);    
%         Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
%         Para = F_modifyESSvaluation(Para,Num,1/falserate_SOC,falseagent);
        % 这里把它还原回去计算福利
        Resulttemp.cal = F_calculatewel_inc_V3(Para_true,Resulttemp,Num,w);
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
%% 考虑分段的参数和出清，这里后面都只是改变结算函数而已
% Para = F_modifyESScost(Para,Num,falserate,falseagent);
% Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent);

Num.P = 20;
Setting.storage.discost_max = 15;
Setting.storage.chacost_max = 15;
Setting.storage.addval_min = 30;
Setting.storage.minusval_max = 60;
clear newPara
for pno = 0:Num.P
    newPara(pno+1) = F_ESS_temppara(Para_false,Num,pno,falseagent,Setting);
end
for pno = 0:Num.P
    Para_false.modify_ESS.discost_Point(:,pno+1) = [newPara(pno+1).storage.discost]';
    Para_false.modify_ESS.chacost_Point(:,pno+1) = [newPara(pno+1).storage.chacost]';
    Para_false.modify_ESS.val_Point(:,pno+1) = [newPara(pno+1).storage.val]';
end
Para_false.modify_ESS.all_Point = [Para_false.modify_ESS.chacost_Point;Para_false.modify_ESS.discost_Point;...
    Para_false.modify_ESS.val_Point];
Para_false.modify_ESS.Pmax = [[Para_false.storage.Pchamaxb] [Para_false.storage.Pdismaxb] [Para_false.storage.valmax] - [Para_false.storage.valmin]];
Para_false.modify_ESS.Interval_len = Para_false.modify_ESS.all_Point(:,1:Num.P) - Para_false.modify_ESS.all_Point(:,2:Num.P+1);




%%
% 考虑分段的出清
clear Result_pno
for w = 1:Num.S 
    for pno = 0:Num.P
        Resulttemp = F_marketclearing_V1_4(Num,newPara(pno+1),availableESS,w);
        Result_pno(w,pno+1)= Resulttemp;
    end
end

% Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
% Para = F_modifyESSvaluation(Para,Num,1/falserate_SOC,falseagent);
for pno = 0:Num.P
    Result_pno(w,pno+1).cal = F_calculatewel_inc_V3(Para_true,Result_pno(w,pno+1),Num,w);
end

%% 

Setting.kIC = 0;
Setting.kIR = 0;
choose_ESS = 1:Num.ESS;
Result_matrix = [];
Result_ESS_matrix = [];
Setting.kIC_version = 2;
for chooseIC = 0:0.001:0.3 % 用来计算在不同情况下的结算函数，然后画出Pareto Frontier
    Setting.kIC=chooseIC;
    Result_temp = F_cal_IC_welfare(Result_pno,Result1,Para_false,Num,1,Setting,choose_ESS);
    if chooseIC == 0
        Result1 = Result_temp;
    end
    % Result1.IC_cal.welfare.ESS_choose
    % sum(Result1.cal.welfare.ESS)
%     sum(Result1.cal.welfare.ESS) - Result1.IC_cal.welfare.ESS_choose;

    % 我这里是假定它真实申报才能这么做。否则的话就会出问题了！
    Result_matrix = [Result_matrix;...
        chooseIC sum(Result1.cal.income.ESS) - Result_temp.IC_cal.income.ESS_choose]; 
    
    % 为什么收支不平衡量可以这么计算？IC_cal是根据我们那个公式计算的结算函数。而cal是根据LMP计算的结算函数
    % 第一项是IC松弛量，第二项是收支盈余量
    
    
    % 这里计算的是不平衡量, ICrelax, welfare, income . welfare和real_welfare的差距是什么？
    Result_ESS_matrix = [Result_ESS_matrix; ...
            chooseIC Result_temp.IC_cal.welfare.ESS_choose Result_temp.IC_cal.income.ESS_choose ...
                      Result_temp.IC_cal.real_welfare.ESS_choose]; 
                  
    % 帕累托前沿在这里
end
% load('240129//IC_test_FalseCost_1.mat')
version_suffix =  '_newICver';            
Picture_root_folder = ['Picture', version_suffix];  
mkdir(Picture_root_folder);

Picture_folder = Picture_root_folder;
mkdir(Picture_folder);

F_plot_Pareto(1,Result_matrix, Para,Picture_folder) %1719.05是收支不平衡量

% F_plot_Pareto(1,Result_matrix, Para) %1719.05是收支不平衡量
%% 

% 这里想要看它在真实申报的背景下，在LMP.VCG.kIC机制下能获取的收益/BB情况

sum(Result1(1).cal.welfare.ESS)      % 这个是LMP机制下的收入
sum(Result1(1).cal.income.ESS)
Result1(1).IC_cal.welfare.ESS_choose % 这个相当于VCG机制下的welfare和收入
Result1(1).IC_cal.income.ESS_choose



Setting.kIC=0.1; % 这个确定应该根据kIC能接受的上限和BB能接受的上限亏空确定
% 其实都一样，只是结算结果上略有差别
Result_chooseIC = F_cal_IC_welfare(Result_pno,Result1,Para_false,Num,1,Setting,choose_ESS);
Result_chooseIC.IC_cal.welfare.ESS_choose 
Result_chooseIC.IC_cal.income.ESS_choose 
Result_chooseIC.IC_cal.real_welfare.ESS_choose

%kIC = 0.1时的结算结果：储能收入29660，储能福利1361.8，储能视在福利1361.8

% LMP机制下储能的welfare为874.67, 收入为29173
% 在IC=0的时候，储能的welfare为2461.2，收入为30760. 但是社会福利贡献计算出来是2442.6
% VCG机制下计算的主体支付为30741,这个和IC=0情况下的支付近乎一致
%   此时IC=0的时候, welfare是2461.2，收入是30760
%       IC=0.037,  welfare是1485.9， 收入是29785
%       IC=0.06,   welfare是1035.7, 收入是29334


% 如果进行谎报1.1倍：社会福利贡献2438.2
%  按照LMP结算，此时welfare 1004.6, 收入是29238
%   此时IC=0的时候, welfare是2176.4，收入是30720, 真实的welfare 2486.4
%       IC=0.037,  welfare是1261.7， 收入是29805, 真实的welfare 1571.7
%       IC=0.06,   welfare是823.0, 收入是29366, 真实的welfare 1133.0

% 如果进行谎报1.2倍：社会福利贡献2377.2
%  按照LMP结算，此时welfare 1169.4, 收入是28981
%   此时IC=0的时候, welfare是1800.5，收入是30148, 真实的welfare 2336.1
%       IC=0.037,  welfare是976.6， 收入是29324, 真实的welfare 1512.3
%       IC=0.06,   welfare是592.8, 收入是28940, 真实的welfare 1128.4

% 如果进行谎报1.4倍：社会福利贡献2145
%  按照LMP结算，此时welfare 1225.4, 收入是28205
%   此时IC=0的时候, welfare是1430.8，收入是29107, 真实的welfare 2157.2
%       IC=0.037,  welfare是678.6， 收入是28354, 真实的welfare 1405.0
%       IC=0.06,   welfare是406.9, 收入是28083, 真实的welfare 1133.3

% 为什么此时的社会福利贡献应当是2145，但IC=0计算出来的welfare是2335.4/1609.0？
% 这个是设置的数值问题
% 其他几个社会福利的情况都验证出来是正确的，社会福利贡献的确是2145，

Result_pno(1).cal.welfare.social  
Result_pno(21).cal.welfare.social 
Result_pno(1).obj  
Result_pno(21).obj 
% 感觉不对啊，怎么谎报来谎报去出现的社会福利更多了
%%
 % 考虑计算储能的收益
% mkdir('240102')
save_name = ['240129','\\','IC_test_FalseSOC_',num2str(falserate_SOC)];
save(save_name)
% save('240129\\Pareto_test')



% time_ANB + time_clear + time_wholeVCG
% time_clear + time_distributeVCG
%% 如何计算S^IC
sum([Para.storage.Pchamaxb] .* [Para.storage.chacost] * 0.4) * 2 %这是总共的谎报幅度
% 谎报幅度再除以超额利润
(1169.4-874.7)/(3752/2)

