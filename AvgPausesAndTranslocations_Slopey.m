% function [means_p,errs_p,mean_rates_t,...
%    err_rates_t] = AvgPausesAndTranslocations_Slopey(resultsdir,num_bs,num_samples_to_avg,label)
%
% Calculates average pause durations and average translocation RATES (bp/s)
% for output of slopey. 
%
% Inputs:
%   resultsdir: Directory containing output of slopey analysis
%   num_samples_to_avg: Number of slopey output samples to use in
%       CalcAvgSlopey
%   label: 'H3' or 'H2A' (selects calibration curve for FRET vs bp)
%   num_bs: Number of bootstrapped samples to generate
%
% Outputs:
%   means_p: A length-n vector where each element is the mean of the nth
%       pause
%   errs_p: bootstrapped errors on means_p
%   
%
% Steph 9/2016

function [means_p,errs_p,mean_rates_t,...
    err_rates_t] = AvgPausesAndTranslocations_Slopey(resultsdir,num_samples_to_avg,label,num_bs)

disp(strcat('Bootstrapping: ',resultsdir))

resultsdir = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',...
        resultsdir);

% Number of bootstrapped results to create:
if ~exist('num_bs','var') num_bs = 1000; end

% Get the means and find out how many traces are in this dataset:
[all_p,all_t] = Extract_Slopey_Results(resultsdir,num_samples_to_avg,label);
num_results = length(all_p{1}(:,1)); % Every trace has a first pause, so 
    % the number of rows in the first cell in all_p will be the total
    % number of traces
means_p = zeros(1,length(all_p));
mean_rates_t = zeros(1,length(all_t));
for k=1:length(all_p)
    means_p(k) = mean(all_p{k}(:,1));
end
figure
for kk=1:length(all_t)
    if length(all_t{kk}(:,1)) >= 2
        % To get the average translocation rate for each step, fit a line to
        % the cluster of points in the change-in-bp vs. translocation duration space:
        % Also make a figure of the scatter plot and the fit:
        subplot(1,length(all_t),kk)
        plot(all_t{kk}(:,1),all_t{kk}(:,3),'xb')
        hold on
        % rate_fit = fit(all_t{kk}(:,1),all_t{kk}(:,3),'poly1');
        rate_fit = fit(all_t{kk}(:,1),all_t{kk}(:,3),@(p1,x)x*p1,'StartPoint',mean(all_t{kk}(:,3))/mean(all_t{kk}(:,1)));
        mean_rates_t(kk) = rate_fit.p1;
        rate_x = linspace(min(0,min(all_t{kk}(:,1))),max(all_t{kk}(:,1)));
        % plot(rate_x,rate_fit.p1.*rate_x+rate_fit.p2,'-k')
        plot(rate_x,rate_fit.p1.*rate_x,'-k')
        xlabel(strcat('Translocation duration (t=',int2str(kk),')'))
        ylabel('bp translocated')
        legend(strcat('Rate = ',num2str(rate_fit.p1)))
        clear rate_x rate_fit
    end
end
print('-depsc',fullfile(resultsdir,'Tr_Rate_plots'))

% Each row of bootstat will be a set of indices with which to resample my
% data with replacement (bootstat will have size num_bs by num_results):
bootstat = bootstrp(num_bs,@(x)x,1:num_results);

% Then bootstrap to get errors:
bs_p = zeros(length(all_p),num_bs);
bs_t = zeros(length(all_t),num_bs);
for j = 1:num_bs
    [p_temp,t_temp] = Extract_Slopey_Results(resultsdir,num_samples_to_avg,label,bootstat(j,:));
    for p = 1:length(p_temp)
        bs_p(p,j) = mean(p_temp{p}(:,1));
    end
    for t = 1:length(t_temp)
        if length(t_temp{t}(:,1)) >= 2
            % rate_fit = fit(t_temp{t}(:,1),t_temp{t}(:,3),'poly1');
            rate_fit = fit(t_temp{t}(:,1),t_temp{t}(:,3),@(p1,x)x*p1,'StartPoint',mean(t_temp{t}(:,3))/mean(t_temp{t}(:,1)));
            bs_t(t,j) = rate_fit.p1;
            clear rate_fit
        end
    end
    clear p_temp t_temp
end

errs_p = zeros(1,length(all_p));
err_rates_t = zeros(1,length(all_t));
for k = 1:size(bs_p,1)
    errs_p(k) = std(bs_p(k,:));
end
for kk = 1:size(bs_t,1)
    err_rates_t(kk) = std(bs_t(kk,:));
end
