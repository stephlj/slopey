% function PlotStepSize_Slopey(datadir_to_analyze,num_samples_to_analyze,label,bp,slopey)
%
% datadir_to_analyze is a folder in HMMresults. Label can be 'H3' or 'H2A'.
% If the bp argument is 1, plots in terms of bp not FRET values. If slopey
% is 0, use output of old HMM (pyhsmm) instead of Slopey.
%
% Updated 11/15/16 to plot kernel density plots rather than histograms.
%
% Steph 11/2016

function PlotStepSize_Slopey(datadir_to_analyze,num_samples_to_analyze,label,bp,slopey)

maindir = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',...
        datadir_to_analyze);

[all_p,all_t] = Extract_Slopey_Results(maindir,num_samples_to_analyze,label,slopey);

if bp==1
    ValToExtract = 3;
    % histo_range = 0:1:30;
    bw = 0.5; % KD bandwidth
    y_density = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
    ylim_density = 0.4;
    % ylim_density_D = 0.15;
    bwD = 0.5;
    % bwD = 0.35;
    % ylim_density_D = 0.3;
    ylim_density_D = 0.2;
    xlims = [0 26];
    if length(find(all_t{1}(:,3)>=0))==length(all_t{1}(:,3)) % This is if all diffs calculated are absolute values
        % histo_range_diffs = 0:1:20;
        xlimsD = xlims;
    else
        % histo_range_diffs = 0:1:20;
        xlimsD = [-1.1 1.1];
    end
else
    ValToExtract = 2;
    % histo_range = -0.05:.05:1.05;
    bw = 0.025;
    y_density = [0 2 4 6 8 10];
    ylim_density = 10;
    bwD = 0.025;
    ylim_density_D = 5;
    xlims = [-.1 1.1];
    if length(find(all_t{1}(:,2)>=0))==length(all_t{1}(:,2)) % This is if all diffs calculated are absolute values
        % histo_range_diffs = -0.05:.05:1.05;
        xlimsD = xlims;
    else
        % histo_range_diffs = -1.05:.05:1.05;
        xlimsD = [-1.1 1.1];
    end
end

% sumF = zeros(size(histo_range));
numF = length(all_p{1}(:,ValToExtract));
% sumdF = zeros(size(histo_range_diffs));
numdF = length(all_t{1}(:,ValToExtract));

sumF = [];
sumdF = [];
nMax = 0;
nMaxD = 0;

% States in FRET and bp
for p = 1:length(all_p)
    figure
    % axLink(end+1) = gca;
    % [F,xoutF] = hist(all_p{p}(:,ValToExtract),histo_range);
    % sumF = sumF+F;
    % F = F./length(all_p{p}(:,ValToExtract));
    % bar(xoutF(2:end-1),F(2:end-1),'hist')
    % ylabel('Fraction of molecules','Fontsize',14)
    [f,xi] = ksdensity(all_p{p}(:,ValToExtract),'bandwidth',bw);
    % Now also plotting CDFs
    [f_cdf,x_cdf] = ecdf(all_p{p}(:,ValToExtract));
    [axLink(p,:)] = plotyy(xi,f,x_cdf,f_cdf);
    ylabel(axLink(p,1),'Density','Fontsize',14)
    ylabel(axLink(p,2),'Cumulative probability','Fontsize',14)
    legend(strcat('N = ',int2str(length(all_p{p}(:,ValToExtract)))))
    set(axLink(p,1),'Fontsize',12)
    set(axLink(p,2),'Fontsize',12)
    xlim(axLink(p,1),xlims)
    xlim(axLink(p,2),xlims)
    % set(gca,'XTick',[0 0.2 0.4 0.6 0.8 1])
    set(axLink(p,1),'YTick',y_density)
    set(axLink(p,2),'YTick',[0 0.2 0.4 0.6 0.8 1])
    
    sumF = [sumF;all_p{p}(:,ValToExtract)];
    nMax = max(nMax,max(f));
    
    if bp==1
        xlabel(strcat('bp (state num = ',int2str(p),')'),'Fontsize',14)
        if slopey
            print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_Slopey_bp')))
        else
            print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_pyhsmm_bp')))
        end
    else
        xlabel(strcat('FRET (state num = ',int2str(p),')'),'Fontsize',14)
        if slopey
            print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_Slopey_FRET')))
        else
            print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_pyhsmm_FRET')))
        end
    end
end

% sumF = sumF./numF;
% for scaling all the graphs to be the same thing:
% nMax = max(sumF(2:end-1));
linkaxes(axLink(:,2),'y')
% axLink(1).YLim = [0 nMax+0.01];
axLink(1).YLim = [0 1];
linkaxes(axLink(:,1),'y')
axLink(1).YLim = [0 ylim_density];

