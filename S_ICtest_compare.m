% 本部分用来展现在不同的S^{IC}下，储能不同策略下的效用。

ifsave = 1;
version_suffix =  '_newICver';            
Picture_root_folder = ['Picture', version_suffix];  
mkdir(Picture_root_folder);
Picture_folder = Picture_root_folder;

Result_true = load('240129\\IC_test_FalseCost_1');
Result_1_1 = load('240129\\IC_test_FalseCost_1_1');
Result_1_2 = load('240129\\IC_test_FalseCost_1_2');
Result_1_4 = load('240129\\IC_test_FalseCost_1_4');
Result_1_6 = load('240129\\IC_test_FalseCost_1_6');
Result_1_8 = load('240129\\IC_test_FalseCost_1_8');
Result_0_5 = load('240129\\IC_test_FalseCost_0_5');
Result_0_8 = load('240129\\IC_test_FalseCost_0_8');
Result_0_9 = load('240129\\IC_test_FalseCost_0_9');
Result_SOC_0_8 = load('240129\\IC_test_FalseSOC_0_8');
Result_SOC_0_9 = load('240129\\IC_test_FalseSOC_0_9');
Result_SOC_1_1 = load('240129\\IC_test_FalseSOC_1_1');
Result_SOC_1_2 = load('240129\\IC_test_FalseSOC_1_2');

welfare_offset = -Result_true.Result1.cal.welfare.social + 2442.6;

% 这个第四列代表的是real_welfare
% plot_matrix = [Result_true.Result_ESS_matrix(:,4) Result_1_1.Result_ESS_matrix(:,4) ...
%     Result_1_2.Result_ESS_matrix(:,4) Result_1_4.Result_ESS_matrix(:,4)];
plot_matrix = [Result_true.Result_ESS_matrix(:,4) Result_1_1.Result_ESS_matrix(:,4) ...
     Result_1_2.Result_ESS_matrix(:,4) Result_1_4.Result_ESS_matrix(:,4) Result_1_6.Result_ESS_matrix(:,4) ...
     Result_1_8.Result_ESS_matrix(:,4) Result_0_5.Result_ESS_matrix(:,4) Result_0_8.Result_ESS_matrix(:,4) ...
     Result_0_9.Result_ESS_matrix(:,4) Result_SOC_0_8.Result_ESS_matrix(:,4)  Result_SOC_0_9.Result_ESS_matrix(:,4) ...
     Result_SOC_1_1.Result_ESS_matrix(:,4) Result_SOC_1_2.Result_ESS_matrix(:,4)];
% 再来找一个代表BB的来做

welfare_result = [ Result_true.Result1.cal.welfare.social
                   Result_1_1.Result1.cal.welfare.social
                   Result_1_2.Result1.cal.welfare.social
                   Result_1_4.Result1.cal.welfare.social
                   Result_1_6.Result1.cal.welfare.social
                   Result_1_8.Result1.cal.welfare.social
                   Result_0_5.Result1.cal.welfare.social
                   Result_0_8.Result1.cal.welfare.social
                   Result_0_9.Result1.cal.welfare.social
                   Result_SOC_0_8.Result1.cal.welfare.social
                   Result_SOC_0_9.Result1.cal.welfare.social
                   Result_SOC_1_1.Result1.cal.welfare.social
                   Result_SOC_1_2.Result1.cal.welfare.social];
%%
% 2442.6/2438.2/2377.2/2145.0
plot_matrix(:,1) = plot_matrix(:,1) - plot_matrix(1,1) + 2442.6;
plot_matrix(:,2) = plot_matrix(:,2) - plot_matrix(1,2) + 2438.2;
plot_matrix(:,3) = plot_matrix(:,3) - plot_matrix(1,3) + 2377.2;
plot_matrix(:,4) = plot_matrix(:,4) - plot_matrix(1,4) + 2145.0;

plot_matrix(:,5) = plot_matrix(:,5) - plot_matrix(1,5) + 1867.7;
plot_matrix(:,6) = plot_matrix(:,6) - plot_matrix(1,6) + 1585.5;
plot_matrix(:,7) = plot_matrix(:,7) - plot_matrix(1,7) +  947.5;
plot_matrix(:,8) = plot_matrix(:,8) - plot_matrix(1,8) + 2218.6;
plot_matrix(:,9) = plot_matrix(:,9) - plot_matrix(1,9) + 2441.3;

