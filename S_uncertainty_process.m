% 生成8个随机场景，包含需求、风电、光伏的随机性
    load curve
    w = 0;
    prob = prob(1,1,1); % 如果想要选择唯一场景的话
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