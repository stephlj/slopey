% function PlotAvgs_Slopey(datadir)
%
% resultset is any input to ListGoodResults_Slopey; if slopey = 1, use
% output of slopey, else use output of pyhsmm.
%
% Steph 11/2016

function PlotAvgs_Slopey(resultset,slopey)

num_samples_to_avg = 200;

if ~exist('slopey','var')
    slopey = 0;
end

[datasets,labels,legends,colors] = ListGoodResults_Slopey(resultset);

% plot the first three pause durations and (if slopey) the first two translocation
    % rates
p_bar_vals = zeros(3,length(datasets));
t_bar_vals = zeros(2,length(datasets));
p_err_vals = zeros(3,length(datasets));
t_err_vals = zeros(2,length(datasets));

for j=1:length(datasets)
    [means,err_means,rates,rates_errs] = AvgPausesAndTranslocations_Slopey(datasets{j},num_samples_to_avg,labels{j},slopey);
    for p = 1:3
        p_bar_vals(p,j) = means(p);
        p_err_vals(p,j) = err_means(p);
    end
    if slopey
        for t = 1:2
            t_bar_vals(t,j) = rates(t);
            t_err_vals(t,j) = rates_errs(t);
        end
    end
    clear means err_means rates rates_errs
end

xvect = XPosForBarErrs(length(datasets));

figure
b_p = bar(p_bar_vals);
for k = 1:length(datasets)
    b_p(k).FaceColor = colors{k};
end
hold on
errorbar(xvect,reshape(p_bar_vals',1,size(p_bar_vals,1)*size(p_bar_vals,2)),...
    reshape(p_err_vals',1,size(p_err_vals,1)*size(p_err_vals,2)),'.k')
set(gca,'XTick',[1,2,3])
set(gca,'XTickLabel',{'wait';'p1';'p2'})
legend(legends)
ylabel('Duration (sec)')
set(gca,'Fontsize',14)

if slopey
    figure
    b_t = bar(t_bar_vals);
    for k = 1:length(datasets)
        b_t(k).FaceColor = colors{k};
    end
    hold on
    errorbar(xvect(1:2*length(datasets)),reshape(t_bar_vals',1,size(t_bar_vals,1)*size(t_bar_vals,2)),...
        reshape(t_err_vals',1,size(t_err_vals,1)*size(t_err_vals,2)),'.k')
    set(gca,'XTick',[1,2])
    set(gca,'XTickLabel',{'t1';'t2'})
    legend(legends)
    ylabel('Translocation rate (bp/sec)')
    set(gca,'Fontsize',14)
end
