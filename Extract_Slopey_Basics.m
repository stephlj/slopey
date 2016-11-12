% function Extract_Slopey_Basics()
%
% Takes the output of CalcAvgSlopey and computes the durations, FRET values
% and bp values of each pause and the durations and changes in FRET and bp
% of each translocation.
%
% This excludes everything after backsteps.
%
% Steph 11/2016

function [p_dur,t_dur,p_FRET,t_dFRET,p_bp,t_dbp] = Extract_Slopey_Basics(times,FRETvals,label)

% Excluding any states lower than this (assume out of FRET range at this point)
% and also excluding any translocations that extend past this floor:
MaxFRETEnd = 0.275;

for kk = 1:2:length(times)
    if FRETvals(ceil(kk/2))>MaxFRETEnd
        p_dur(ceil(kk/2)) = times(kk+1)-times(kk);
        p_FRET(ceil(kk/2)) = FRETvals(ceil(kk/2));
        p_bp(ceil(kk/2)) = ConvertFRETtobp(FRETvals(ceil(kk/2)),label);
        if ceil(kk/2)+1<=length(FRETvals) && ...
                FRETvals(ceil(kk/2)+1)>MaxFRETEnd && FRETvals(ceil(kk/2)+1)<FRETvals(ceil(kk/2))
            t_dur(ceil(kk/2)) = times(kk+2)-times(kk+1);
            t_dFRET(ceil(kk/2)) = FRETvals(ceil(kk/2))-FRETvals(ceil(kk/2)+1);
            t_dbp(ceil(kk/2)) = ConvertFRETtobp(FRETvals(ceil(kk/2)+1),label)-ConvertFRETtobp(FRETvals(ceil(kk/2)),label);
        else
            if ~exist('t_dur','var')
                t_dur = -1;
            end
            if ~exist('t_dFRET','var')
                t_dFRET = -1;
            end
            if ~exist('t_dbp','var')
                t_dbp = -1;
            end
            break
        end
    else
        if ~exist('p_dur','var')
            p_dur = -1;
        end
        if ~exist('t_dur','var')
            t_dur = -1;
        end
        if ~exist('p_FRET','var')
            p_FRET = -1;
        end
        if ~exist('t_dFRET','var')
            t_dFRET = -1;
        end
        if ~exist('p_bp','var')
            p_bp = -1;
        end
        if ~exist('t_dbp','var')
            t_dbp = -1;
        end
        break
    end
end