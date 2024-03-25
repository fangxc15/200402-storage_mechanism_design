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

    


clear
Para.bigM = 100000;
Filename = 'IEEE5_V2';

%% sheet读入，读入储能信息、Demand信息
ESSsheet = 'ESS1.0';
[Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
Num.ESS = max(Rawdata_ESS(:,1));
Para.storage = F_ESSstructBuild(Rawdata_ESS,Num);
Demandsheet = 'D1.0';
[Rawdata_Demand,Name_Demand] = xlsread(Filename,Demandsheet);
Num.D = max(Rawdata_Demand(:,2));
Num.T = max(Rawdata_Demand(:,1));
Num.N = 5;
Para.storage(4).discost = 8;
Para.storage(4).chacost = 8;


%% 读入Generator信息
mpc = case5;
% Num.T = 6;
% Num.S = 2; %把P1.2的高峰期和低谷期反了一下

Gsheet = 'G1.0';
[Rawdata_Supply,Name_Supply] = xlsread(Filename,Gsheet);
Num.I = max(Rawdata_Supply(:,1));
Para.generator = F_GstructBuild(Num, Rawdata_Supply);
for i = 1:Num.I
    Para.generator(i).Pmax =  Para.generator(i).Gmax * ones(Num.T,1);
    Para.generator(i).Pmin =  Para.generator(i).Gmin * ones(Num.T,1);
end 

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

%% 读入Demand

Para.demand = F_CstructBuild(Num, Rawdata_Demand);
for t = 1:Num.T
    for d = 1:Num.D
        Para.Tdemandquant(d,t) = Para.demand(d).Pmax(t);
        Para.Tdemandutility(d,t) =  Para.demand(d).Utility(t);
    end 
end 

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
%% 读入Renewable,节点,量、价等(这里还没有做)
availableESS = 1:Num.ESS;
%% 进行第一次出清，得到出清计划、节点电价
Result1 = F_marketclearing(Num,Para,availableESS);
[Result1.welfare,Result1.income,Result1.cost,Result1.utility] = F_calculatewel_inc(Para,Result1,Num);
ESSschedule.cha = Result1.QESScha;
ESSschedule.dis = Result1.QESSdis;
%% 去掉所有储能，计算VCG payment，根据此时得到的社会福利大小，也需要得到节点电价
 % 计时开始处
Result2 = F_marketclearing(Num,Para,[]);
 % 计时结束处
[Result2.welfare,Result2.income] = F_calculatewel_inc(Para,Result2,Num);

VCG.totalpayment = - Result2.welfare.GD + Result1.welfare.GD; %这是给所有ESS的VCG payment
VCG.LMPpayment = sum(Result1.income.ESS); %这是给所有ESS的LMP payment
%% 在储能内部，根据Nash Bargaining进行分配。首先计算d，然后计算F，然后计算alpha
VCG.d = Result1.income.ESS; %确定disagreement point

%确定alpha值
for nnESS = 1:Num.ESS
    ESSnode = Para.storage(nnESS).Bus;
    VCG.alpha(nnESS) = max(0,sum((Result1.LMP(ESSnode,:) + Result2.LMP(ESSnode,:)) .*...
        (Result1.QESSdis(nnESS,:) - Result1.QESScha(nnESS,:)))/2);
end 

%确定最终的每个ESS的payment
if sum(VCG.alpha)~=0
    VCG.ESSincome = VCG.d + (VCG.totalpayment - VCG.LMPpayment) * VCG.alpha/sum(VCG.alpha);
else 
    VCG.ESSincome = 0;
end
%% 对于G和D，根据社会福利的变化进行分配
Gwelfaredelta = Result1.welfare.generator - Result2.welfare.generator;
Dwelfaredelta = Result1.welfare.demand - Result2.welfare.demand;
Gallocateindex = max(Gwelfaredelta,0) / (sum(max(Gwelfaredelta,0)) + sum(max(Dwelfaredelta,0)));
Dallocateindex = max(Dwelfaredelta,0) / (sum(max(Gwelfaredelta,0)) + sum(max(Dwelfaredelta,0)));
VCG.Gpayment = Gallocateindex * (VCG.LMPpayment - VCG.totalpayment);
VCG.Dpayment = Dallocateindex * (VCG.LMPpayment - VCG.totalpayment);

%% 定义公平性指标，看ANB得到的分配结果怎么样。每个人创造出的好处和所有人创造的是不一样的
% 这是单独拿掉一个ESS，看社会福利的减少量
for nnESS = 1:Num.ESS
    tempavailESS = 1:Num.ESS;
    tempavailESS(nnESS)= [];
%     Resulttemp = F_marketclearing_V2(Num,Para,tempavailESS,ESSschedule);
    % 计时开始点
    Resulttemp = F_marketclearing(Num,Para,tempavailESS);
    % 计时结束点
    [Resulttemp.welfare,Resulttemp.income] = F_calculatewel_inc(Para,Resulttemp,Num);
    ESScontribution(nnESS) = Result1.welfare.excludeESS(nnESS) - Resulttemp.welfare.social;
end 
%% 计算Fariness index
Fairnessindex = 0;
for nnESS = 1:Num.ESS
    Fairnessindex = Fairnessindex + (ESScontribution(nnESS)/VCG.ESSincome(nnESS) - mean(ESScontribution./VCG.ESSincome))^2;
end 
Fairnessindex = Fairnessindex/Num.ESS;

%% 计算SharpleyValue

for no = 0:2^(Num.ESS)-1
    strno = dec2bin(no);
    strno = [repmat('0',1,Num.ESS-length(strno)) strno];
    tempavailESS = find(strno == '1');
%     Resulttemp = F_marketclearing_V2(Num,Para,tempavailESS,ESSschedule);
    Resulttemp = F_marketclearing(Num,Para,tempavailESS);
    [Resulttemp.welfare,Resulttemp.income] = F_calculatewel_inc(Para,Resulttemp,Num);
    coalitionyoukSharpley(no+1) = - Result2.welfare.GD + Resulttemp.welfare.GD;
end 
%% 
for nnESS = 1:Num.ESS
    ESSsharpley(nnESS) = 0;
    for tempno = 0:2^(Num.ESS-1)-1
        tempstrno = dec2bin(tempno);
        tempstrno = [repmat('0',1,Num.ESS-1-length(tempstrno)) tempstrno];
        nowith = bin2dec([tempstrno(1:nnESS-1) '1' tempstrno(nnESS:Num.ESS-1)]);
        nowithout = bin2dec([tempstrno(1:nnESS-1) '0' tempstrno(nnESS:Num.ESS-1)]);
        innum = length(find(tempstrno == '1'));
        ESSsharpley(nnESS) = ESSsharpley(nnESS) + (coalitionSharpley(nowith+1) - ...
            coalitionSharpley(nowithout+1)) * factorial(innum) * factorial(Num.ESS - innum-1);
    end 
    ESSsharpley(nnESS) = ESSsharpley(nnESS)/factorial(Num.ESS);
end 

%% 比较一下按照Sharpley结算，按Nash Bargaining结算，按完全版的VCG结算的区别

%% 加入备用市场？
%% 加入激励相容？
    Revenue.ESS = VCG.ESSincome - Result1.cost.ESS;
    Revenue.generator = Result1.welfare.generator - VCG.Gpayment;
    Revenue.demand = Result1.welfare.demand + VCG.Dpayment;%VCG Dpayment是负的,为什么？这个地方好奇怪？
    
% 给出ESS真实的成本，Excel里的成本可能是假的
    realdiscost = [3.0000    2.0000    0.1000    1.0000];
    realchacost = [3.0000    2.0000    0.1000    1.0000];

    adjustedESSR = Revenue.ESS + ([Para.storage.discost] - realdiscost) .*  ...
        sum(Result1.QESSdis,2)' + ([Para.storage.chacost] - realchacost) .* sum(Result1.QESScha,2)';
% 验证环节
% sum(Revenue.ESS) + sum(Revenue.generator) + sum(Revenue.demand)
% sum(Result1.welfare.generator) + sum(Result1.welfare.demand) + sum(Result1.welfare.ESS)

% sum(Result1.income.ESS)
%     adjustedESSR(4)
%     adjustedSW = Result1.welfare.social + sum(adjustedESSR) - sum(Revenue.ESS)
