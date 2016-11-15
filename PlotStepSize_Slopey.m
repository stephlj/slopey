% function PlotStepSize_Slopey(datadir_to_analyze,num_samples_to_analyze,label,bp)
%
% datadir_to_analyze is a folder in HMMresults. Label can be 'H3' or 'H2A'.
% If the bp argument is 1, plots in terms of bp not FRET values.
%
% Updated 11/15/16 to plot kernel density plots rather than histograms.
%
% Steph 11/2016

function PlotStepSize_Slopey(datadir_to_analyze,num_samples_to_analyze,label,bp)

maindir = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',...
        datadir_to_analyze);

[all_p,all_t] = Extract_Slopey_Results(maindir,num_samples_to_analyze,label);

bw = 0.2; % KD bandwidth

if bp==1
    ValToExtract = 3;
    % histo_range = 0:1:30;
    xlims = [0 30];
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
    axLink(p) = gca;
    % [F,xoutF] = hist(all_p{p}(:,ValToExtract),histo_range);
    % sumF = sumF+F;
    % F = F./length(all_p{p}(:,ValToExtract));
    % bar(xoutF(2:end-1),F(2:end-1),'hist')
    % ylabel('Fraction of molecules','Fontsize',14)
    [f,xi] = ksdensity(all_p{p}(:,ValToExtract),'bandwidth',bw);
    sumF = [sumF;all_p{p}(:,ValToExtract)];
    nMax = max(nMax,max(f));
    plot(xi,f,'-k')
    ylabel('Density','Fontsize',14)
    legend(strcat('N = ',int2str(length(all_p{p}(:,ValToExtract)))))
    set(gca,'Fontsize',12)
    xlim(xlims)
    if bp==1
        xlabel(strcat('bp (state num = ',int2str(p),')'),'Fontsize',14)
        print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_Slopey_bp')))
    else
        xlabel(strcat('FRET (state num = ',int2str(p),')'),'Fontsize',14)
        print('-depsc',fullfile(maindir,strcat('StateHisto_p',int2str(p),'_Slopey_FRET')))
    end
end

% sumF = sumF./numF;
% for scaling all the graphs to be the same thing:
% nMax = max(sumF(2:end-1));
linkaxes(axLink,'y')
% axLink(1).YLim = [0 nMax+0.01];
axLink(1).YLim = [0 0.5];

% Summed figure
figure
% bar(xoutF(2:end-1),sumF(2:end-1),'hist')
% ylabel('Fraction of molecules','Fontsize',14)
[f,xi] = ksdensity(sumF,'bandwidth',bw);
plot(xi,f,'-k')
ylabel('Density','Fontsize',14)
legend(strcat('N = ',int2str(numF)))
set(gca,'Fontsize',12)
xlim(xlims)
% ylim([0 nMax+0.01])
ylim([0 0.2]);
if bp==1
    xlabel('bp','Fontsize',14)
    print('-depsc',fullfile(maindir,'StateHisto_All_Slopey_bp'))
else
    xlabel('FRET','Fontsize',14)
    print('-depsc',fullfile(maindir,'StateHisto_All_Slopey_FRET'))
end
clear axLink

% Differences between states in FRET and bp
for t = 1:length(all_t)
    figure
    axLink(t) = gca;
    hold on
    % [dF,xoutdF] = hist(all_t{t}(:,ValToExtract),histo_range_diffs);
    % sumdF = sumdF+dF;
    % dF = dF./length(all_t{t}(:,ValToExtract));
    % bar(xoutdF(2:end-1),dF(2:end-1),'hist')
    % ylabel('Fraction of molecules','Fontsize',14)
    [fd,xid] = ksdensity(all_t{t}(:,ValToExtract),'bandwidth',bw);
    sumdF = [sumdF;all_t{t}(:,ValToExtract)];
    nMaxD = max(nMaxD,max(fd));
    plot(xid,fd,'-k')
    ylabel('Density','Fontsize',14)
    legend(strcat('N = ',int2str(length(all_t{t}(:,ValToExtract)))))
    set(gca,'Fontsize',12)
    xlim(xlimsD)
    if bp==1
        xlabel(strcat('Change in nucleosome position (bp) (change num = ',int2str(t),')'),'Fontsize',14)
        print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_Slopey_bp')))
    else
        xlabel(strcat('Change in nucleosome position (FRET) (state num = ',int2str(t),')'),'Fontsize',14)
        print('-depsc',fullfile(maindir,strcat('StateDiffs_p',int2str(t),'_Slopey_FRET')))
    end
end
% sumdF = sumdF./numdF;
% for scaling all the graphs to be the same thing:
% nMaxd = max(sumdF(2:end-1));
linkaxes(axLink,'y')
% axLink(1).YLim = [0 nMaxD+0.01];
axLink(1).YLim = [0 0.4];

% Summed figure of state differences
figure
% bar(xoutdF(2:end-1),sumdF(2:end-1),'hist')
% ylabel('Fraction of molecules','Fontsize',14)
[fd,xid] = ksdensity(sumdF,'bandwidth',bw);
plot(xid,fd,'-k')
ylabel('Density','Fontsize',14)
legend(strcat('N = ',int2str(numdF)))
set(gca,'Fontsize',12)
xlim(xlimsD)
% ylim([0 nMaxD+0.01])
ylim([0 0.2])
if bp==1
    xlabel('Change in nucleosome position (bp)','Fontsize',14)
    print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_Slopey_bp'))
else
    xlabel('Change in nucleosome position (FRET)','Fontsize',14)
    print('-depsc',fullfile(maindir,'StateHisto_AllDiffs_Slopey_FRET'))
end

        