plot_matrix(:,10) = plot_matrix(:,10) - plot_matrix(1,10) -329.4;
plot_matrix(:,11) = plot_matrix(:,11) - plot_matrix(1,11) + 790.6;
plot_matrix(:,12) = plot_matrix(:,12) - plot_matrix(1,12) + 1302.8;
plot_matrix(:,13) = plot_matrix(:,13) - plot_matrix(1,13) + 1302.8;


plot_x = Result_true.Result_ESS_matrix(:,1);


set(groot,'defaultLegendFontSize',12);
set(groot,'defaultAxesFontSize',13);
%     set(groot,'defaultFontSize',14);

set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultAxesFontName',['SimSun']);

set(0,'defaultfigurecolor','w'); %设置背景颜色为白色
set(groot,'defaultfigurePosition',[200 200 480 420]);

figure(1)
ha = area(plot_x,plot_matrix(:,1));
ha.FaceAlpha = 0.3;
ha.FaceColor = [0.12 0.37 0.82];

hold on
hb = plot(plot_x,plot_matrix(:,2:5),'--','Linewidth',1);
hold on
hc = area(plot_x,max(plot_matrix(:,1:6)')');
hc.FaceAlpha = 0.3;
hc.FaceColor = [0.7 1 1];

legend('真实申报下的利润','多报10%的充放电成本','多报20%的充放电成本','多报40%的充放电成本','多报60%的充放电成本', ...
    '虚报能获取的额外利润')% '多报80%的充放电成本'，'少报50%的充放电费用','少报20%的充放电费用','少报10%的充放电费用');
legend('boxoff')
grid on
xlabel('激励相容松弛量');
ylabel('储能的福利 ($)');
% title('储能福利函数随激励相容松弛量的变化')

if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','RX_differentICrelax.png']);
    saveas(1,[Picture_folder,'/','RX_differentICrelax.jpg'])
end
%% 不同的RelaxIC之下，对应最优策略下的社会福利
set(groot,'defaultfigurePosition',[200 200 480 380]);

