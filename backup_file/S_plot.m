%210315/Data_optimal_bidding_onlyagent1s

%% 对于Data_optimal_bidding,看一些数据
for w = 1:Num.S
    Cmp_price(:,w) = Para.scenario(w).price(:,1);
end 
Resultbid1.obj
Resultbid2.obj

Resultbid1.obj_scenario %显然这个有点问题,不是真正的welfare
Resultbid2.obj_scenario

% 对比ESS的利润(所有ESS). 这里的利润都是要Result_after里优化出来的
for w = 1:Num.S
    welfareESS0(w,:) = Resultorigin(w).cal.welfare.ESS; %原来的情况
    welfareESS1(w,:) = Resultafter1(w).cal.welfare.ESS; %自调度投标
    welfareESS2(w,:) = Resultafter2(w).cal.welfare.ESS; %EB投标
    welfareESS3(w,:) = Resultwith(w).cal.welfare.ESS;   % 市场调度
end 
welfareESS_matrix = [welfareESS0(:,bidagent) welfareESS1(:,bidagent) welfareESS2(:,bidagent) welfareESS3(:,bidagent)];

% 然后还要考虑社会福利
for w = 1:Num.S
    welfaresocial0(w) = Resultorigin(w).cal.welfare.social;
    welfaresocial1(w) = Resultafter1(w).cal.welfare.social; %自调度投标
    welfaresocial2(w) = Resultafter2(w).cal.welfare.social; % EB投标
    welfaresocial3(w) = Resultwith(w).cal.welfare.social;    % 市场调度
end 
welfare_matrix = [welfaresocial0' welfaresocial1' welfaresocial2' welfaresocial3'];

% 对比ESS的计划(bidagent)
for w = 1:Num.S
    ESSschedule1(w).schedule = Resultafter1(w).QESScha(bidagent,:) - Resultafter1(w).QESSdis(bidagent,:);
    ESSschedule2(w).schedule = Resultafter2(w).QESScha(bidagent,:) - Resultafter2(w).QESSdis(bidagent,:);
    ESSschedule3(w).schedule = Resultwith(w).QESScha(bidagent,:) - Resultwith(w).QESSdis(bidagent,:);
end 


% 对比当时的市场价格
for w = 1:Num.S
    LMPresult1(w).LMP = Resultafter1(w).LMP([Para.storage(bidagent).Bus],:);
    LMPresult2(w).LMP = Resultafter2(w).LMP([Para.storage(bidagent).Bus],:);
    LMPresult3(w).LMP = Resultwith(w).LMP([Para.storage(bidagent).Bus],:);
end 

%%
