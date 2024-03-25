%%  �������ܽ��
%% ��������VCG�������LMP���Ƶļ�����������
% ���� True cost ���� False cost 2
% ESSVCGwelfare = VCG(w).ESSwelfare; %�������VCG����
% ESSLMPwelfare = Result1(w).cal.welfare.ESS; %LMP����
% [sum(ESSVCGwelfare) sum(ESSLMPwelfare) Result1(w).cal.welfare.social]  %VCG���� LMP���� ��ḣ��
% Result1(w).LMP(1,:);  %LMP�ֲ�
% ESSVCGincome = VCG(w).ESSincome;   %VCG����
% ESScontribution = VCG(w).ESScontribution;%VCG����
% ESSLMPincome = Result1(w).cal.income.ESS(excludeESS); %LMP����
% time_ANB + time_clear + time_wholeVCG   %���Ļ���ʱ��
% time_clear + time_distributeVCG         %��׼VCG����ʱ��
% VCG.Fairnessindex
%% ����Data_optimal_bidding,��һЩ����
% for w = 1:Num.S
%     Cmp_price(:,w) = Para.scenario(w).price(:,1);
% end 
% Resultbid1.obj
% Resultbid2.obj
% 
% Resultbid1.obj_scenario %��Ȼ����е�����,����������welfare
% Resultbid2.obj_scenario

% �Ա�ESS������(����ESS)
for w = 1:Num.S
    welfareESS1(w,:) = Resultafter1(w).cal.welfare.ESS; %�Ե���Ͷ��
    welfareESS2(w,:) = Resultafter2(w).cal.welfare.ESS; %EBͶ��
    welfareESS3(w,:) = Resultwith(w).cal.welfare.ESS;   % �г�����
end 
[welfareESS1(:,1) welfareESS2(:,1) welfareESS3(:,1)]
% Ȼ��Ҫ������ḣ��
for w = 1:Num.S
    welfaresocial1(w) = Resultafter1(w).cal.welfare.social; %�Ե���Ͷ��
    welfaresocial2(w) = Resultafter2(w).cal.welfare.social; % EBͶ��
    welfaresocial3(w) = Resultwith(w).cal.welfare.social;    % �г�����
end 
[welfaresocial1' welfaresocial2' welfaresocial3']
% �����ܳɱ�
for w = 1:Num.S
    totalcost1(w) = Resultafter1(w).cal.welfare.social - sum(Resultafter1(w).cal.utility.demand);
    totalcost2(w) = Resultafter2(w).cal.welfare.social - sum(Resultafter2(w).cal.utility.demand);
    totalcost3(w) = Resultwith(w).cal.welfare.social - sum(Resultwith(w).cal.utility.demand);
end 
[totalcost1' totalcost2' totalcost3']

% �Ա�ESS�ļƻ�(bidagent)
for w = 1:Num.S
    ESSschedule1(w).schedule = Resultafter1(w).QESScha(bidagent,:) - Resultafter1(w).QESSdis(bidagent,:);
    ESSschedule2(w).schedule = Resultafter2(w).QESScha(bidagent,:) - Resultafter2(w).QESSdis(bidagent,:);
    ESSschedule3(w).schedule = Resultwith(w).QESScha(bidagent,:) - Resultwith(w).QESSdis(bidagent,:);
end 

% �Աȵ�ʱ���г��۸�
for w = 1:Num.S
    LMPresult1(w).LMP = Resultafter1(w).LMP([Para.storage(bidagent).Bus],:);
    LMPresult2(w).LMP = Resultafter2(w).LMP([Para.storage(bidagent).Bus],:);
    LMPresult3(w).LMP = Resultwith(w).LMP([Para.storage(bidagent).Bus],:);
end 
%% ����Data_mystructure��һ������
% for w = 1:Num.S
%     welfareESS_my(w,:) = Result1(w).cal.welfare.ESS;
%     welfaresocial_my(w) = Result1(w).cal.welfare.social;
% end 
% for w = 1:Num.S
%     sche_ESS(w,:) = Result1(w).QESSdis(1,:) - Result1(w).QESScha(1,:);
% end 