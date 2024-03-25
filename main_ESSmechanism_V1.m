clear
Para.bigM = 100000;
Filename = 'IEEE5_V2';

%% sheet����
ESSsheet = 'ESS1.0';
[Rawdata_ESS,Name_ESS] = xlsread(Filename,ESSsheet);
Num.ESS = max(Rawdata_ESS(:,1));
Para.storage = F_ESSstructBuild(Rawdata_ESS,Num);
Demandsheet = 'D1.0';
[Rawdata_Demand,Name_Demand] = xlsread(Filename,Demandsheet);
Num.D = max(Rawdata_Demand(:,2));
Num.T = max(Rawdata_Demand(:,1));
Num.N = 5;

%% ����Generator
mpc = case5;
% Num.T = 6;
% Num.S = 2; %��P1.2�ĸ߷��ں͵͹��ڷ���һ��

Gsheet = 'G1.0';
[Rawdata_Supply,Name_Supply] = xlsread(Filename,Gsheet);
Num.I = max(Rawdata_Supply(:,1));
Para.generator = F_GstructBuild(Num, Rawdata_Supply);
for i = 1:Num.I
    Para.generator(i).Pmax =  Para.generator(i).Gmax * ones(Num.T,1);
    Para.generator(i).Pmin =  Para.generator(i).Gmin * ones(Num.T,1);
end 

% Num.I = size(mpc.gen,1); %���Լӿ�������Դ
% for i = 1:Num.I
%     Para.generator(i).GNum = i;
%     Para.generator(i).FNum = i;
%     Para.generator(i).type = 1; %������
%     Para.generator(i).bus =  mpc.gen(i,1);
%     Para.generator(i).Cmax = mpc.gen(i,9);
%     Para.generator(i).Cmin = mpc.gen(i,10);
%     Para.generator(i).Pmax =  Para.generator(i).Cmax * ones(Num.T,1);
%     Para.generator(i).Pmin =  Para.generator(i).Cmin * ones(Num.T,1);
%     Para.generator(i).cost = mpc.gencost(i,5);
% end
% Para.generator(2).cost = 30;
% Para.generator(3).cost = 14;

%% ����Demand

Para.demand = F_CstructBuild(Num, Rawdata_Demand);
for t = 1:Num.T
    for d = 1:Num.D
        Para.Tdemandquant(d,t) = Para.demand(d).Pmax(t);
        Para.Tdemandutility(d,t) =  Para.demand(d).Utility(t);
    end 
end 

%% ��������
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
%% ����Renewable,�ڵ�,�����۵�(���ﻹû����)
availableESS = [1 2];
%���е�һ�γ��壬�õ�����ƻ����ڵ���
Result1 = F_marketclearing(Num,Para,availableESS);
[Result1.welfare,Result1.income] = F_calculatewel_inc(Para,Result1,Num);
%% ȥ�����д��ܣ�����VCG payment�����ݴ�ʱ�õ�����ḣ����С��Ҳ��Ҫ�õ��ڵ���
 
Result2 = F_marketclearing(Num,Para,[]);
[Result2.welfare,Result2.income] = F_calculatewel_inc(Para,Result2,Num);

VCG.totalpayment = - Result2.welfare.GD + Result1.welfare.GD;
VCG.LMPpayment = sum(Result1.income.ESS);
%% �ڴ����ڲ�������Nash Bargaining���з��䡣���ȼ���d��Ȼ�����F��Ȼ�����alpha
VCG.d = Result1.income.ESS;
for nnESS = 1:Num.ESS
    ESSnode = Para.storage(nnESS).Bus;
    VCG.alpha(nnESS) = max(0,sum((Result1.LMP(ESSnode,:) + Result2.LMP(ESSnode,:)) .*...
        (Result1.QESSdis(nnESS,:) - Result1.QESScha(nnESS,:)))/2);
end 
if sum(VCG.alpha)~=0
    VCG.ESSincome = VCG.d + (VCG.totalpayment - VCG.LMPpayment) * VCG.alpha/sum(VCG.alpha);
else 
    VCG.ESSincome = 0;
end
%% ����G��D��������ḣ���ı仯���з���
Gwelfaredelta = Result1.welfare.generator - Result2.welfare.generator;
Dwelfaredelta = Result1.welfare.demand - Result2.welfare.demand;
Gallocateindex = max(Gwelfaredelta,0) / (sum(max(Gwelfaredelta,0)) + sum(max(Dwelfaredelta,0)));
Dallocateindex = max(Dwelfaredelta,0) / (sum(max(Gwelfaredelta,0)) + sum(max(Dwelfaredelta,0)));
VCG.Gpayment = Gallocateindex * (VCG.LMPpayment - VCG.totalpayment);
VCG.Dpayment = Dallocateindex * (VCG.LMPpayment - VCG.totalpayment);

%% ���幫ƽ��ָ�꣬��ANB�õ��ķ�������ô����ÿ���˴�����ĺô��������˴�����ǲ�һ����
% ���ǵ����õ�һ��ESS������ḣ���ļ�����
for nnESS = 1:Num.ESS
    tempavailESS = 1:Num.ESS;
    tempavailESS(nnESS)= [];
    Resulttemp = F_marketclearing(Num,Para,tempavailESS);
    [Resulttemp.welfare,Resulttemp.income] = F_calculatewel_inc(Para,Resulttemp,Num);
    ESScontribution(nnESS) = Result1.welfare.excludeESS(nnESS) - Resulttemp.welfare.social;
end 
%% ����Fariness index
Fairnessindex = 0;
for nnESS = 1:Num.ESS
    Fairnessindex = Fairnessindex + (ESScontribution(nnESS)/VCG.ESSincome(nnESS) - mean(ESScontribution./VCG.ESSincome))^2;
end 
Fairnessindex = Fairnessindex/Num.ESS;

%% ����SharpleyValue

for no = 0:2^(Num.ESS)-1
    strno = dec2bin(no);
    strno = [repmat('0',1,Num.ESS-length(strno)) strno];
    tempavailESS = find(strno == '1');
    Resulttemp = F_marketclearing(Num,Para,tempavailESS);
    [Resulttemp.welfare,Resulttemp.income] = F_calculatewel_inc(Para,Resulttemp,Num);
    coalitionSharpley(no+1) = - Result2.welfare.GD + Resulttemp.welfare.GD;
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

%% �Ƚ�һ��ESSsharpley,ESScontribution��VCG.ESSincome

%% ����Sharpley value


