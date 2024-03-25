%% ���ڴ��ܶ��ԣ�������һ������������߼�/VCG�����⣬����Ҫ�б�ġ�


% 200403 �����ִ����뿪�г�ʱ�����ഢ�ܰ�ԭ�ƻ������г�
%       ������ԭ�ƻ������г�(clearing1)/�������ܲ����г�(clearing2)�����������ǲ�һ���ģ����������������ܽ��мƻ�������ǰ�߲�����

% 200516 ������һ��ȱ��!���ܿ���һ������ӵ�ж��ESS
% ���ű�������������
    % ����ȫԱ����ʱ�ĳ����븣������������ESS������ʱ�ĳ����븣����ȷ��VCG��payment�����ǲ���Market Clearing 1)
    % ����Asymmetric NB����ÿ��ESS�ĸ���
    % ��ESS֮����з�̯
    % ����fairness index������ÿ�������marginal contribution

% ��Ҫʵ������Ŀ�꣬�Ƚ�VCG payment��LMP payment,VCG payment��LMP
    % payment��ܶ࣬Ӧ���ǰ���������㣬�԰ɣ�
% �Ƚ�VCG payment �� modified VCG payment�����߱ȽϽӽ����㹻��ƽ����ʱ�٣�

% 200518 ����Ϊcase118�Ķ���

% 200519 V4,����VCG payment

% 201130 V5,����һϵ���޸ģ�������ܼܹ����޸�
    % ����VCG����֮��ESS��profit
    % ����Result Structure��˵��
    % Result1 �����ܲ�������
    % Result2 �������д��ܲ���������
    % Resulttemp ��һ��ESS�˳������


clear
choose_scenario = 0;
S_datainput;
falserate = 1; %������߱��۵ı���
falseagent = 1:Num.ESS; %��ʾ��߱��۵�agent,1,5
falserate_SOC = 1; %������߱�SOC valuation�ı���
Para.dualresult = 0;
%% �趨���ʵ�available ESS
availableESS = 1:Num.ESS;% ֻ�е�һ��ESS��available��


%% ��degredation cost���г���,����������˵�ٻ��µ����
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
%% �������ESSschedule
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
%% ȥ�����д��ܽ��г���, ����VCG 
% ESSschedule.cha = Result1.QESScha;
% ESSschedule.dis = Result1.QESSdis;
% ȥ�����д��ܣ�����VCG payment�����ݴ�ʱ�õ�����ḣ����С��Ҳ��Ҫ�õ��ڵ���
 % ��ʱ��ʼ��
availableESS = [];
excludeESS = setdiff(1:Num.ESS,availableESS);

for w = 1:Num.S
    t0 = cputime;
    Para = F_modifyESScost(Para,Num,falserate,falseagent);
    Resulttemp = F_marketclearing_V1_4(Num,Para,availableESS,w);
    Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Result2(w) = Resulttemp;
    % ������Ҫ������Ǵ��ܵ�����֧��
    VCG(w).totalpayment = - Result2(w).cal.welfare.GD + Result1(w).cal.welfare.GD; %�������ܵ���ḣ������
    VCG(w).LMPpayment = sum(Result1(w).cal.income.ESS(excludeESS)); %���Ǹ�����ESS��LMP payment�������ǵĸ���
    time_wholeVCG(w) = cputime - t0;
end 
% save('210315\\FalseSOC_1_3')

%% �ڴ����ڲ�������Nash Bargaining���з��䡣���ȼ���d��Ȼ�����F��Ȼ�����alpha
for w = 1:Num.S
    t0 = cputime;
    %ȷ��disagreement point
    VCG(w).d = Result1(w).cal.income.ESS; 
    %ȷ��alphaֵ
    for nnESS = 1:Num.ESS
        ESSnode = Para.storage(nnESS).Bus;
