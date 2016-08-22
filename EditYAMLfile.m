% function EditYAMLfile(filename,paramname,paramvalue)
%
% For interfacing with Matt's slopey code.
% 
% Steph 4/2016

function EditYAMLfile(filename,paramname,paramvalue)

    % load function
    function old_params = load_yml(name)
        old_params = struct();
        if exist(name,'file')
            f = fopen(name,'r');
            file_all = fscanf(f,'%c');
            for line = strsplit(file_all,'\n')
                splits = regexpi(line,'^(?<field>[a-z_]+):\s+(?<value>.*?)\s*$','names');
                if ~isempty(splits{1})
                    old_params.(splits{1}.field) = splits{1}.value;
                end
            end
            fclose(f);
        end
    end

    % write function
    function write_yml(name,new_params)
        fields = fieldnames(new_params);
        output = '';
        for p = 1:length(fields)
            param_val = new_params.(fields{p});
            if p==length(fields)
                output = [output,fields{p},':',' ',param_val];
            else
                output = [output,fields{p},':',' ',param_val,sprintf('\n')];
            end
        end
        f = fopen(name,'w');
        fprintf(f,'%s',output);
        fclose(f);
    end

    % Read in current params file, if it exists, and turn it into a Matlab
    % struct
    old = load_yml(filename);
    
    % Create or overwrite param value
    if ischar(paramvalue)
        old.(paramname) = paramvalue;
    elseif length(paramvalue) > 1
        paramvalue_text = '[';
        for u = 1:length(paramvalue)
            paramvalue_text = strcat(paramvalue_text,num2str(paramvalue(u)));
            if u~=length(paramvalue)
                paramvalue_text = strcat(paramvalue_text,',');
            end
        end
        paramvalue_text = strcat(paramvalue_text,']');
        old.(paramname) = paramvalue_text;
    else
        old.(paramname) = num2str(paramvalue);
    end
    
    % Write back to YAML file
    write_yml(filename,old);
    
end
