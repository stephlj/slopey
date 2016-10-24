% function RunSlopeyAnalysis(datadir_to_analyze)
%
% datadir_to_analyze is a folder in HMMresults.
%
% Steph 4/2016

function RunSlopeyAnalysis(datadir_to_analyze)

samples_to_plot = 10; % will plot the results of the last samples_to_plot iterations
perc_dur_to_analyze = 0.001; % Will keep the last perc_dur_to_analyze% of durations

fig_pos = [100,400,900,700];
figure('Position',fig_pos)

% maindir = '/Users/Steph/Documents/UCSF/Narlikar lab/HMM analysis Slopey/slopey';
if strcmpi(datadir_to_analyze,'SlopeyHospital')
    maindir = fullfile('/Users/Steph/Desktop',datadir_to_analyze);
else
    maindir = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',...
        datadir_to_analyze);
end
symdir = '~/Documents/symlink/HMM_analysis_Slopey';
codedir = cd;

setenv('PYTHONPATH', ['/Users/Steph/code/:', getenv('PYTHONPATH')]);
setenv('PATH', ['/Users/Steph/miniconda/bin/:', getenv('PATH')]);
% setenv('MATLAB', '1')

% system('make'); % Update anything that needs updating
cd(symdir)
system(strcat(fullfile('MATLAB=1 ./Analyze_Slopey.sh Symlinks_Data',datadir_to_analyze),' -j2'));
cd(codedir)

% names = dir(fullfile(maindir,'*_Results.mat'));

% allresults = load(fullfile(maindir,'results','all_results.mat'));
results = LoadSlopeyResults(maindir,samples_to_plot,perc_dur_to_analyze);

all_first_duration = [];
all_second_duration = [];
all_third_duration = [];

    % plot histograms
    function plot_histo(durations,t,subfig_pos)
        subplot('Position',subfig_pos)
        [n,xout] = hist(durations,[0:.05:2]);
        n = n./sum(n);
        bar(xout,n)
        xlim([0 2])
        title(t,'Fontsize',14)
        xlabel('Duration (sec)','Fontsize',14)
        ylabel('Frequency','Fontsize',14)
        set(gca,'Fontsize',12)
    end

k=1;
disp(',: back one trace; .: forward; s: change _s_tart crop; e: change _e_nd crop')
disp('n: change _n_umber of slopey bits; i: change _i_nitialization; d: _d_iscard from analysis')
disp('z: _z_oom; u: _u_nzoom')

xlims=[0,0];

while k <= length(results)
    currstruct = results{k};
    
    if ~isfield(results{k},'discard') || (isfield(results{k},'discard') && ~strcmpi(results{k}.discard,'true'))
    
        [first_duration, second_duration, third_duration] = PlotSlopeyResults(currstruct,...
            samples_to_plot,'false',xlims);

        all_first_duration = [all_first_duration, first_duration];
        all_second_duration = [all_second_duration, second_duration];
        all_third_duration = [all_third_duration, third_duration];

        % interactive section
        cc=1;
        while cc~=13
            ct=waitforbuttonpress;
            cc=get(gcf,'currentcharacter');

            if ct==1
                % Go forward to the next trace
                if cc=='.'
                    k = k+1;
                    cc = 13;
                % Go back one trace
                elseif cc==',' 
                    if k>1
                        k=k-1;
                    end
                    cc=13;
                % Zoom
                elseif cc=='z'
                    [x,~] = ginput(2);
                    x = sort(x);
                    if x(1)<0
                        x(1)=1;
                    end
                    if round(x(2)*currstruct.fps)>size(currstruct.data,1)
                        x(2)=round(size(currstruct.data,1)/currstruct.fps);
                    end
                    xlims(1) = x(1);
                    xlims(2) = x(2);
                    cc=13;
                % Unzoom
                elseif cc=='u'
                    xlims = [0,0];
                    cc=13;
                % Change start or end crop
                elseif cc=='s' || cc=='e'
                    [x,~] = ginput(1);
                    x = round(x*currstruct.fps);
                    if x>0 && x<size(currstruct.data,1)
                        if cc=='s'
                            EditYAMLfile(fullfile(maindir,strcat(currstruct.name,'.params.yml')),'start',x);
                        else
                            EditYAMLfile(fullfile(maindir,strcat(currstruct.name,'.params.yml')),'end',x);
                        end
                        cd(symdir)
                        system(fullfile('./Analyze_Slopey.sh Symlinks_Data',datadir_to_analyze));
                        cd(codedir)
                        results = LoadSlopeyResults(maindir,samples_to_plot,perc_dur_to_analyze,results,k);
                    else
                        disp('Invalid start value')
                    end
                    cc=13;
                % Change initialization or num_slopey
                elseif cc=='n' || cc=='i'
                    if cc=='n' || ~isfield(currstruct,'num_slopey')
                        new_num = round(input('How many slopey bits to find? '));
                    else
                        new_num = currstruct.num_slopey;
                    end
                    if new_num>0
                        u = 1;
                        new_init = zeros(new_num,1);
                        while u <= new_num
                            disp(strcat('Click on the approximate middle of slopey bit ',int2str(u)))
                            [x,~] = ginput(1);
                            x = round(x*currstruct.fps);
                            if x>0 && x<size(currstruct.data,1)
                                new_init(u) = x;
                                u = u+1;
                            end
                            clear x
                        end
                        EditYAMLfile(fullfile(maindir,strcat(currstruct.name,'.params.yml')),'translocation_frame_guesses',new_init);
                        cd(symdir)
                        system(fullfile('./Analyze_Slopey.sh Symlinks_Data',datadir_to_analyze));
                        cd(codedir)
                        results = LoadSlopeyResults(maindir,samples_to_plot,perc_dur_to_analyze,results,k);
                    end
                    cc=13;
                % Discard from further analysis
                elseif cc=='d'
                    EditYAMLfile(fullfile(maindir,strcat(currstruct.name,'.params.yml')),'discard','true');
                    cd(symdir)
                    system(strcat(fullfile('./Analyze_Slopey.sh Symlinks_Data',datadir_to_analyze),' clean_discards'));
                    system(fullfile('./Analyze_Slopey.sh Symlinks_Data',datadir_to_analyze));
                    cd(codedir)
                    results = LoadSlopeyResults(maindir,samples_to_plot,perc_dur_to_analyze,results,k);
                    cc=13;
                % Don't let extra "enters" build up:
                elseif isequal(cc,char(13)) %13 is the ascii code for the return key
                    cc=13;
                end
            end
        end
    else
        k = k+1;
    end
  
end

close
figure('Position',[100,800,900,350])
plot_histo(all_first_duration,'t_1',[0.1 .1 .25 .8]);
plot_histo(all_second_duration,'t_2',[0.4 .1 .25 .8]);
plot_histo(all_third_duration,'t_3',[0.7 .1 .25 .8]);

end

