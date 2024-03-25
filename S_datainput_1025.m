clear
Para.bigM = 100000;
mpc = case118;

Num.D = size(mpc.bus,1);
Num.N = size(mpc.bus,1);
S_uncertainty_process; %生成的随机性场景
Num.B = 4;

%从excel中读入的文件名和sheet名
Filename = 'IEEE118_V5';
Gsheet = 'G2.0';
ESSsheet = 'ESS3.0'; % 


%% sheet读入，读入储能信息
[Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
% Num.ESS = max(Rawdata_ESS(:,1));
Num.ESS = size(Rawdata_ESS,1);
[Para.storage,Num] = F_ESSstructBuild(Rawdata_ESS,Num,Name_ESS);

%% 对储能的成本做修正
% Para.storage(4).discost = 8;
% Para.storage(4).chacost = 8;
w = 1
%% 读入demand信息
for d = 1 : Num.D
    for t = 1:Num.T
%         for w = 1:Num.S
            Para.demand(d).Pmax(t,:) = Para.scenario(w).normD(t) * mpc.bus(d,3)/Num.B * ones(Num.B,1);
            Para.demand(d).Pmin(t,:) = zeros(Num.B,1);
            Para.demand(d).Utility(t,:) = (d * 5 + 50 * Para.scenario(w).normD(t)) * ones(Num.B,1);
%         end 
    %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %这个好像有点问题；
       Para.demand(d).Bus = d;      
    end 
end
% for w = 1:Num.S
%     for t = 1:Num.T
%         for d = 1:Num.D
%             Para.scenario(w).Tdemandquant(d,t) = Para.demand(d).Pmax(t,w);
%             Para.scenario(w).Tdemandutility(d,t) =  Para.demand(d).Utility(t,w);
%         end 
%     end 
% end
%% 读入Generator信息
% Num.T = 6;
% Num.S = 2; %把P1.2的高峰期和低谷期反了一下

[Rawdata_Supply,Name_Supply] = xlsread(Filename,Gsheet);
Num.I = max(Rawdata_Supply(:,1));
Para.generator = F_GstructBuild(Num, Rawdata_Supply);
%% 生成不同场景下的generation max
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
%% Renewable的出力统计
Para.sumrenewable = Para.generator(55).Pmax + Para.generator(56).Pmax;
Para.sumdemand = sum(mpc.bus(:,3)) * [Para.scenario.normD];
Para.sumnetdemand = Para.sumdemand - Para.sumrenewable;

%%
Num.R = sum(([Para.generator.type] == 3) | ([Para.generator.type] == 4));
Num.G = Num.I - Num.R;
renewset = find([Para.generator.type] == 3 | [Para.generator.type] == 4);
genset = find([Para.generator.type] ~= 3 & [Para.generator.type] ~= 4);



for t = 1:Num.T
    for d = 1:Num.D
        Para_modify.demand(t).utility(d,:) = Para.demand(d).Utility(t,:);
        Para_modify.demand(t).Pmax(d,:) = Para.demand(d).Pmax(t,:);
        Para_modify.demand(t).Pmin(d,:) = Para.demand(d).Pmin(t,:);
    end
    
    for s = 1:Num.ESS
        Para_modify.ESS(t).cha_utility(s,:) = Para.storage(s).chacost;
        Para_modify.ESS(t).dis_utility(s,:) = Para.storage(s).discost;   
        Para_modify.ESS(t).Pchamax(s,:) = Para.storage(s).Pchamaxb;  
        Para_modify.ESS(t).Pdismax(s,:) = Para.storage(s).Pdismaxb;  
        Para_modify.ESS(t).Pchamin(s,:) = Para.storage(s).Pchaminb;  
        Para_modify.ESS(t).Pdismin(s,:) = Para.storage(s).Pdisminb;  
    end 
    
    for g = 1:Num.G
        Para_modify.gen(t).cost(g,:) = Para.generator(genset(g)).cost;
        Para_modify.gen(t).Pmax(g,:) = Para.generator(genset(g)).Pmax(t) /Num.B * ones(Num.B,1);
        Para_modify.gen(t).Pmin(g,:) = Para.generator(genset(g)).Pmin(t) /Num.B * ones(Num.B,1);

    end 
    
    for r = 1:Num.R
        Para_modify.renew(t).cost(r,:) = Para.generator(renewset(r)).cost;
        Para_modify.renew(t).Pmax(r,:) = Para.generator(renewset(r)).Pmax(t) /Num.B * ones(Num.B,1);
        Para_modify.renew(t).Pmin(r,:) = Para.generator(renewset(r)).Pmin(t) /Num.B * ones(Num.B,1);
    end 
    
end 



%% 读入拓扑
% Num.B = size(mpc.branch,1);
% for ibranch = 1:Num.B
%     if mpc.branch(ibranch,6) ~=0
%         Para.branch(ibranch).Pmax = mpc.branch(ibranch,6);
%     else 
%         Para.branch(ibranch).Pmax = Para.bigM;
%     end 
%    Para.branch(ibranch).LNum = ibranch;
%    Para.branch(ibranch).Node1 = mpc.branch(ibranch,1);
%    Para.branch(ibranch).Node2 = mpc.branch(ibranch,2);
%    Para.branch(ibranch).Bvalue = 1/mpc.branch(ibranch,4);
% end 
% Para.Bmatrix = makeBdc(mpc);
% for nnode = 1:Num.N
%     Para.nodeinstrument(nnode).G = find([Para.generator.bus] == nnode);
%     Para.nodeinstrument(nnode).D = find([Para.demand.Bus] == nnode);
%     Para.nodeinstrument(nnode).ESS = find([Para.storage.Bus] == nnode);
% end 
% Para.refnode = find(mpc.bus(:,2) == 3);
