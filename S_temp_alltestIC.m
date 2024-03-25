%% 用来在testIC时实现循环




% falserate_array = [1,1.1,1.2,1.4,1.6,1.8,0.5,0.8,0.9];
% for false_no = 1:length(falserate_array)
%     falserate = falserate_array(false_no);
%     main_ESSmechanism_Pareto_testIC
%     clearvars -except falserate_array false_no
% end

falserate_SOC_array = [0.8,0.9,1.1,1.2];
for false_no = 1:length(falserate_SOC_array)
    falserate_SOC = falserate_SOC_array(false_no);
    main_ESSmechanism_Pareto_testIC
    clearvars -except falserate_SOC_array false_no
end
