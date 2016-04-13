% function success = EditYAMLfile(filename,paramname,paramvalue)
%
% Steph 4/2016

function success = EditYAMLfile(filename,paramname,paramvalue)

    % load function
    function old_params = load_yml(name)
        if exist(name,'file')
            f = fopen(name,'r');
            file_all = fread(f);
%             % How do I know if these fields exist?
            old_params.start = file_all(blah);
            old_params.end = file_all(blah);
            old_params.num_slopey = file_all(blah);
            fclose(f);
        else
            old_params = -1;
        end
    end
    % write function
    function success = write_yml(name,new_params)
        f = fopen(name,'w');
        if isfield(old_params.start)
            
        end
        if isfield(old_params.end)
            
        end
        if isfield(old_params.num_slopey)
            
        end
        fclose(f);
    end

    old = load_yml(filename);
    
    if ~isstruct(old)
        clear old
    end
    
    if strcmpi(paramname,'start')
        old.start = paramvalue;
    elseif strcmpi(paramname,'end')
        old.end = paramvalue;
    elseif strcmpi(paramname,'num_slopey')
        old.num_slopey = paramvalue;
    end
    
    success = write_yml(filename,old);
    
end
