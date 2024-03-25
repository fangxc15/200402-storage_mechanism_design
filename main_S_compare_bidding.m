% 本脚本用来进行optimal_bidding并分析它对市场的影响
%  Resultorigin指的是没有储能参加的时候
%  Resultafter指的是有储能optimal bidding后的出清结果

% 其他储能原来都是按照我们设计的投标结构参与的。竟然还有这么好的事情。。

clear
choose_scenario = 1;
S_datainput;
Para.dualresult = 0;
allagent = 1:Num.ESS;
bidagent = 1:2; %应该只有一个bid agent，要不然是负数了
tempavailableESS = setdiff(allagent,bidagent);
for w = 1:Num.S
    % 没有ESS的出清
    Resulttemp = F_marketclearing_V1_4(Num,Para,setdiff(allagent,bidagent),w); % 没有那些自投标储能1时的结果
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Resultorigin(w) = Resulttemp;
    Para.scenario(w).price = Resultorigin(w).LMP([Para.storage.Bus],:)'; %不考虑它对价格的影响，在没有储能的时候得到一个边际价格
    % 拥有ESS的出清
    Resulttemp = F_marketclearing_V1_4(Num,Para,allagent,w); % 有储能1时的结果
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Resultwith(w) = Resulttemp;
end 
%
Resultbid1 = F_stochastic_bidding_1_2(Para,bidagent,Num);
Resultbid2 = F_stochastic_bidding_2_2(Para,bidagent,Num);
%%  关键是还要计算之后的社会福利怎么变？
clear ESSschedule
Resultafter1 = F_generatesocial(Resultbid1,bidagent,Num,Para,allagent);
Resultafter2 = F_generatesocial(Resultbid2,bidagent,Num,Para,allagent);
mkdir('240128_newBidding')
save('240128_newBidding\\Data_optimal_bidding_agent12');
% save('210315\\Data_optimal_bidding_onlyagent1');
%%
S_replot_data;
%%
% 查看平均社会福利增益
save('240128_newBidding\\Data_optimal_bidding_agent12');

