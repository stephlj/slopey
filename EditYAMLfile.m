% function EditYAMLfile(filename,paramname,paramvalue)
%
% Steph 4/2016

function EditYAMLfile(filename,paramname,paramvalue)

    % load function
    function old_params = load_yml(name)
        if exist(name,'file')
            f = fopen(name,'r');
            file_all = fscanf(f,'%c');
            old_params = struct();
            if ~isempty(file_all)
                [starts,ends] = regexpi(file_all,': \d*');
                index = 1;
                for p = 1:length(starts)
                    field = file_all(index:starts(p)-1);
                    value = file_all(starts(p)+2:ends(p));
                    old_params.(field) = value;
                    clear field value
                    index = ends(p)+2;
                end
            end
            fclose(f);
        else
            old_params = -1;
        end
    end
    % write function
    function write_yml(name,new_params)
        fields = fieldnames(new_params);
        output = '';
        for p = 1:length(fields)
            if p==length(fields)
                output = [output,fields{p},':',' ',num2str(new_params.(fields{p}))];
            else
                output = [output,fields{p},':',' ',num2str(new_params.(fields{p})),sprintf('\n')];
            end
        end
        f = fopen(name,'w');
        fprintf(f,'%s',output);
        fclose(f);
    end

    old = load_yml(filename);
    
    if ~isstruct(old)
        clear old
    end
    
    old.(paramname) = num2str(paramvalue);
    
    write_yml(filename,old);
    
end
