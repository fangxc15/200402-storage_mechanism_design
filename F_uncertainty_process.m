function [Para,Num] = F_uncertainty_process(Para,Num,choose_scenario)

% ����8������������������󡢷�硢����������
    load curve
    w = 0;
    if choose_scenario == 0
        prob = prob(1,1,1); % �����Ҫѡ��Ψһ�����Ļ�
    end
    for idemand = 1:size(prob,1)
        for iwind = 1:size(prob,2)
            for isolar = 1:size(prob,3)
                w = w + 1;
                Para.scenario(w).prob = prob(idemand,iwind,isolar)/sum(sum(sum(prob)));
                Para.scenario(w).normD = demandcluster(:,idemand)/mean(mean(demandcluster));
                Para.scenario(w).normW = windcluster(:,iwind)/mean(mean(windcluster))/3;
                Para.scenario(w).normS = solarcluster(:,isolar)/mean(mean(solarcluster))/4;
            end 
        end 
    end
    Num.S = w;
    Num.T = size(demandcluster,1);
end

