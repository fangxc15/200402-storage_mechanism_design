% ���ű���������optimal_bidding�����������г���Ӱ��
%  Resultoriginָ����û�д��ܲμӵ�ʱ��
%  Resultafterָ�����д���optimal bidding��ĳ�����

% ��������ԭ�����ǰ���������Ƶ�Ͷ��ṹ����ġ���Ȼ������ô�õ����顣��

clear
choose_scenario = 1;
S_datainput;
Para.dualresult = 0;
allagent = 1:Num.ESS;
bidagent = 1:2; %Ӧ��ֻ��һ��bid agent��Ҫ��Ȼ�Ǹ�����
tempavailableESS = setdiff(allagent,bidagent);
for w = 1:Num.S
    % û��ESS�ĳ���
    Resulttemp = F_marketclearing_V1_4(Num,Para,setdiff(allagent,bidagent),w); % û����Щ��Ͷ�괢��1ʱ�Ľ��
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Resultorigin(w) = Resulttemp;
    Para.scenario(w).price = Resultorigin(w).LMP([Para.storage.Bus],:)'; %���������Լ۸��Ӱ�죬��û�д��ܵ�ʱ��õ�һ���߼ʼ۸�
    % ӵ��ESS�ĳ���
    Resulttemp = F_marketclearing_V1_4(Num,Para,allagent,w); % �д���1ʱ�Ľ��
    Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
    Resultwith(w) = Resulttemp;
end 
%
Resultbid1 = F_stochastic_bidding_1_2(Para,bidagent,Num);
Resultbid2 = F_stochastic_bidding_2_2(Para,bidagent,Num);
%%  �ؼ��ǻ�Ҫ����֮�����ḣ����ô�䣿
clear ESSschedule
Resultafter1 = F_generatesocial(Resultbid1,bidagent,Num,Para,allagent);
Resultafter2 = F_generatesocial(Resultbid2,bidagent,Num,Para,allagent);
mkdir('240128_newBidding')
save('240128_newBidding\\Data_optimal_bidding_agent12');
% save('210315\\Data_optimal_bidding_onlyagent1');
%%
S_replot_data;
%%
% �鿴ƽ����ḣ������
save('240128_newBidding\\Data_optimal_bidding_agent12');

