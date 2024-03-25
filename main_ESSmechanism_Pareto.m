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
    
% 240101 V6,ȥ���г����Ż����㺯��


clear
choose_scenario = 0;
S_datainput;
falserate = 1; %������߱��۵ı���
falseagent = 1:Num.ESS; %��ʾ��߱��۵�agent,1,5
falserate_SOC = 1; %������߱�SOC valuation�ı���
Para.dualresult = 0;


%% �趨���ʵ�available ESS
availableESS = 1:Num.ESS;% ֻ�е�һ��ESS��available��

Para.maxSW = 8.3067e+06;
%% ��degredation cost���г���
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
%% �������ESSschedule
for nnESS = 1:Num.ESS
    for w = 1:Num.S
        ESSschedule(nnESS).scene(w).dis = Result1(w).QESSdis(nnESS,:);
        ESSschedule(nnESS).scene(w).cha = Result1(w).QESScha(nnESS,:);
    end 
end 
%% ���ǷֶεĲ����ͳ���
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

% ���Ƿֶεĳ���
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

%% ��ͼ
% load('240129//IC_test_FalseCost_1.mat')
version_suffix =  '_newICver';            
Picture_root_folder = ['Picture', version_suffix];  
mkdir(Picture_root_folder);

Picture_folder = Picture_root_folder;
mkdir(Picture_folder);

F_plot_Pareto(1,Result_matrix, Para,Picture_folder) %1719.05����֧��ƽ����
%% 

sum(Result1(1).cal.welfare.ESS)
sum(Result1(1).cal.income.ESS)
Result1(1).IC_cal.welfare.ESS_choose
Result1(1).IC_cal.income.ESS_choose


% LMP�����´��ܵ�welfareΪ874.67, ����Ϊ29173
% ��IC=0��ʱ�򣬴��ܵ�welfareΪ2410.7������Ϊ30709

% VCG�����¼��������֧��Ϊ30741,�����IC=0����µ�֧������һ��
%%
 % ���Ǽ��㴢�ܵ�����
mkdir('240102')
save('240102\\Pareto_test') %��������Ѿ������ǲ��Ե������ˣ�



% time_ANB + time_clear + time_wholeVCG
% time_clear + time_distributeVCG
