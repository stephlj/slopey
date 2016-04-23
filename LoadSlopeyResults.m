% function results = LoadSlopeyResults(samples_to_plot,perc_dur_to_analyze)
%
% Steph 4/2016

function results = LoadSlopeyResults(samples_to_plot,perc_dur_to_analyze)

if ~exist('samples_to_plot','var') samples_to_plot = 10; end % will load only the results of the last samples_to_plot iterations
if ~exist('perc_dur_to_analyze','var') perc_dur_to_analyze = 0.10; end % Will keep the last perc_dur_to_analyze% of durations

maindir = '/Users/Steph/Documents/UCSF/Narlikar lab/HMM analysis Slopey/slopey';
names = dir(fullfile(maindir,'data','*.mat'));

results_py = load(fullfile(maindir,'results','all_results.mat'));

results = cell(1,length(names));

for k = 1:length(names)
    struct_py = results_py.(names(k).name(1:end-4));
    
    results{k}.name = names(k).name(1:end-4);
    results{k}.fps = 1/struct_py.params.T_cycle;
    results{k}.data = struct_py.data;
    results{k}.start = double(struct_py.params.start);
    results{k}.end = double(struct_py.params.end);
    
    samples = struct_py.samples;
    % Each structure in allresults has 3 fields: params, data, and samples.
    % Samples is a num_iterations+1-by-3 cell array. If n is
    % num_iterations:
    % currstruct.samples{n,1}{1} is a num_slopey+1-by-1 vector, giving the
    % times in seconds of the start and end of each slopey bit.
    % currstruct.samples{n,1}{2} is a num_slopey-by-1 vector giving the red
    % intensity values for each flat bit that separates slopeys.
    % currstruct.samples{n,2} is a double that gives the offset parameter
    % for converting from seconds to frames.
    % currstruct.samples{n,3} is a 2x1 vector that gives the transformation
    % parameters to obtain real green values instead of idealized ones.

    num_samples_to_load = round(max(samples_to_plot,perc_dur_to_analyze*size(samples,1)));
    
    results{k}.ch2_transform = zeros(num_samples_to_load,2);
    results{k}.offset = zeros(num_samples_to_load,1);
    try
        results{k}.times = zeros(num_samples_to_load,size(samples{1,1}{1},1));
        results{k}.vals = zeros(num_samples_to_load,size(samples{1,1}{2},1));
        non_vector = 1;
    catch
        results{k}.times = zeros(num_samples_to_load,2);
        results{k}.vals = zeros(num_samples_to_load,2);
        non_vector = 0;
    end
    for j = (size(samples,1)-num_samples_to_load-1):size(samples,1)
        results{k}.ch2_transform(j,:) = samples{j,3};
        results{k}.offset(j,:) = samples{j,2};
        if non_vector == 1
            results{k}.times(j,:) = samples{j,1}{1};
            results{k}.vals(j,:) = samples{j,1}{2};
        else
            results{k}.times(j,:) = samples{j,1}(1,:);
            results{k}.vals(j,:) = samples{j,1}(2,:);
        end
    end
    
    clear samples
end