% Summed figure
figure
% bar(xoutF(2:end-1),sumF(2:end-1),'hist')
% ylabel('Fraction of molecules','Fontsize',14)
[f,xi] = ksdensity(sumF,'bandwidth',bw);
[f_cdf,x_cdf] = ecdf(sumF);
ax = plotyy(xi,f,x_cdf,f_cdf);
ylabel(ax(1),'Density','Fontsize',14)
ylabel(ax(2),'Cumulative probability','Fontsize',14)
legend(strcat('N = ',int2str(numF)))
set(ax(1),'Fontsize',12)
set(ax(2),'Fontsize',12)
xlim(ax(1),xlims)
xlim(ax(2),xlims)
ylim(ax(1),[0 ylim_density])
% set(gca,'XTick',[0 0.2 0.4 0.6 0.8 1])
set(ax(1),'YTick',y_density)
set(ax(2),'YTick',[0 0.2 0.4 0.6 0.8 1])

if bp==1
    xlabel('bp','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,'StateHisto_All_Slopey_bp'))
    else
        print('-depsc',fullfile(maindir,'StateHisto_All_pyhsmm_bp'))
    end
else
    xlabel('FRET','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,'StateHisto_All_Slopey_FRET'))
    else
        print('-depsc',fullfile(maindir,'StateHisto_All_pyhsmm_FRET'))
    end
end
clear axLink

% Differences between states in FRET and bp
for t = 1:length(all_t)
    figure
    hold on
    [fd,xid] = ksdensity(all_t{t}(:,ValToExtract),'bandwidth',bwD);
    [fd_cdf,xd_cdf] = ecdf(all_t{t}(:,ValToExtract));
    [axLink(t,:)] = plotyy(xid,fd,xd_cdf,fd_cdf);
    ylabel(axLink(t,1),'Density','Fontsize',14)
    ylabel(axLink(t,2),'Cumulative probability','Fontsize',14)
    legend(strcat('N = ',int2str(length(all_t{t}(:,ValToExtract)))))
    set(axLink(t,1),'Fontsize',12)
    set(axLink(t,2),'Fontsize',12)
    xlim(axLink(t,1),xlimsD)
    xlim(axLink(t,2),xlimsD)
    % set(gca,'XTick',[0 0.2 0.4 0.6 0.8 1])
    set(axLink(t,1),'YTick',y_density)
    set(axLink(t,2),'YTick',[0 0.2 0.4 0.6 0.8 1])
    
    sumdF = [sumdF;all_t{t}(:,ValToExtract)];
    nMaxD = max(nMaxD,max(fd));
    if bp==1
        xlabel(strcat('Change in nucleosome position (bp) (change num = ',int2str(t),')'),'Fontsize',14)
        if slopey
            print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_Slopey_bp')))
        else
            print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_pyhsmm_bp')))
        end
            
    else
        xlabel(strcat('Change in nucleosome position (FRET) (state num = ',int2str(t),')'),'Fontsize',14)
        if slopey
            print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_Slopey_FRET')))
        else
            print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_pyhsmm_FRET')))
        end
    end
end
% sumdF = sumdF./numdF;
% for scaling all the graphs to be the same thing:
% nMaxd = max(sumdF(2:end-1));
linkaxes(axLink(:,1),'y')
% axLink(1).YLim = [0 nMaxD+0.01];
axLink(1).YLim = [0 1];
linkaxes(axLink(:,2),'y')
axLink(1).YLim = [0 ylim_density_D];

% Summed figure of state differences
figure
% bar(xoutdF(2:end-1),sumdF(2:end-1),'hist')
% ylabel('Fraction of molecules','Fontsize',14)
[fd,xid] = ksdensity(sumdF,'bandwidth',bwD);
[fd_cdf,xd_cdf] = ecdf(sumdF);
axD = plotyy(xid,fd,xd_cdf,fd_cdf);
ylabel(axD(1),'Density','Fontsize',14)
ylabel(axD(2),'Cumulative probability','Fontsize',14)
legend(strcat('N = ',int2str(numdF)))
set(axD(1),'Fontsize',12)
set(axD(2),'Fontsize',12)
xlim(axD(1),xlimsD)
xlim(axD(2),xlimsD)
ylim(axD(1),[0 ylim_density_D])
% set(gca,'XTick',[0 0.2 0.4 0.6 0.8 1])
set(axD(1),'YTick',y_density)
set(axD(2),'YTick',[0 0.2 0.4 0.6 0.8 1])

if bp==1
    xlabel('Change in nucleosome position (bp)','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_Slopey_bp'))
    else
        print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_pyhsmm_bp'))
    end
else
    xlabel('Change in nucleosome position (FRET)','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_Slopey_FRET'))
    else
        print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_pyhsmm_FRET'))
    end
end

        

