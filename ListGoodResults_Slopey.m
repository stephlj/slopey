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
    labels{1} = 'H2A';
    colors{1} = 'k';
    datasets{2} = 'SNF2h103nMATP1mMyS1mM';
    lgndtext{2} = '103 nM SNF2h, 1 mM ATP, 1 mM ATP';
    labels{2} = 'H2A';
    colors{2} = 'b';
elseif strcmpi(resultset,'APM')
    datasets{1} = 'SNF2hNG400nMATP1mMH3Cy3';
    lgndtext{1} = '400 nM SNF2h';
    labels{1} = 'H3';
    colors{1} = 'b';
    datasets{2} = 'SNF2hNG2uMATP1mMH3Cy3APM';
    lgndtext{2} = '2 uM SNF2h, H2A/E64R';
    labels{2} = 'H3';
    colors{2} = 'c';
    datasets{3} = 'SNF2h2RA400nMATP1mMH3Cy3';
    lgndtext{3} = '400 nM 2RA';
    labels{3} = 'H3';
    colors{3} = 'r';
    datasets{4} = 'SNF2h2RA2uMATP1mMH3Cy3APM';
    lgndtext{4} = '2 uM 2RA, H2A/E64R';
    labels{4} = 'H3';
    colors{4} = 'm';
end