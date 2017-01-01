% function PlotStepSize_DiffsCDFs(Dataset,bp,slopey,num_samples_to_analyze)
%
% Dataset is any input to ListGoodResults_Slopey. Plots cdfs of first
% state-second state FRET or bp differences, and cdfs of second state-third
% state differences, for all sets in Dataset. Also plots errors based on
% bootstrapping.
%
% If slopey is 0, use pyhsmm results. If bp is 0, report differences in
% FRET values. If slopey is 1, also need to pass num_samples_to_analyze.
%
% Steph 12/2016

function PlotStepSize_DiffsCDFs(Dataset,bp,slopey,num_samples_to_analyze)

num_bs = 1000;

if slopey==1 && ~exist('num_samples_to_analyze','var')
    disp('Slopey requires num_samples_to_analyze; not using slopey.')
    slopey=0;
end

if slopey==0
    num_samples_to_analyze = 0;
end

[datadirs,labels,legends,colors] = ListGoodResults_Slopey(Dataset);

maindir = '/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results';

if bp==1
    ValToExtract = 3;
else
    ValToExtract = 2;
end

h1=figure;
h2=figure;
for d = 1:length(datadirs)
    currdir = fullfile(maindir,datadirs{d});
    [curr_p,curr_t] = Extract_Slopey_Results(currdir,num_samples_to_analyze,labels{d},slopey);
    num_results = length(curr_p{1}(:,1)); % Every trace has a first pause, so 
        % the number of rows in the first cell in all_p will be the total
        % number of traces
    [f1,x1] = ecdf(curr_t{1}(:,ValToExtract));
    [f2,x2] = ecdf(curr_t{2}(:,ValToExtract));
    figure(h1)
    plot(x1,f1,strcat('-',colors{d}))
    figure(h2)
    plot(x2,f2,strcat('-',colors{d}))
    if d==1
        figure(1)
        hold on
        figure(2)
        hold on
        if bp==1 && length(find(curr_t{1}(:,ValToExtract)>=0))==length(curr_t{1}(:,ValToExtract)) % This is if all diffs calculated are absolute values
            xlimsD = [0 26];
        else
            xlimsD = [-1.1 1.1];
        end
    end
    
    bs_1 = zeros(length(x1),num_bs); % Each column will be a bootstrapped cdf, evaluated at all or some x1's
    bs_2 = zeros(length(x2),num_bs);
    
    clear curr_p curr_t
    
    % Bootstrap to get errors:
    disp(strcat('Bootstrapping: ',currdir))
    % Each row of bootstat will be a set of indices with which to resample my
    % data with replacement (bootstat will have size num_bs by num_results):
    bootstat = bootstrp(num_bs,@(x)x,1:num_results);
    for j = 1:num_bs
        [~,curr_t] = Extract_Slopey_Results(currdir,num_samples_to_analyze,labels{d},slopey,bootstat(j,:));
        [fi_1, xi_1] = ecdf(curr_t{1}(:,ValToExtract)); % Each column will contain the ecdf outputs for one bootstrapped sample
        [fi_2, xi_2] = ecdf(curr_t{2}(:,ValToExtract));
        % All xi_1 are members of x1; but ~isequal(x1,xi_1)
        % Can I do this without a for-loop?
        memb_ind_1 = ismember(x1,xi_1);
        m_f = 1;
        for m = 1:length(memb_ind_1)
            if memb_ind_1(m)~=0
                bs_1(m,j) = fi_1(m_f);
                m_f = m_f+1;
            end
        end
        memb_ind_2 = ismember(x2,xi_2);
        m_f = 1;
        for m = 1:length(memb_ind_2)
            if memb_ind_2(m)~=0
                bs_2(m,j) = fi_2(m_f);
                m_f = m_f+1;
            end
        end
        clear fi_1 xi_1 fi_2 xi_2 memb_ind_1 memb_ind_2 m_f
    end
    % What I want for the errors is the std dev at every point of the
    % original cdf. But I have a bunch of zeros ... Can I avoid a for-loop
    % here too?
    errs_1 = zeros(size(f1));
    errs_2 = zeros(size(f2));
    for e = 1:size(errs_1,1)
        errs_1(e) = std(bs_1(e,find(bs_1(e,:))));
    end
    for e = 1:size(errs_2,1);
        errs_2(e) = std(bs_2(e,find(bs_2(e,:))));
    end
    errs_1(isnan(errs_1)) = 0;
    errs_2(isnan(errs_2)) = 0;
    figure(h1)
    plot(x1,f1+errs_1./2,strcat('--',colors{d}))
    plot(x1,f1-errs_1./2,strcat('--',colors{d}))
    figure(h2)
    plot(x2,f2+errs_2./2,strcat('--',colors{d}))
    plot(x2,f2-errs_2./2,strcat('--',colors{d}))
    
    clear currdir curr_t curr_p x1 x2 f1 f2 num_results bootstat bs_1 bs_2 errs_1 errs_2
end

figure(h1)
legend(legends)
ylabel('Cumulative probability','Fontsize',14)
set(gca,'Fontsize',12)
xlim(xlimsD)
ylim([0 1])
set(gca,'YTick',[0 0.2 0.4 0.6 0.8 1])
if bp==1
    xlabel('Change in bp, wait to p1','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_waitp1_Slopey_bp')))
    else
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_waitp1_pyhsmm_bp')))
    end

else
    xlabel('Change in FRET, wait to p1','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_waitp1_Slopey_FRET')))
    else
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_waitp1_pyhsmm_FRET')))
    end
end

figure(h2)
legend(legends)
ylabel('Cumulative probability','Fontsize',14)
set(gca,'Fontsize',12)
xlim(xlimsD)
ylim([0 1])
set(gca,'YTick',[0 0.2 0.4 0.6 0.8 1])
if bp==1
    xlabel('Change in bp, p1 to p2','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_p1p2_Slopey_bp')))
    else
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_p1p2_pyhsmm_bp')))
    end

else
    xlabel('Change in FRET, p1 to p2','Fontsize',14)
    if slopey
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_p1p2_Slopey_FRET')))
    else
        print('-depsc',fullfile(maindir,strcat('StateDiffs_CDFs_p1p2_pyhsmm_FRET')))
    end
end

