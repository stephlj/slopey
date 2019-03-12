% function ConvertGoodtracesToYAML(dirname)
%
% For converting parameters like discard, start and end times to slopey
% params files.
%
% Update 3/2019: Since it's actually better to crop as little as possible
% with slopey, commented out the lines that transfer start and end data to
% the YAML files. Also edited load.py to not use start and end info in the
% pyhsmm Results.mat files used for initialization.
%
% Steph 6/2016

function ConvertGoodtracesToYAML(dirname)

dirname = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',dirname);

existing_yml = dir(fullfile(dirname,'*.params.yml'));

if ~isempty(existing_yml)
    overwrite = input('params.yml exist already; overwrite? (y/n): ','s');
else
    overwrite = 'y';
end

if strcmpi(overwrite,'y')

    if exist(fullfile(dirname,'goodtraces.txt'),'file')
        f = fopen(fullfile(dirname,'goodtraces.txt'),'r');
        file_all = fscanf(f,'%c');
        index = 1;
        if ~isempty(file_all)
            starts = regexpi(file_all,'\n*');
            % Iterate through each line and create/modify YAML as necessary:
            for p = 1:length(starts)+1
                if p==length(starts)+1
                    currtrace = file_all(starts(p-1)+1:end);
                    spaces(1)=length(currtrace);
                else
                    currtrace = file_all(index:starts(p));
                    spaces = regexpi(currtrace,'\s*');
                end
                trace_name = strcat(currtrace(1:spaces(1)-5),'_Results');
                trace_name = strrep(trace_name,filesep,'_');
                if currtrace(1)=='#'
                    EditYAMLfile(fullfile(dirname,strcat(trace_name(2:end),'.params.yml')),'discard','true');
                end
                if ~strcmpi(currtrace(end-3:end-1),'mat')
                    [start_index,start_end] = regexpi(currtrace,'start=\d*');
                    [end_index,end_end] = regexpi(currtrace,'end=\d*');
%                     if ~isempty(start_index)
%                         start_str = currtrace(start_index:start_end);
%                         start_val = str2num(start_str(strfind(start_str,'=')+1:end));
%                         EditYAMLfile(fullfile(dirname,strcat(trace_name,'.params.yml')),'start',start_val);
%                     end
%                     if ~isempty(end_index)
%                         end_str = currtrace(end_index:end_end);
%                         end_val = str2num(end_str(strfind(end_str,'=')+1:end));
%                         EditYAMLfile(fullfile(dirname,strcat(trace_name,'.params.yml')),'end',end_val);
%                     end
                end
                if p~=length(starts)+1
                    index = starts(p)+1;
                end
            end
        end
        fclose(f);
    else
        disp('No goodtraces file?')
        return
    end

    % Also including information from the tokeep vector:
    allnames = dir(fullfile(dirname,'*_Results.mat'));
    if exist(fullfile(dirname,'ToAnalyzeFurther.mat'),'file')
        tokeep = load(fullfile(dirname,'ToAnalyzeFurther.mat'));
        tokeep = tokeep.tokeep;
        for t = 1:length(tokeep)
            if tokeep(t)==0
                EditYAMLfile(fullfile(dirname,strcat(allnames(t).name(1:end-4),'.params.yml')),'discard','true');
            end
        end
    end

end