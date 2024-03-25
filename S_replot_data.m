% 储能是在IEEE118节点上，但没什么阻塞。出清的尖峰负荷下降？

% 需要输入和bidding相关的数据
Picture_folder = 'Picture_agent12';
mkdir(Picture_folder)
set(groot,'defaultfigurePosition',[200 200 480 380]);
%     set(groot,'defaultLegendFontName','Times New Roman');
set(groot,'defaultLegendFontSize',13);
set(groot,'defaultAxesFontSize',13);
%     set(groot,'defaultFontSize',14);

set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultAxesFontName',['SimSun']);

set(0,'defaultfigurecolor','w'); %设置背景颜色为白色

ifsave = 1;
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
    welfareESS0(:,w) = Resultorigin(w).cal.welfare.ESS'; %原来的情况
    welfareESS1(:,w) = Resultafter1(w).cal.welfare.ESS'; %自调度投标
    welfareESS2(:,w) = Resultafter2(w).cal.welfare.ESS'; %EB投标
    welfareESS3(:,w) = Resultwith(w).cal.welfare.ESS';   % 市场调度
end 
welfareESS_matrix = [sum(welfareESS0(bidagent,:),1)
                    sum(welfareESS1(bidagent,:),1) 
                    sum(welfareESS2(bidagent,:),1)
                    sum(welfareESS3(bidagent,:),1)];
%%
figure(1)

