% function PlotSlopeyResults(input_struct,samples_to_plot,perc_dur_to_analyze,discard,xlims)
%
% Given the slopey analysis results for one trace, plots the results of the last
% samples_to_plot iterations on top of the raw data, and histograms the
% last perc_dur_to_analyze percent of the sampled durations. Returns the
% durations it histograms.
%
% Steph 4/2016

function [first_dur, second_dur, third_dur] = PlotSlopeyResults(input_struct,...
    samples_to_plot,perc_dur_to_analyze,discard,xlims)

if ~exist('samples_to_plot','var') samples_to_plot = 10; end % will plot the results of the last samples_to_plot iterations
if ~exist('perc_dur_to_analyze','var') perc_dur_to_analyze = 0.10; end % Will keep the last perc_dur_to_analyze% of durations
if ~exist('discard','var') discard = 'false'; end
if ~exist('xlims','var') xlims = [0 0]; end

smooth_width = 5;

    % Given red intensities and the fit parameters for green channel,
    % return non-idealized green
    function green = redtogreen(red,maxRed,a,b)
        green = a.*(maxRed-red)+b;
    end

    % plot histograms
    function plot_histo(durations,t,subfig_pos)
        subplot('Position',subfig_pos)
        [n,xout] = hist(durations,[0:.05:3]);
        n = n./sum(n);
        bar(xout,n)
        xlim([0 3])
        title(t,'Fontsize',14)
        xlabel('Duration (sec)','Fontsize',14)
        ylabel('Frequency','Fontsize',14)
        set(gca,'Fontsize',12)
    end

    start_time = input_struct.start/input_struct.fps;
    end_time = input_struct.end/input_struct.fps;
    
    % Going to plot the last 10 samples on the trace, and histogram the
    % last 10% of slopey bit durations.
    
    xvectData = ((1:size(input_struct.data,1))./input_struct.fps); % input_struct.data is in frames, need to plot vs seconds
    
    % QUESTION: Do I need to concern myself with the offset parameter?
    
    subplot('Position',[0.1 .6 .85 .35])
    if ~strcmpi(discard,'true')
        plot(xvectData,input_struct.data(:,1),'xr')
        hold on
        plot(xvectData,input_struct.data(:,2),'xg')
        % Update 9/2016: adding a smoothed overlay
        plot(xvectData,medfilt2(input_struct.data(:,1),[smooth_width,1]),'-r','Linewidth',1)
        plot(xvectData,medfilt2(input_struct.data(:,2),[smooth_width,1]),'-g','Linewidth',1)
        for b = 0:samples_to_plot-1
            times = input_struct.times(end-b,:)+start_time;
            vals = input_struct.vals(end-b,:);
            max_red = max(vals);
            for kk = 1:length(times)
                curr_time = times(kk);
                curr_red = vals(floor(kk/2)+1);
                curr_green = redtogreen(curr_red,...
                    max_red,input_struct.ch2_transform(end-b,1),input_struct.ch2_transform(end-b,2));
                if kk>1
                    prev_time = times(kk-1);
                    prev_red = vals(floor((kk-1)/2)+1);
                    prev_green = redtogreen(prev_red,...
                        max_red,input_struct.ch2_transform(end-b,1),input_struct.ch2_transform(end-b,2));
                end

                plot(curr_time,curr_red,'ob')
                plot(curr_time,curr_green,'ok')
                if kk==1
                    plot([start_time,curr_time],[curr_red, curr_red],'--b')
                    plot([start_time,curr_time],[curr_green, curr_green],'--k')
                elseif kk == length(times)
                    plot([prev_time,curr_time],[prev_red curr_red],'--b')
                    plot([prev_time,curr_time],[prev_green,curr_green],'--k')
                    plot([curr_time,end_time],[curr_red curr_red],'--b')
                    plot([curr_time,end_time],[curr_green curr_green],'--b')
                else
                    plot([prev_time,curr_time],[prev_red curr_red],'--k')
                    plot([prev_time,curr_time],[prev_green,curr_green],'--k')
                end

            end
            clear times vals max_red
        
        end
    else
        plot(xvectData,input_struct.data(:,1),'xk')
        hold on
        plot(xvectData,input_struct.data(:,2),'xk')
    end
    title(input_struct.name,'Fontsize',14,'Interpreter','none')
    set(gca,'Fontsize',12)
    xlabel('Time (sec)','Fontsize',14)
    ylabel('Intensity (a.u.)','Fontsize',14)
    if isequal(xlims,[0 0])
        xlim([max(0,start_time-10) min(end_time+10,length(xvectData))])
    else
        xlim(xlims)
    end
    hold off
    
    % Now plot the last 10% of the slopey durations:
    first_dur = [];
    second_dur = [];
    third_dur = [];
    for d = length(input_struct.offset):-1:(length(input_struct.offset)-length(input_struct.offset)/(perc_dur_to_analyze*100))
        times = input_struct.times(d,:);
        first_dur(end+1) = times(2) - times(1);
        if length(times) > 2
            second_dur(end+1) = times(4) - times(3);
            if length(times) > 4
                third_dur(end+1) = times(6) - times(5);
            end
        end
    end
    
    plot_histo(first_dur,'t_1',[0.1 .1 .25 .4]);
    plot_histo(second_dur,'t_2',[0.4 .1 .25 .4]);
    plot_histo(third_dur,'t_3',[0.7 .1 .25 .4]);

end