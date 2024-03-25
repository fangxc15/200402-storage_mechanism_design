function [Result1,mytime] = F_getresult(Num,Para,availableESS,ESSschedule)

    for w = 1:Num.S
        t0 = cputime;
        if nargin == 3
            Result1(w).rawdata = F_marketclearing_V1_2(Num,Para,availableESS,w);
        else 
           Result1(w).rawdata = F_marketclearing_V1_2(Num,Para,availableESS,w,ESSschedule);
        end
        [Result1(w).welfare,Result1(w).income,Result1(w).cost,Result1(w).utility] = F_calculatewel_inc_V2(Para,Result1(w).rawdata,Num,w);
        mytime = cputime - t0;
    end 
end 
