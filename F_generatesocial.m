function Resultafter = F_generatesocial(Resultbid,bidagent,Num,Para,availableESS)
    % 用来根据已有的ESS自调度计划计算social welfare
    for nnESS = 1:Num.ESS
        tempno = find(bidagent == nnESS);
        if ~isempty(tempno)
            for w = 1:Num.S
                ESSschedule(nnESS).scene(w).dis = Resultbid.scene(w).discharging(:,tempno); %返回里有charging和discharging
                ESSschedule(nnESS).scene(w).cha = Resultbid.scene(w).charging(:,tempno);
            end 
        else 
            ESSschedule(nnESS).scene = [];
        end 
    end 
    for w = 1:Num.S
        Resulttemp = F_marketclearing_V1_4(Num,Para,availableESS,w,ESSschedule);
        Resulttemp.cal = F_calculatewel_inc_V3(Para,Resulttemp,Num,w);
        Resultafter(w) = Resulttemp;
    end 

end 