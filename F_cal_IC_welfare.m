function Result1 = F_cal_IC_welfare(Result_pno,Result1,Para,Num,w,Setting,choose_ESS)
%        choose_ESS = Setting.choose_ESS;
       
       Interval_no = [];
       for i = 1:length(choose_ESS)
           Interval_no = [Interval_no (choose_ESS(i) - 1) * Num.ESScostblock + [1:Num.ESScostblock]];
       end
       offset = Num.ESScostblock * Num.ESS;
       for i = 1:length(choose_ESS)
           Interval_no = [Interval_no offset + (choose_ESS(i) - 1) * Num.ESScostblock + [1:Num.ESScostblock]];
       end
       offset = offset + Num.ESSvalblock * Num.ESS;
       for i = 1:length(choose_ESS)
           Interval_no = [Interval_no offset + (choose_ESS(i) - 1) * Num.ESSvalblock + [1:Num.ESSvalblock]];
       end
       
       for pno = 0:Num.P
           temp_chab = sum(Result_pno(w,pno+1).QESSchab,2);
           temp_disb = sum(Result_pno(w,pno+1).QESSdisb,2);
           for b = 1:Num.ESScostblock
               Result_pno(w,pno+1).temp_chab(:,b) = temp_chab(:,1,b);
               Result_pno(w,pno+1).temp_disb(:,b) = temp_disb(:,1,b);
           end
       end
       % Result_pno(w,pno+1).EndSOC 这个也是可以展示的
       for pno = 1:Num.P
           temp_chab = (Result_pno(w,pno).temp_chab + Result_pno(w,pno+1).temp_chab)/2;
           mid_chab(:,pno) = reshape(temp_chab',Num.ESScostblock * Num.ESS,1);
           temp_disb = (Result_pno(w,pno).temp_disb + Result_pno(w,pno+1).temp_disb)/2;
           mid_disb(:,pno) = reshape(temp_disb',Num.ESScostblock * Num.ESS,1);
           temp_EndSOC = (Result_pno(w,pno).EndSOC + Result_pno(w,pno+1).EndSOC)/2;
           mid_EndSOC(:,pno) = reshape(temp_EndSOC',Num.ESSvalblock * Num.ESS,1);
       end
       mid_all = [-mid_chab;-mid_disb;mid_EndSOC];
       
%        temp_len: 111, sum(Pdismax) = 1040;  
%        temp_len = sum(sum(Para.modify_ESS.Interval_len(Interval_no,:).^2,1).^0.5); %这里的temp_len是总共的len
%        temp_R = sum(sum(Para.modify_ESS.Interval_len(Interval_no,:) .* mid_all(Interval_no,:))) ...
%                         - Setting.kIC * temp_len   * sum([Para.storage(choose_ESS).Pdismax]) ...
%                         - Setting.kIR * sum([Para.storage(choose_ESS).Pdismax]);

       temp_len = sum(Para.modify_ESS.Interval_len(Interval_no,:) .^2,1).^0.5;
       
       
       % 说实话这个地方设计的是有点问题的...
       % Para.modify_ESS.Pmax(Interval_no) * abs(Para.modify_ESS.Interval_len(Interval_no,:))
       
       % 这个地方kIC本来的设计是有问题的额
       if isfield(Setting,'kIC_version') && Setting.kIC_version == 2
           % 这里的Setting.version2是相当于最新版的模式，考虑max(0,a)且考虑了sumproduct的kIC计算
%            Para.modify_ESS.Interval_len(Interval_no,:) * 
           temp_R = sum(max(0,sum(Para.modify_ESS.Interval_len(Interval_no,:) .* mid_all(Interval_no,:),1) ...
                        - Setting.kIC * Para.modify_ESS.Pmax(Interval_no) * abs(Para.modify_ESS.Interval_len(Interval_no,:))   )) ...
                        - Setting.kIR * sum([Para.storage(choose_ESS).Pdismax]);
           
       else
           % 否则就是没考虑sumproduct的kIC计算
            temp_R = sum(max(0,sum(Para.modify_ESS.Interval_len(Interval_no,:) .* mid_all(Interval_no,:),1) ...
                        - Setting.kIC * temp_len   * sum([Para.storage(choose_ESS).Pdismax]))) ...
                        - Setting.kIR * sum([Para.storage(choose_ESS).Pdismax]);
       end
%       Cons = [Cons, Var.RX(c,1) == sum(sum(Para.Interval_len(tempno,:) .* ...
%             Var.scenario(c).QXmean(tempno,:),1)) - Var.kIC * temp_len * ...
%             sum(Para.qabsmax(tempno)) - Var.kIR * sum(Para.qabsmax(tempno))];


%     temp_len = sum(Para.Interval_len(tempno,:) .^2,1).^0.5;
%      Cons = [Cons, Var.RX(c,1) == sum(max(0,sum(Para.Interval_len(tempno,:) .* ...
%         Var.scenario(c).QXmean(tempno,:),1) - Var.kIC * sum(Para.qabsmax(tempno)) ...
%         * temp_len))  - Var.kIR * sum(Para.qabsmax(tempno))];     


       Result1(w).IC_cal.welfare.ESS_choose = temp_R; %这个是视在社会福利
       cal = F_calculatewel_inc_V3(Para,Result1,Num,w);
           
           
       Result1(w).IC_cal.submit_cost.ESS_choose = sum(cal.cost.ESS);
       Result1(w).IC_cal.submit_utility.ESS_choose = sum(cal.utility.ESS);
       Result1(w).IC_cal.income.ESS_choose = temp_R + Result1(w).IC_cal.submit_cost.ESS_choose ...
           - Result1(w).IC_cal.submit_utility.ESS_choose;
       
       % 真实的社会福利应该用收入减去当时计算的真实社会福利得到
       Result1(w).IC_cal.real_welfare.ESS_choose = Result1(w).IC_cal.income.ESS_choose - ...
                sum(Result1(w).cal.cost.ESS(choose_ESS)) + sum(Result1(w).cal.utility.ESS(choose_ESS));
       
%        
%        
%        Result1(w).IC_cal.income.ESS_choose = Result1(w).IC_cal.welfare.ESS_choose + ...
%            sum(Result1(w).cal.cost.ESS(choose_ESS)) - sum(Result1(w).cal.utility.ESS(choose_ESS));
 end