b = bar(welfareESS_matrix(2:4,[1:3,5:8])');
colors = [0.93 0.92 0.27;
          0.16 0.87 0.58;
          0.5 0.7 0.9];
for i = 1:6
    line([i+0.5,i+0.5],[-500,1500],'color', 'k','LineStyle','--')
end
set(b(1),'FaceColor',colors(1,:))
set(b(2),'FaceColor',colors(2,:))
set(b(3),'FaceColor',colors(3,:))


% xlabel('场景集')
ylabel('储能利润 ($)')
legend('场景SS-Bid','场景EB-Bid','场景DC-Bid','Location','NorthWest')
legend('boxoff')
set(gca,'ygrid','on')
set(gca,'Ticklength',[0,0])
set(gca,'xaxislocation','top');
set(gca,'XTick',1:7,'XTickLabel',{'场景1','场景2','场景3','场景4', ...
    '场景5','场景6','场景7'})

% set(gca,'XTicklabel',[])
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','ESS_profit_cmp.png']);
    saveas(1,[Picture_folder,'/','ESS_profit_cmp.jpg'])
end
%%
% 然后还要考虑社会福利
for w = 1:Num.S
    welfaresocial0(w) = Resultorigin(w).cal.welfare.social;
    welfaresocial1(w) = Resultafter1(w).cal.welfare.social; %自调度投标
    welfaresocial2(w) = Resultafter2(w).cal.welfare.social; % EB投标
    welfaresocial3(w) = Resultwith(w).cal.welfare.social;    % 市场调度
end 
welfare_matrix = [welfaresocial0;welfaresocial1;welfaresocial2;welfaresocial3];
delta_welfare = welfare_matrix - repmat(welfare_matrix(1,:),4,1);
%%
figure(2)
b = bar(delta_welfare(2:4,[1:3,5:8])');
colors = [0.93 0.92 0.27;
          0.16 0.87 0.58;
          0.5 0.7 0.9];
for i = 1:6
    line([i+0.5,i+0.5],[-500,1500],'color', 'k','LineStyle','--')
end
set(b(1),'FaceColor',colors(1,:))
set(b(2),'FaceColor',colors(2,:))
set(b(3),'FaceColor',colors(3,:))

% xlabel('场景集')
ylabel('社会福利增量 ($)')
legend('场景SS-Bid','场景EB-Bid','场景DC-Bid','Location','NorthWest')
legend('boxoff')
set(gca,'ygrid','on')
set(gca,'Ticklength',[0,0])
set(gca,'xaxislocation','top');
set(gca,'XTick',1:7,'XTickLabel',{'场景1','场景2','场景3','场景4', ...
    '场景5','场景6','场景7'})

% set(gca,'ygrid','on')
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','Welfare_cmp.png']);
    saveas(2,[Picture_folder,'/','Welfare_cmp.jpg'])
end
%% 对比ESS的计划(bidagent)和总共的充放电量
for w = 1:Num.S
    ESSschedule0(w).schedule = sum(Resultorigin(w).QESScha(bidagent,:),1)' - sum(Resultorigin(w).QESSdis(bidagent,:),1)';
    ESSschedule1(w).schedule = sum(Resultafter1(w).QESScha(bidagent,:),1)' - sum(Resultafter1(w).QESSdis(bidagent,:),1)';
    ESSschedule2(w).schedule = sum(Resultafter2(w).QESScha(bidagent,:),1)' - sum(Resultafter2(w).QESSdis(bidagent,:),1)';
    ESSschedule3(w).schedule = sum(Resultwith(w).QESScha(bidagent,:),1)' - sum(Resultwith(w).QESSdis(bidagent,:),1)';
%     ESSschedule0(w).sum_Q = sum(sum(Resultorigin(w).QESScha(bidagent,:) + Resultorigin(w).QESSdis(bidagent,:)));
%     ESSschedule1(w).sum_Q = sum(sum(Resultafter1(w).QESScha(bidagent,:) + Resultafter1(w).QESSdis(bidagent,:)));
%     ESSschedule2(w).sum_Q = sum(sum(Resultafter2(w).QESScha(bidagent,:) + Resultafter2(w).QESSdis(bidagent,:)));
%     ESSschedule3(w).sum_Q = sum(sum(Resultwith(w).QESScha(bidagent,:) + Resultwith(w).QESSdis(bidagent,:)));
end 
ESSsumQ_matrix = [sum(abs([ESSschedule0.schedule]),1)
                sum(abs([ESSschedule1.schedule]),1)
                sum(abs([ESSschedule2.schedule]),1)
                sum(abs([ESSschedule3.schedule]),1)];
%%
figure(3)
b = bar(ESSsumQ_matrix(2:4,[1:3,5:8])');
colors = [0.93 0.92 0.27;
          0.16 0.87 0.58;
          0.5 0.7 0.9];
for i = 1:6
    line([i+0.5,i+0.5],[0,600],'color', 'k','LineStyle','--')
end
set(b(1),'FaceColor',colors(1,:))
set(b(2),'FaceColor',colors(2,:))
set(b(3),'FaceColor',colors(3,:))

% xlabel('场景集')
ylabel('储能的充放电总里程 (MWh)')
legend('场景SS-Bid','场景EB-Bid','场景DC-Bid','Location','NorthWest')
legend('boxoff')
set(gca,'ygrid','on')
set(gca,'Ticklength',[0,0])
set(gca,'xaxislocation','top');
set(gca,'XTick',1:7,'XTickLabel',{'场景1','场景2','场景3','场景4', ...
    '场景5','场景6','场景7'})

% set(gca,'ygrid','on')
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','ESS_Q_cmp.png']);
    saveas(3,[Picture_folder,'/','ESS_Q_cmp.jpg'])
end
    %%

% 对比当时的市场价格
choose_agent = 1; % 选择哪个储能节点的市场价格
for w = 1:Num.S
    LMPresult0(w).LMP = Resultorigin(w).LMP([Para.storage(choose_agent).Bus],:)';
    LMPresult1(w).LMP = Resultafter1(w).LMP([Para.storage(choose_agent).Bus],:)';
    LMPresult2(w).LMP = Resultafter2(w).LMP([Para.storage(choose_agent).Bus],:)';
    LMPresult3(w).LMP = Resultwith(w).LMP([Para.storage(choose_agent).Bus],:)';
end 

% choose_S = 1;
LMPdiffmatrix = zeros(4,Num.S);
%计算高峰低谷价差
LMPdiffmatrix = [max([LMPresult0.LMP]) - min([LMPresult0.LMP])
                max([LMPresult1.LMP]) - min([LMPresult1.LMP])
                max([LMPresult2.LMP]) - min([LMPresult2.LMP])
                max([LMPresult3.LMP]) - min([LMPresult3.LMP])];
% for choose_S = 1:Num.S
%     LMPdiffmatrix(:,choose_S) = [max(LMPresult0(choose_S).LMP) - min(LMPresult0(choose_S).LMP)
%                      max(LMPresult1(choose_S).LMP) - min(LMPresult1(choose_S).LMP)
%                     max(LMPresult2(choose_S).LMP) - min(LMPresult2(choose_S).LMP)
%                     max(LMPresult3(choose_S).LMP) - min(LMPresult3(choose_S).LMP)];
% end
%%
choose_S = 5; %1或者5比较好
LMPmatrix = [LMPresult0(choose_S).LMP LMPresult1(choose_S).LMP LMPresult2(choose_S).LMP LMPresult3(choose_S).LMP];
%% 这个是画节点边际价格
figure(4)
plot(LMPmatrix,'LineWidth',1)
legend('无储能','场景SS-Bid','场景EB-Bid','场景DC-Bid','Location','SouthWest')
xlabel('时段')
ylabel('节点边际价格 ($/MWh)')
% legend('场景SS-Bid','场景EB-Bid-Bid','场景DC-Bid','Location','NorthWest')
legend('boxoff')
grid on
% set(gca,'ygrid','on')
set(gca,'Ticklength',[0,0])
% set(gca,'xaxislocation','top');
% set(gca,'XTick',1:7,'XTickLabel',{'场景1','场景2','场景3','场景4', ...
%     '场景5','场景6','场景7'})
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','LMP_cmp.png']);
    saveas(4,[Picture_folder,'/','LMP_cmp.jpg'])
end
%% 出清的尖峰负荷下降. 也不知道其他储能怎么处理的。这里其实要算的是peak net demand
peakL_matrix = zeros(4,Num.S);
for w = 1:Num.S %(sum(Resultorigin(w).QD,1)
    Dschedule0(w).schedule = Para.sumnetdemand(:,w) - sum(Resultorigin(w).QESSdis,1)' + sum(Resultorigin(w).QESScha,1)';
    Dschedule1(w).schedule = Para.sumnetdemand(:,w) - sum(Resultafter1(w).QESSdis,1)' + sum(Resultafter1(w).QESScha,1)';
    Dschedule2(w).schedule = Para.sumnetdemand(:,w) - sum(Resultafter2(w).QESSdis,1)' + sum(Resultafter2(w).QESScha,1)';
    Dschedule3(w).schedule = Para.sumnetdemand(:,w) - sum(Resultwith(w).QESSdis,1)' + sum(Resultwith(w).QESScha,1)';
%     peakL_matrix(:,w) = [max(Dschedule0(w).schedule)
%                         max(Dschedule1(w).schedule)
%                         max(Dschedule2(w).schedule)
%                         max(Dschedule3(w).schedule)];
end 
peaknetL_matrix = [max([Dschedule0.schedule])
                max([Dschedule1.schedule])
                max([Dschedule2.schedule])
                max([Dschedule3.schedule])];
% 这个peak load感觉除了场景8没什么下降，很尴尬啊。

%% 画出为什么会出现福利损失, 同时展现价格和充放电量

% 这里要一起画。
choose_S = 2;
LMPprofile = LMPresult1(choose_S).LMP;
ESSprofile = ESSschedule1(choose_S).schedule;

figure(6)
yyaxis left
b = bar(ESSprofile);
b.FaceColor = [0.5 0.7 0.9];
ylabel('储能的充放电功率 (MW)')
% ylim([-50 50])
% yticks(-50:25:50)
% set(b,'YTicks',-50:25:50)

yyaxis right
b = area(LMPprofile)
b.FaceAlpha = 0.2;
ylim([40,70])
% plot(LMPprofile,'LineWidth',1)
ylabel('节点边际价格 ($/MWh)')
xlabel('时段')
xlim([1 24])
set(gca,'XTick',0:4:24)
set(gca,'Ticklength',[0,0])
grid on 
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','Price_Q_profile.png']);
    saveas(6,[Picture_folder,'/','Price_Q_profile.jpg'])
end
% hold on 

%%
outresult.delta_welfare = delta_welfare;
outresult.delta_welfare_weightsum = delta_welfare * [Para.scenario.prob]';
outresult.welfareESS = welfareESS_matrix;
outresult.welfareESS_weightsum = welfareESS_matrix  * [Para.scenario.prob]';
outresult.ESSsumQ = ESSsumQ_matrix;
outresult.ESSsumQ_weightsum = ESSsumQ_matrix * [Para.scenario.prob]';