%         VCG(w).alpha(nnESS) = max(0,sum((Result1(w).LMP(ESSnode,:) + Result2(w).LMP(ESSnode,:)) .*...
%         (Result1(w).QESSdis(nnESS,:) - Result1(w).QESScha(nnESS,:)))/2);
          VCG(w).alpha(nnESS) = sum((Result1(w).LMP(ESSnode,:) + Result2(w).LMP(ESSnode,:)) .*...
               (Result1(w).QESSdis(nnESS,:) - Result1(w).QESScha(nnESS,:)))/2
    end 
    %ȷ�����յ�ÿ��ESS��payment
    if sum(VCG(w).alpha)~=0
        VCG(w).ESSincome = VCG(w).d + (VCG(w).totalpayment - VCG(w).LMPpayment) * VCG(w).alpha/sum(VCG(w).alpha);
    else 
        VCG(w).ESSincome = 0;
    end
    VCG(w).ESSwelfare = VCG(w).ESSincome - Result1(w).cal.cost.ESS + Result1(w).cal.utility.ESS; % ����VCG����֮��ESS��profit
    %% ����G��D��������ḣ���ı仯���з���
    VCG(w).Gwelfaredelta = Result1(w).cal.welfare.generator - Result2(w).cal.welfare.generator;
    VCG(w).Dwelfaredelta = Result1(w).cal.welfare.demand - Result2(w).cal.welfare.demand;
    VCG(w).Gallocateindex = max(VCG(w).Gwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Dallocateindex = max(VCG(w).Dwelfaredelta,0) / (sum(max(VCG(w).Gwelfaredelta,0)) + sum(max(VCG(w).Dwelfaredelta,0)));
    VCG(w).Gpayment = VCG(w).Gallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
    VCG(w).Dpayment = VCG(w).Dallocateindex * (VCG(w).LMPpayment - VCG(w).totalpayment);
    time_ANB(w) = cputime - t0; %����ANB��ʱ��
    %�����Զ���һ��VCG����֮�¸�������Ӧ����֧��/������
end
%% ���幫ƽ��ָ�꣬��ANB�õ��ķ�������ô����ÿ���˴�����ĺô��������˴�����ǲ�һ����
% ���ǵ����õ�һ��ESS������ḣ���ļ�����

for w = 1:Num.S
    t0 = cputime;
    for nnESS = 1:Num.ESS
        tempavailableESS = 1:Num.ESS;
        tempavailableESS(nnESS)= [];


%         t0 = cputime;
        Para = F_modifyESScost(Para,Num,falserate,falseagent);
        Resulttemp = F_marketclearing_V1_4(Num,Para,tempavailableESS,w);
        Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
        Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
        VCG(w).ESScontribution(nnESS) = Result1(w).cal.welfare.excludeESS(nnESS) - Resulttemp.cal.welfare.social;
    end 
    time_distributeVCG(w) = cputime - t0;
end 

    %% ����Fariness index
%     VCG(w).Fairnessindex = 0;
%     for nnESS = 1:Num.ESS
%         VCG(w).Fairnessindex = VCG(w).Fairnessindex + (VCG(w).ESScontribution(nnESS)/VCG(w).ESSincome(nnESS) - mean(VCG(w).ESScontribution./VCG(w).ESSincome))^2;
%     end 
%     VCG(w).Fairnessindex = VCG(w).Fairnessindex/Num.ESS;
for w = 1:Num.S
    VCG(w).Fairnessindex = 0;
    totalcontribution(w) = sum(VCG(w).ESScontribution);
    totalincome(w) = sum(VCG(w).ESSincome);
    
    tempset = [];
    for nnESS = 1:Num.ESS
        if abs(VCG(w).ESScontribution(nnESS)) > 1e-4
            tempindex(nnESS) = VCG(w).ESSincome(nnESS) * totalcontribution(w)/VCG(w).ESScontribution(nnESS)/ totalincome(w);
            % tempindex��ʾ��Ե�Ť���̶�
            VCG(w).Fairnessindex = VCG(w).Fairnessindex + abs(VCG(w).ESSincome(nnESS) * totalcontribution(w)/VCG(w).ESScontribution(nnESS)/ totalincome(w) - 1);
            tempset = [tempset nnESS];
        end 
    end 
    VCG(w).Fairnessindex = VCG(w).Fairnessindex/max(1,length(tempset));
end


save('210315\\Time_Test')
time_ANB + time_clear + time_wholeVCG
time_clear + time_distributeVCG
% temp = [];
% for i = 1:8
% temp = [temp; sum(VCG(i).Gallocateindex) sum(VCG(i).Dallocateindex)];
% end