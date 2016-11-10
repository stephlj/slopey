% function bp = ConvertFRETtobp(FRET,label)
%
% Label can be 'H2A' or 'H3'; selects which calibration curve to use.
%
% Steph 11/2016

function bp = ConvertFRETtobp(FRET,label)

if ~exist('label','var') label = 'H3'; end

if strcmpi(label,'H3')
    R0 = 9.5;
    a = 9.5;
else
    disp('ConvertFRETtobp: H2A label not implemented yet.')
    return
end

bp = sqrt(9*(R0^6/FRET-1)^(1/3)-9*a^2);