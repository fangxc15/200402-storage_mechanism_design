function consumer = F_CstructBuild(Num, RawData_Demand)
%   ���������ڰ�����Demand���ݽ���consumer�Ľṹ�����ݣ��������
%   ������������20171120 11:33
%   �������޸���20180426 16:43
for t = 1 : Num.T
    temp_Line = find(RawData_Demand(:,1)==t);
    tempData_Demand = RawData_Demand(temp_Line,:);
    for d = 1 : Num.D  
    %    consumer(d).Time(t).SNum = tempData_Demand(d,1);  %��������е����⣻
       consumer(d).Bus = tempData_Demand(d,3);
       consumer(d).Pmax(t) = tempData_Demand(d,4);
       consumer(d).Pmin(t) = 0;
       consumer(d).Utility(t) = tempData_Demand(d,5);
    end 
end

end

