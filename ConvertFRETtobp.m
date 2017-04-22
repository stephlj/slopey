% function bp = ConvertFRETtobp(FRET,label)
%
% Label can be 'H2A' or 'H3'; selects which calibration curve to use.
%
% Steph 11/2016

function bp = ConvertFRETtobp(FRET,label)

if ~exist('label','var') label = 'H3'; end

if strcmpi(label,'H3')
    d_0 = 5.8; % nm
    R0 = 10.9; % nm
    theta = 153.8; % degrees
else
    disp('ConvertFRETtobp: H2A label not implemented yet.')
    return
end

bp = (1/0.34)*(d_0*cosd(theta)+sqrt(d_0^2*((cosd(theta))^2-1)+R0^2*(1/FRET-1)^(1/3)));

if ~isreal(bp) || bp<0
    if FRET > 0.95
        bp=3;
    else
        keyboard;
    end
end