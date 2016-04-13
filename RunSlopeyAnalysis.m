% function RunSlopeyAnalysis()
%
% Steph 4/2016

function RunSlopeyAnalysis()

samples_to_plot = 10; % will plot the results of the last samples_to_plot iterations

fig_pos = [100,400,900,700];

maindir = '/Users/Steph/Documents/UCSF/Narlikar lab/HMM analysis Slopey/slopey';

setenv('PYTHONPATH', ['/Users/Steph/code/:', getenv('PYTHONPATH')]);
setenv('PATH', ['/Users/Steph/miniconda/bin/:', getenv('PATH')]);

system('make'); % Update anything that needs updating

names = dir(fullfile(maindir,'data','*.mat'));

% allresults = load(fullfile(maindir,'results','all_results.mat'));
results = LoadSlopeyResults(data_name);

    % Given red intensities and the fit parameters for green channel,
    % return non-idealized green
    function green = redtogreen(red,maxRed,a,b)
        green = a.*(maxRed-red)+b;
    end

all_first_duration = [];
all_second_duration = [];
all_third_duration = [];

%k=1;
figure('Position',fig_pos)
disp(',: back one trace; .: forward; d: _d_iscard (do not keep for further analysis)')
disp('or un-discard; z: zoom; u: unzoom; r: _r_edo Gibbs sampling on this one trace')

%while k <= length(names)
for k=1:length(names)
    currstruct = eval(strcat('allresults.',names(k).name(1:end-4)));
    samples = currstruct.samples;
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
    
    % Going to plot the last 10 samples on the trace, and histogram the
    % last 10% of slopey bit durations.
    
    fps = 1/currstruct.params.T_cycle;
    xvectData = ((1:length(currstruct.data))./fps); % currstruct.data is in frames, need to plot vs seconds
    
    % QUESTION: Do I need to concern myself with the offset parameter?
    
    subplot('Position',[0.1 .6 .85 .35])
    plot(xvectData,currstruct.data(:,1),'xr')
    hold on
    title(strcat(names(k).name(1:end-4)),'Fontsize',14,'Interpreter','none')
    set(gca,'Fontsize',12)
    xlabel('Time (sec)','Fontsize',14)
    ylabel('Intensity (a.u.)','Fontsize',14)
    plot(xvectData,currstruct.data(:,2),'xg')
    for b = 0:samples_to_plot-1
        try
            times = samples{end-b,1}{1};
            vals = samples{end-b,1}{2};
            num_times = length(samples{end-b,1}{1});
        catch
            times = samples{end-b,1}(1,:);
            vals = samples{end-b,1}(2,:);
            num_times = 2;
        end
        max_red = max(vals);
        for kk = 1:num_times
            temp_time = times(kk)+double(currstruct.params.start)/fps;
            temp_red = vals(floor(kk/2)+1);
            temp_green = redtogreen(vals(floor(kk/2)+1),...
                max_red,samples{end-b,3}(1),samples{end-b,3}(2));
            plot(temp_time,temp_red,'ob')
            plot(temp_time,temp_green,'ok')
            if kk==1
                plot([double(currstruct.params.start)/fps,temp_time],[temp_red, temp_red],'--b')
                plot([double(currstruct.params.start)/fps,temp_time],[temp_green, temp_green],'--k')
            elseif kk == num_times
                plot([times(kk-1)+double(currstruct.params.start)/fps,...
                        temp_time],...
                     [vals(floor((kk-1)/2)+1) temp_red],...
                     '--b')
                 plot([times(kk-1)+double(currstruct.params.start)/fps,...
                        temp_time],...
                     [redtogreen(vals(floor((kk-1)/2)+1),...
                            max_red,samples{end-b,3}(1),samples{end-b,3}(2)),...
                        temp_green],...
                     '--k')
                plot([temp_time,double(currstruct.params.end)/fps],[temp_red temp_red],'--b')
                plot([temp_time,double(currstruct.params.end)/fps],[temp_green temp_green],'--b')
            else
                plot([times(kk-1)+double(currstruct.params.start)/fps,...
                        temp_time],...
                     [vals(floor((kk-1)/2)+1) temp_red],...
                     '--k')
                 plot([times(kk-1)+double(currstruct.params.start)/fps,...
                        temp_time],...
                     [redtogreen(vals(floor((kk-1)/2)+1),...
                            max_red,samples{end-b,3}(1),samples{end-b,3}(2)),...
                      temp_green],'--k')
            end
                
        end
    end
    hold off
    
    % Now plot the last 10% of the slopey durations:
    first_duration = [];
    second_duration = [];
    third_duration = [];
    for d = length(samples):-1:(length(samples)-length(samples)/10)
        try
            times = samples{d,1}{1};
            num_times = length(samples{d,1}{1});
        catch
            times = samples{d,1}(1,:);
            num_times = 2;
        end
        first_duration(end+1) = times(2) - times(1);
        if num_times > 2
            second_duration(end+1) = times(4) - times(3);
            if num_times > 4
                third_duration(end+1) = times(6) - times(5);
            end
        end
    end
    
    subplot('Position',[0.1 .1 .25 .4])
    [n1,xout] = hist(first_duration,[0:.05:2]);
    n1 = n1./sum(n1);
    bar(xout,n1)
    xlim([0 2])
    title('t_1','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)
    
    subplot('Position',[0.4 .1 .25 .4])
    n2 = hist(second_duration,[0:.05:2]);
    n2 = n2./sum(n2);
    bar(xout,n2)
    xlim([0 2])
    title('t_2','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)
    
    subplot('Position',[0.7 .1 .25 .4])
    n3 =hist(third_duration,[0:.05:2]);
    n3 = n3./sum(n3);
    bar(xout,n3)
    xlim([0 2])
    title('t_3','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)
    
    all_first_duration = [all_first_duration, first_duration];
    all_second_duration = [all_second_duration, second_duration];
    all_third_duration = [all_third_duration, third_duration];
  
    pause
end

close
figure('Position',[100,800,900,350])
    subplot('Position',[0.1 .1 .25 .8])
    [n1,xout] = hist(all_first_duration,[0:.05:2]);
    n1 = n1./sum(n1);
    bar(xout,n1)
    xlim([0 2])
    title('t_1','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)
    
    subplot('Position',[0.4 .1 .25 .8])
    n2 = hist(all_second_duration,[0:.05:2]);
    n2 = n2./sum(n2);
    bar(xout,n2)
    xlim([0 2])
    title('t_2','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)
    
    subplot('Position',[0.7 .1 .25 .8])
    n3 =hist(all_third_duration,[0:.05:2]);
    n3 = n3./sum(n3);
    bar(xout,n3)
    xlim([0 2])
    title('t_3','Fontsize',14)
    xlabel('Duration (sec)','Fontsize',14)
    ylabel('Frequency','Fontsize',14)
    set(gca,'Fontsize',12)

end

