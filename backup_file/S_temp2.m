% 最后的过程
% ESS的利润(VCG机制下)
sum(VCG(w).ESSwelfare)
% ESS在LMP机制下的利润
sum(Result1(w).cal.welfare.ESS)
% 某天24小时的LMP
% Result1.LMP(1,:)
max(Result1.LMP(1,:)) - min(Result1.LMP(1,:))
%% 以下用来计算PAB下所有储能的利润
clear
load('210315\\Falsecost_0_5')
S_PABincome;


