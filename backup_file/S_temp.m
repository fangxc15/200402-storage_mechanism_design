%%  用来汇总结果
%% 用来测试VCG机制相对LMP机制的激励相容特性
% 对于 True cost 或者 False cost 2
ESSVCGwelfare = VCG(w).ESSwelfare; %修正版的VCG利润
ESSLMPwelfare = Result1(w).cal.welfare.ESS; %LMP利润
[sum(ESSVCGwelfare) sum(ESSLMPwelfare) Result1(w).cal.welfare.social]  %VCG利润，LMP利润，社会总福利
Result2(w).cal.welfare.social  %所有储能不参与的情况
Result1(w).LMP(1,:);  %LMP分布
ESSVCGincome = VCG(w).ESSincome;   %VCG收入
ESScontribution = VCG(w).ESScontribution;%VCG贡献
ESSLMPincome = Result1(w).cal.income.ESS(excludeESS); %LMP收入
time_ANB + time_clear + time_wholeVCG   %本文机制时间
time_clear + time_distributeVCG         %标准VCG机制时间
VCG.Fairnessindex
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
[welfareESS0(:,bidagent) welfareESS1(:,bidagent) welfareESS2(:,bidagent) welfareESS3(:,bidagent)]

% 然后还要考虑社会福利
for w = 1:Num.S
    welfaresocial0(w) = Resultorigin(w).cal.welfare.social;
    welfaresocial1(w) = Resultafter1(w).cal.welfare.social; %自调度投标
    welfaresocial2(w) = Resultafter2(w).cal.welfare.social; % EB投标
    welfaresocial3(w) = Resultwith(w).cal.welfare.social;    % 市场调度
end 
[welfaresocial0' welfaresocial1' welfaresocial2' welfaresocial3']

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
%% 对于Data_mystructure的一点数据
% for w = 1:Num.S
%     welfareESS_my(w,:) = Result1(w).cal.welfare.ESS;
%     welfaresocial_my(w) = Result1(w).cal.welfare.social;
% end 
% for w = 1:Num.S
%     sche_ESS(w,:) = Result1(w).QESSdis(1,:) - Result1(w).QESScha(1,:);
% end 