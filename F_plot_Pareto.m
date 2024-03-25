function [] = F_plot_Pareto(ifsave, Result_matrix,Para, Picture_folder)
    set(groot,'defaultfigurePosition',[200 200 480 380]);
%     set(groot,'defaultLegendFontName','Times New Roman');
    set(groot,'defaultLegendFontSize',12);
    set(groot,'defaultAxesFontSize',11);
%     set(groot,'defaultFontSize',14);

%     set(groot,'defaultAxesFontWeight','bold');
%     set(groot,'defaultAxesFontName','Times New Roman');
    set(0,'defaultfigurecolor','w'); %设置背景颜色为白色
%     version_suffix =  '';            
%     Picture_root_folder = ['Picture', version_suffix];  
%     mkdir(Picture_root_folder);
%     Picture_folder = Picture_root_folder;
%     Picture_folder = [Picture_root_folder,'/',save_name];
%     mkdir(Picture_folder);
    %% 画出surplus,RelaxIC的帕累托前沿(1)
    
    figure(1)
%     plotmatrix = sortrows([[Result_ParetoBBSW.welfare]' [Result_ParetoBBSW.surplus]' [Result_ParetoBBSW.kIR]'],1);
%     plotmatrix = plotmatrix(plotmatrix(:,1) ~= 0 | plotmatrix(:,2) ~= 0,:);
    plot(Result_matrix(:,1), Result_matrix(:,2),'LineWidth',2)
%     matrix_plot = sortrows([[Result_ParetoBBSW(solveindex).surplus]
%     solveindex = find([solution_ParetoBBSW.problem] == 0); % 要找到有解的,所以soluton问题要查看是怎么回事
%     [Result_ParetoBBSW(solveindex).welfare]]',1);
%     plot(matrix_plot(:,1),matrix_plot(:,2));
    grid on
    xlabel('激励相容松弛量');
    ylabel('收支盈余量');
%     title('激励相容和收支盈余量的帕累托曲线')
    if ifsave
        print('-dpng','-r1000',[Picture_folder,'/','IC_surplus_Pareto.png']);
        saveas(1,[Picture_folder,'/','IC_surplus_Pareto.jpg'])
    end
    %% 画出RelaxBB,RelaxIC的帕累托前沿(1)
    figure(2)
%     plotmatrix = sortrows([[Result_ParetoBBSW.welfare]' [Result_ParetoBBSW.surplus]' [Result_ParetoBBSW.kIR]'],1);
%     plotmatrix = plotmatrix(plotmatrix(:,1) ~= 0 | plotmatrix(:,2) ~= 0,:);
    plot(Result_matrix(:,1), -Result_matrix(:,2)/2442.6,'LineWidth',2)
%     matrix_plot = sortrows([[Result_ParetoBBSW(solveindex).surplus]
%     solveindex = find([solution_ParetoBBSW.problem] == 0); % 要找到有解的,所以soluton问题要查看是怎么回事
%     [Result_ParetoBBSW(solveindex).welfare]]',1);
%     plot(matrix_plot(:,1),matrix_plot(:,2));
    grid on
    xlabel('激励相容松弛量');
    ylabel('收支盈余量');
%     title('激励相容/收支平衡松弛量的帕累托曲线')
    if ifsave
        print('-dpng','-r1000',[Picture_folder,'/','IC_BB_Pareto.png']);
        saveas(2,[Picture_folder,'/','IC_BB_Pareto.jpg'])
    end
end