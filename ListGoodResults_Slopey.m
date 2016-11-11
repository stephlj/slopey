% function [datasets,labels,legends,colors] = ListGoodResults_Slopey(resultset)
%
% Input can be:
% 'SNF2hWvsNoyS'
%
% Steph 11/2016

function [datasets,labels,lgndtext,colors] = ListGoodResults_Slopey(resultset)

if strcmpi(resultset,'SNF2hWvsNoyS')
    datasets{1} = 'SNF2h103nMATP1mM';
    lgndtext{1} = '103 nM SNF2h, 1 mM ATP';
    labels{1} = 'H3';
    colors{1} = 'k';
    datasets{2} = 'SNF2h103nMATP1mMyS1mM';
    lgndtext{2} = '103 nM SNF2h, 1 mM ATP, 1 mM ATP';
    labels{2} = 'H3';
    colors{2} = 'b';
end