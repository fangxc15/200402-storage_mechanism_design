%% ������Pareto����Ļ����ϣ�����������һ�����testIC�Ļ���. ����ⲿ��������һ��ѭ��.

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
    
% 240101 ����IC��conclusionȥ������㺯��
% 240102 ȥ������֤���������ԣ����еĴ��ܶ�����������������


% clear
falserate = 1; %������߱��۵ı���
falserate_SOC = 1; %������߱�SOC valuation�ı���
choose_scenario = 0;
S_datainput;
falseagent = 1:Num.ESS; %��ʾ��߱��۵�agent,1,5
Para.dualresult = 0;

%% �趨���ʵ�available ESS
availableESS = 1:Num.ESS;% ֻ�е�һ��ESS��available��

Para.maxSW = 8.3067e+06;

%% ����һ����Para�ͼ�Para
Para_true = Para;
Para_false = Para;
Para_false = F_modifyESScost(Para_false,Num,falserate,falseagent);
Para_false = F_modifyESSvaluation(Para_false,Num,falserate_SOC,falseagent);

%% ��degredation cost���г���.
% [Result1,time_clear] = F_getresult(Num,Para,availableESS);
 for w = 1:Num.S 
        t0 = cputime;
%         Para = F_modifyESScost(Para,Num,falserate,falseagent);
%         Para = F_modifyESSvaluation(Para,Num,falserate_SOC,falseagent);
        Resulttemp = F_marketclearing_V1_4(Num,Para_false,availableESS,w);    
%         Para = F_modifyESScost(Para,Num,1/falserate,falseagent);
%         Para = F_modifyESSvaluation(Para,Num,1/falserate_SOC,falseagent);
        % ���������ԭ��ȥ���㸣��
        Resulttemp.cal = F_calculatewel_inc_V3(Para_true,Resulttemp,Num,w);
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
%% ���ǷֶεĲ����ͳ��壬������涼ֻ�Ǹı���㺯������
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
% ���Ƿֶεĳ���
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
for chooseIC = 0:0.001:0.3 % ���������ڲ�ͬ����µĽ��㺯����Ȼ�󻭳�Pareto Frontier
    Setting.kIC=chooseIC;
    Result_temp = F_cal_IC_welfare(Result_pno,Result1,Para_false,Num,1,Setting,choose_ESS);
    if chooseIC == 0
        Result1 = Result_temp;
    end
    % Result1.IC_cal.welfare.ESS_choose
    % sum(Result1.cal.welfare.ESS)
%     sum(Result1.cal.welfare.ESS) - Result1.IC_cal.welfare.ESS_choose;

    % �������Ǽٶ�����ʵ�걨������ô��������Ļ��ͻ�������ˣ�
    Result_matrix = [Result_matrix;...
        chooseIC sum(Result1.cal.income.ESS) - Result_temp.IC_cal.income.ESS_choose]; 
    
    % Ϊʲô��֧��ƽ����������ô���㣿IC_cal�Ǹ��������Ǹ���ʽ����Ľ��㺯������cal�Ǹ���LMP����Ľ��㺯��
    % ��һ����IC�ɳ������ڶ�������֧ӯ����
    
    
    % ���������ǲ�ƽ����, ICrelax, welfare, income . welfare��real_welfare�Ĳ����ʲô��
    Result_ESS_matrix = [Result_ESS_matrix; ...
            chooseIC Result_temp.IC_cal.welfare.ESS_choose Result_temp.IC_cal.income.ESS_choose ...
                      Result_temp.IC_cal.real_welfare.ESS_choose]; 
                  
    % ������ǰ��������
end
% load('240129//IC_test_FalseCost_1.mat')
version_suffix =  '_newICver';            
Picture_root_folder = ['Picture', version_suffix];  
mkdir(Picture_root_folder);

Picture_folder = Picture_root_folder;
mkdir(Picture_folder);

F_plot_Pareto(1,Result_matrix, Para,Picture_folder) %1719.05����֧��ƽ����

% F_plot_Pareto(1,Result_matrix, Para) %1719.05����֧��ƽ����
%% 