[~, index] = max(plot_matrix'); 
weight_matrix_SW = plot_matrix./plot_matrix(:,1)-1;
% weight_matrix = (plot_matrix - plot_matrix(:,1))/2442.6;
weight_matrix_SW = weight_matrix_SW(:,1:6);
weight_matrix_SW(:,1) = 1;
weight_matrix_SW(plot_matrix(:,1:6) < plot_matrix(:,1)) = 0;

weight_matrix_SW = weight_matrix_SW./nansum(weight_matrix_SW')';
plot_welfare_matrix = weight_matrix_SW * welfare_result(1:6) + welfare_offset;
figure(2)
plot(plot_x,plot_welfare_matrix ,'LineWidth',2)
grid on
xlabel('激励相容松弛量');
ylabel('社会福利增量');
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','IC_SW_prob_Pareto.png']);
    saveas(2,[Picture_folder,'/','IC_SW_prob_Pareto.jpg'])
end

% plot(plot_x,welfare_result(index)) % 这是可能达成的welfare的下降趋势

% 计算社会福利损失的概率来画图，更好一些. 不知道应该怎么画
%% 这个其实只能展现不同策略情况下的结算规则
BB_matrix = [Result_true.Result_matrix(:,2) Result_1_1.Result_matrix(:,2) ...
    Result_1_2.Result_matrix(:,2) Result_1_4.Result_matrix(:,2) Result_1_6.Result_matrix(:,2) ...
    Result_1_8.Result_matrix(:,2)];
% BB_matrix = [BB_matrix diag(BB_matrix(:,index))];
BB_matrix_all =  [Result_true.Result_matrix(:,2) Result_1_1.Result_matrix(:,2) ...
    Result_1_2.Result_matrix(:,2) Result_1_4.Result_matrix(:,2) Result_1_6.Result_matrix(:,2) ...
    Result_1_8.Result_matrix(:,2) Result_0_5.Result_matrix(:,2) Result_0_8.Result_matrix(:,2) ...
    Result_0_9.Result_matrix(:,2) ...
    Result_SOC_0_8.Result_matrix(:,2)  Result_SOC_0_9.Result_matrix(:,2) ...
    Result_SOC_1_1.Result_matrix(:,2)   Result_SOC_1_2.Result_matrix(:,2)];
% BB_matrix(choose_no,:)

% figure(11)
% plot(plot_x, BB_matrix(:,1))
% hold on 
% plot(plot_x, diag(BB_matrix(:,index)))

BB_matrix(plot_matrix(:,1:6) < plot_matrix(:,1)) = nan;
BB_matrix_high = BB_matrix;
BB_matrix_high(BB_matrix < BB_matrix(:,1)) = nan;
BB_matrix_low = BB_matrix;
BB_matrix_low(BB_matrix > BB_matrix(:,1)) = nan;

weight_matrix = plot_matrix./plot_matrix(:,1)-1;
% weight_matrix = (plot_matrix - plot_matrix(:,1))/2442.6;
weight_matrix = weight_matrix(:,1:6);
weight_matrix(:,1) = 1;

weight_matrix_high = weight_matrix;
weight_matrix_high(isnan(BB_matrix_high)) = nan;
weight_matrix_high = weight_matrix_high./nansum(weight_matrix_high')';
weight_matrix_low = weight_matrix;
weight_matrix_low(isnan(BB_matrix_low)) = nan;
weight_matrix_low = weight_matrix_low./nansum(weight_matrix_low')';


figure(12)
plot(plot_x, BB_matrix(:,1),'LineWidth',2)
hold on
hfill = fill([plot_x;flip(plot_x)], [nansum(BB_matrix_high.* weight_matrix_high,2);flip(nansum(BB_matrix_low.* weight_matrix_low,2))],'r');
hfill.FaceColor = [0.12 0.37 0.82];
hfill.FaceAlpha = 0.3;
hfill.EdgeAlpha = 0;
grid on
xlabel('激励相容松弛量');
ylabel('收支盈余量');
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','IC_surplus_prob_Pareto.png']);
    saveas(12,[Picture_folder,'/','IC_surplus_prob_Pareto.jpg'])
end

figure(13)
plot(plot_x, -BB_matrix(:,1)/2442.6,'LineWidth',2)
hold on
hfill = fill([plot_x;flip(plot_x)], -[nansum(BB_matrix_high.* weight_matrix_high,2);flip(nansum(BB_matrix_low.* weight_matrix_low,2))]/2442.6,'r');
hfill.FaceColor = [0.12 0.37 0.82];
hfill.FaceAlpha = 0.3;
hfill.EdgeAlpha = 0;
grid on
xlabel('激励相容松弛量');
ylabel('收支平衡松弛量');
if ifsave
    print('-dpng','-r1000',[Picture_folder,'/','IC_BB_prob_Pareto.png']);
    saveas(13,[Picture_folder,'/','IC_BB_prob_Pareto.jpg'])
end


%%
% F_plot_Pareto(0,Result_true.Result_matrix, Result_true.Para, Picture_folder) %1719.05是收支不平衡量
%% 展现最终的结果(这个可以展现)
choose_IC = 0.1;
choose_no = find(Result_true.Result_matrix(:,1)== choose_IC);
plot_matrix(choose_no,:)
BB_matrix_all(choose_no,:)
plot_matrix(1,:)
BB_matrix_all(1,:)

%% IC = 0.05/0.10/0.15/0.20/0.30下的储能收入
plot_matrix(51,:)/plot_matrix(51,1)
plot_matrix(101,:)/plot_matrix(101,1)
plot_matrix(151,:)/plot_matrix(151,1)
plot_matrix(201,:)/plot_matrix(201,1)
plot_matrix(301,:)/plot_matrix(301,1)
%% 不同IC下的社会福利
plot_welfare_matrix(1)
plot_welfare_matrix(101)/plot_welfare_matrix(1)
plot_welfare_matrix(201)/plot_welfare_matrix(1)
plot_welfare_matrix(301)/plot_welfare_matrix(1)
%% 
[sum(Result_true.Result1.cal.welfare.ESS)
sum(Result_1_1.Result1.cal.welfare.ESS)
sum(Result_1_2.Result1.cal.welfare.ESS)
sum(Result_1_4.Result1.cal.welfare.ESS)
sum(Result_1_6.Result1.cal.welfare.ESS)
sum(Result_1_8.Result1.cal.welfare.ESS)
sum(Result_0_5.Result1.cal.welfare.ESS)
sum(Result_0_8.Result1.cal.welfare.ESS)
sum(Result_0_9.Result1.cal.welfare.ESS)
sum(Result_SOC_0_8.Result1.cal.welfare.ESS)
sum(Result_SOC_0_9.Result1.cal.welfare.ESS)
sum(Result_SOC_1_1.Result1.cal.welfare.ESS)
sum(Result_SOC_1_1.Result1.cal.welfare.ESS)]



