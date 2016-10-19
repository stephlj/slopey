% function results = LoadSlopeyResults(datadir,samples_to_plot,perc_dur_to_analyze,varargin)
%
% Optional inputs are for re-loading only a subset of traces (speeds up
% RunSlopeyAnalysis).
%
% Steph 4/2016

function results = LoadSlopeyResults(datadir,samples_to_plot,perc_dur_to_analyze,varargin)

if ~exist('samples_to_plot','var') samples_to_plot = 10; end % will load only the results of the last samples_to_plot iterations
if ~exist('perc_dur_to_analyze','var') perc_dur_to_analyze = 0.10; end % Will keep the last perc_dur_to_analyze% of durations

results_py = dir(fullfile(datadir,'results_slopey','*_Results.results.mat'));

if isempty(varargin)
    results = cell(1,length(results_py));
    k_vect = 1:length(results_py);
else
    results = varargin{1};
    k_vect = varargin{2};
end

for k = k_vect
    name_split = strsplit(results_py(k).name,'.');
    struct_py = load(fullfile(datadir,'results_slopey',results_py(k).name));
    struct_py = struct_py.(name_split{1});

    if isfield(struct_py.params,'discard') && strcmpi(struct_py.params.discard,'true')
        results{k}.discard = 'true';
    else
        results{k}.name = name_split{1};
        results{k}.fps = 1/struct_py.params.T_cycle;
        results{k}.data = struct_py.data;
        results{k}.start = double(struct_py.params.start);
        results{k}.end = double(struct_py.params.end);

        num_samples = size(struct_py.times_samples,1);

        % Each struct_py has:
        % times_samples: num_samples+1 by num_slopey+1 array with times in
        %     seconds of start and end of each slopey bit
        % vals_samples: num_samples+1 by num_slopey array with red intensity
        %     values for each flat bit that separates slopeys
        % ch2_samples: num_samples by 2 array with transformation parameters to
        %     obtain real green values from idealized ones
        % u_samples: num_samples by 1 vector of offsets
        % params: params struct
        % data: raw data (num_frames by 2)

        num_samples_to_load = round(max(samples_to_plot,perc_dur_to_analyze*num_samples));

        results{k}.ch2_transform = struct_py.ch2_samples(num_samples+1-num_samples_to_load:end,:);
        results{k}.offset = struct_py.u_samples(num_samples+1-num_samples_to_load:end,:);
        results{k}.times = struct_py.times_samples(num_samples+1-num_samples_to_load:end,:);
        results{k}.vals = struct_py.vals_samples(num_samples+1-num_samples_to_load:end,:);
    end
    clear struct_py
end