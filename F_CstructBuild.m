function consumer = F_CstructBuild(Num, RawData_Demand)
%   本函数用于把输入Demand数据建立consumer的结构体数据，方便调用
%   本函数创建于20171120 11:33
%   本函数修改于20180426 16:43
for t = 1 : Num.T
    temp_Line = find(RawData_Demand(:,1)==t);
    tempData_Demand = RawData_Demand(temp_Line,:);
    for d = 1 : Num.D  
    %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %这个好像有点问题；
       consumer(d).Bus = tempData_Demand(d,3);
       consumer(d).Pmax(t) = tempData_Demand(d,4);
       consumer(d).Pmin(t) = 0;
       consumer(d).Utility(t) = tempData_Demand(d,5);
    end 
end

end

