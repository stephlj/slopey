% function bp = ConvertFRETtobp(FRET,label)
%
% Label can be 'H2A' or 'H3'; selects which calibration curve to use.
%
% Steph 11/2016

function bp = ConvertFRETtobp(FRET,label)

if ~exist('label','var') label = 'H3'; end

if strcmpi(label,'H3')
    a = 47.2; % nm
    R0 = 61.62; % nm
    c = 0.1254; % FRET
else
    disp('ConvertFRETtobp: H2A label not implemented yet.')
    return
end

% wrong equation!
% bp = sqrt((3.4)^2*(R0^6/FRET-1)^(1/3)-(3.4)^2*a^2);

bp = 0.34*sqrt(R0^2*(1/(FRET-c)-1)^(1/3)-a^2);

if ~isreal(bp)
    if FRET > 0.95
        bp=3;
    else
        keyboard;
    end
end