%% �����������Թ������硢������о���

clear all;
load data
%% ������ϵ��������
% for k = 1:20
%     lunkuo = [];
%     for repeat = 1:5
%         [idx C sumd D]=kmeans(dataprocess,k,'Start','sample','Replicates',5);  %����������ŵ����ݣ�������������ݵ������˼���������ټ�һά
%         for kk = 1:k
%             index(kk).no = find(idx == kk);
%             index(kk).sample = dataprocess(index(kk).no,:); %ѡ������������kk���
%         end
% 
%         for i = 1:m
%             c(i) = 0;
%             for kk = 1:k
%                 b(i,kk) = inf;
%                 if idx(i) == kk
%                     for j = 1 : length(index(kk).no)
%                         c(i)= c(i) + norm(index(kk).sample(j,:) - dataprocess(i,:),2);
%                     end 
%                     c(i) = c(i) / (length(index(kk).no) - 1);
%                 else 
%                     b(i,kk) = 0;
%                     for j = 1 : length(index(kk).no)
%                         b(i,kk) = b(i,kk) +  norm(index(kk).sample (j,:) - dataprocess(i,:),2);
%                     end 
%                     b(i,kk) = b(i,kk) / length(index(kk).no);
% 
%                 end 
%             end
%             bb(i) = min(b(i,:));
%             s(i) = (bb(i) - c(i))/max(bb(i),c(i));
%         end 
%         lunkuo = [lunkuo mean(s(1:m))];
%     end
%     lunkuoresult(k) = mean(lunkuo);
%     
% end 
%% �������
dataprocess = solarcurve;
[m,n] = size(dataprocess);
repeattime = 5;
for k = 2
    temp(k) = 0;
    for repeat = 1:repeattime
        [idx C sumd D]=kmeans(dataprocess,k,'Start','sample','Replicates',5);  %����������ŵ����ݣ�������������ݵ������˼���������ټ�һά
        temp = temp + sum(sumd);
    end
    temp(k) = temp(k) / repeattime;
end

for kk = 1:k
    solarprob(kk) = length(find(idx == kk))/m;
end 
% plot(temp)
% temp(1:19)-temp(2:20)

figure(1)
plot(C') 

solarcluster = C';
solarindex = idx;
save curve solarcluster solarindex solarprob;
    %�����Ǽ�������ϵ��
 %% ������
dataprocess = windcurve;
[m,n] = size(dataprocess);
repeattime = 5;
for k = 2
    temp(k) = 0;
    for repeat = 1:repeattime
        [idx C sumd D]=kmeans(dataprocess,k,'Start','sample','Replicates',5);  %����������ŵ����ݣ�������������ݵ������˼���������ټ�һά
        temp = temp + sum(sumd);
    end
    temp(k) = temp(k) / repeattime;
end

for kk = 1:k
    windprob(kk) = length(find(idx == kk))/m;
end 

% plot(temp)
% temp(1:19)-temp(2:20)
figure(2)
plot(C') 

windcluster = C';
windindex = idx;
save curve windcluster windindex windprob '-append';
    %�����Ǽ�������ϵ��

 %% �������
    dataprocess = demandcurve;

    repeattime = 5;
for k = 2
    temp(k) = 0;
    for repeat = 1:repeattime
        [idx C sumd D]=kmeans(dataprocess,k,'Start','sample','Replicates',5);  %����������ŵ����ݣ�������������ݵ������˼���������ټ�һά
        temp = temp + sum(sumd);
    end
    temp(k) = temp(k) / repeattime;
end
for kk = 1:k
    demandprob(kk) = length(find(idx == kk))/m;
end 

% plot(temp)
% temp(1:19)-temp(2:20)
figure(3)
plot(C') 
demandcluster = C';
demandindex =idx;
save curve demandcluster demandindex demandprob '-append';
 %% ����ͳ��
 for dem = 1 : 2
     for wind = 1 : 2
         for solar = 1 : 2
            prob(dem,wind,solar) = length (intersect (find(solarindex == solar), ...
                intersect(find(demandindex==dem),...
                find(windindex==wind))))/365;
         end
     end 
 end 
save curve prob '-append'