% ������Ҫ��������ʵ�걨�ı����£���LMP.VCG.kIC�������ܻ�ȡ������/BB���

sum(Result1(1).cal.welfare.ESS)      % �����LMP�����µ�����
sum(Result1(1).cal.income.ESS)
Result1(1).IC_cal.welfare.ESS_choose % ����൱��VCG�����µ�welfare������
Result1(1).IC_cal.income.ESS_choose



Setting.kIC=0.1; % ���ȷ��Ӧ�ø���kIC�ܽ��ܵ����޺�BB�ܽ��ܵ����޿���ȷ��
% ��ʵ��һ����ֻ�ǽ����������в��
Result_chooseIC = F_cal_IC_welfare(Result_pno,Result1,Para_false,Num,1,Setting,choose_ESS);
Result_chooseIC.IC_cal.welfare.ESS_choose 
Result_chooseIC.IC_cal.income.ESS_choose 
Result_chooseIC.IC_cal.real_welfare.ESS_choose

%kIC = 0.1ʱ�Ľ���������������29660�����ܸ���1361.8���������ڸ���1361.8

% LMP�����´��ܵ�welfareΪ874.67, ����Ϊ29173
% ��IC=0��ʱ�򣬴��ܵ�welfareΪ2461.2������Ϊ30760. ������ḣ�����׼��������2442.6
% VCG�����¼��������֧��Ϊ30741,�����IC=0����µ�֧������һ��
%   ��ʱIC=0��ʱ��, welfare��2461.2��������30760
%       IC=0.037,  welfare��1485.9�� ������29785
%       IC=0.06,   welfare��1035.7, ������29334


% ������лѱ�1.1������ḣ������2438.2
%  ����LMP���㣬��ʱwelfare 1004.6, ������29238
%   ��ʱIC=0��ʱ��, welfare��2176.4��������30720, ��ʵ��welfare 2486.4
%       IC=0.037,  welfare��1261.7�� ������29805, ��ʵ��welfare 1571.7
%       IC=0.06,   welfare��823.0, ������29366, ��ʵ��welfare 1133.0

% ������лѱ�1.2������ḣ������2377.2
%  ����LMP���㣬��ʱwelfare 1169.4, ������28981
%   ��ʱIC=0��ʱ��, welfare��1800.5��������30148, ��ʵ��welfare 2336.1
%       IC=0.037,  welfare��976.6�� ������29324, ��ʵ��welfare 1512.3
%       IC=0.06,   welfare��592.8, ������28940, ��ʵ��welfare 1128.4

% ������лѱ�1.4������ḣ������2145
%  ����LMP���㣬��ʱwelfare 1225.4, ������28205
%   ��ʱIC=0��ʱ��, welfare��1430.8��������29107, ��ʵ��welfare 2157.2
%       IC=0.037,  welfare��678.6�� ������28354, ��ʵ��welfare 1405.0
%       IC=0.06,   welfare��406.9, ������28083, ��ʵ��welfare 1133.3

% Ϊʲô��ʱ����ḣ������Ӧ����2145����IC=0���������welfare��2335.4/1609.0��
% ��������õ���ֵ����
% ����������ḣ�����������֤��������ȷ�ģ���ḣ�����׵�ȷ��2145��

Result_pno(1).cal.welfare.social  
Result_pno(21).cal.welfare.social 
Result_pno(1).obj  
Result_pno(21).obj 
% �о����԰�����ô�ѱ����ѱ�ȥ���ֵ���ḣ��������
%%
 % ���Ǽ��㴢�ܵ�����
% mkdir('240102')
save_name = ['240129','\\','IC_test_FalseSOC_',num2str(falserate_SOC)];
save(save_name)
% save('240129\\Pareto_test')



% time_ANB + time_clear + time_wholeVCG
% time_clear + time_distributeVCG
%% ��μ���S^IC
sum([Para.storage.Pchamaxb] .* [Para.storage.chacost] * 0.4) * 2 %�����ܹ��Ļѱ�����
% �ѱ������ٳ��Գ�������
(1169.4-874.7)/(3752/2)

