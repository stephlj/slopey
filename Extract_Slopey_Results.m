% function [all_p,all_t] = Extract_Slopey_Results(datadir_to_analyze,num_samples_to_avg,label,bootstr_smpls)
% 
% Takes all the slopey results in a datadir and aggregates pause and
% translocation information.
%
% Datadir needs to be the full path to the directory to analyze.
% 
% To compute, e.g., average duration of the wait pause, you would want 
%     mean(all_p{1}(:,1))
%
% Last input is optional and is a list of trace indices to compute
% durations etc from.
% 
% all_p{i} will have an n by 3 matrix, where i is the pause duration number
% (wait, p1, p2, etc) and n is the number of traces that have that state.
% The first column of all_p{i} will be duration, the second FRET value, the
% third bp value. Similarly for all_t{i} but instead of FRET and bp, it
% will be difference in FRET or bp between start and end of the
% translocation.
% 
% Steph 11/2016

function [all_p,all_t] = Extract_Slopey_Results(maindir,num_samples_to_avg,label,bootstr_smpls)

results = LoadSlopeyResults(maindir,num_samples_to_avg);
default_t_Inj = 9.98; % seconds

if ~exist('label','var') label = 'H3'; end

if ~exist('bootstr_smpls','var') || max(bootstr_smpls)>length(results)
    bootstr_smpls = 1:length(results); 
    disp('Not using special (e.g. bootstrapped) trace list.')
end

tokeep = cell(length(results),2);
k = 1;
% Iterate through results and CalvAvgSlopey for traces not discarded.
% Any discarded traces will result in an empty matrix in that cell of
% tokeep.
for j=bootstr_smpls
    if ~isfield(results{j},'discard') || ~strcmpi(results{j}.discard,'true')
        if ~isfield(results{j},'t_Inj')
            % Get the injection time from the original data file (in seconds)
            orig_file = load(fullfile(maindir,results{j}.name));
            if isfield(orig_file,'t_Inj')
               t_Inj = orig_file.t_Inj;
               results{j}.t_Inj = t_Inj;
            else
               disp(sprintf('Using default t_Inj of %d seconds',t_Inj))
               t_Inj = default_t_Inj;
            end
            clear orig_file
        else
            t_Inj = results{j}.t_Inj;
        end
        [tokeep{k,1},~,~,tokeep{k,2}] = CalcAvgSlopey(results{j},t_Inj);
        k = k+1;
    end
end

% Starting with 50 states because no trace should have more than that.
all_p = cell(50,1);
all_t= cell(50,1);

for r = 1:size(tokeep,1)
    if ~isempty(tokeep{r,1})
        [p_dur,t_dur,p_FRET,t_dFRET,p_bp,t_dbp] = Extract_Slopey_Basics(tokeep{r,1},tokeep{r,2},label);
        for p = 1:length(p_dur)
            all_p{p}(end+1,:) = [p_dur(p) p_FRET(p) p_bp(p)];
            if p<=length(t_dur)
                all_t{p}(end+1,:) = [t_dur(p) t_dFRET(p) t_dbp(p)];
            end
        end
    end
end

% Remove empty cells
all_p= all_p(~cellfun('isempty',all_p));
all_t= all_t(~cellfun('isempty',all_t));