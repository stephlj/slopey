% function PlotSlopeyResults_ForAnimation(input_struct)
%
% maindir = fullfile('/Users/Steph/Documents/UCSF/Narlikar lab/smFRET data analysis/HMM results',...
%        datadir_to_analyze);
% results = LoadSlopeyResults(maindir,100001);
% PlotSlopeyResults_ForAnimation(results)
%
% Steph and Matty 6/2019

function PlotSlopeyResults_ForAnimation(input_struct)

savedir = '/Users/Steph/Desktop/SlopeyTalkFigs/SlopeyAnimationAug04_3_371';
xlims = [120 145]; 
input_struct = input_struct{33};

% savedir = '/Users/Steph/Desktop/SlopeyTalkFigs/SlopeyAnimationAug04_2_428';
% xlims = [100 120];
% input_struct = input_struct{20};

saved_movie = VideoWriter(fullfile(savedir,'MHwander.avi'));
open(saved_movie);

    % Given red intensities and the fit parameters for green channel,
    % return non-idealized green
    function green = redtogreen(red,maxRed,a,b)
        green = a.*(maxRed-red)+b;
    end

    start_time = input_struct.start/input_struct.fps;
    end_time = input_struct.end/input_struct.fps;
    
    xvectData = ((1:size(input_struct.data,1))./input_struct.fps); % input_struct.data is in frames, need to plot vs seconds
    
        h = figure('visible','off');
        
        for b = 1:50:25000
              
            hold on
            plot(xvectData,input_struct.data(:,1),'xr')
            
            plot(xvectData,input_struct.data(:,2),'xg')
            
            times = input_struct.times(b,:)+start_time-input_struct.offset(b);
            vals = input_struct.vals(b,:);
            max_red = max(vals);
            for kk = 1:length(times)
                curr_time = times(kk);
                curr_red = vals(floor(kk/2)+1);
                curr_green = redtogreen(curr_red,...
                    max_red,input_struct.ch2_transform(b,1),input_struct.ch2_transform(b,2));
                if kk>1
                    prev_time = times(kk-1);
                    prev_red = vals(floor((kk-1)/2)+1);
                    prev_green = redtogreen(prev_red,...
                        max_red,input_struct.ch2_transform(b,1),input_struct.ch2_transform(b,2));
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
            
            set(gca,'Fontsize',12)
            xlabel('Time (sec)','Fontsize',14)
            ylabel('Intensity (a.u.)','Fontsize',14)
            xlim(xlims)
            
            print('-dpng',fullfile(savedir,strcat(sprintf('%06d', b),'.png')))
            hold off
            frame = getframe(h);
            writeVideo(saved_movie,frame);
            clf
        end
    
    close(saved_movie);

end