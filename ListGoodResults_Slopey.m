% function [datasets,labels,legends,colors] = ListGoodResults_Slopey(resultset)
%
% Input can be:
% 'SNF2hWvsNoyS'
% 'APM'
% 'INO80_PreboundvsNot'
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
    lgndtext{1} = 'WT/SNF2h';
    labels{1} = 'H3';
    colors{1} = 'k';
    datasets{2} = 'SNF2hNG2uMATP1mMH3Cy3APM';
    lgndtext{2} = 'E64R/SNF2h';
    labels{2} = 'H3';
    colors{2} = 'r';
    datasets{3} = 'SNF2h2RA400nMATP1mMH3Cy3';
    lgndtext{3} = 'WT/2RA SNF2h';
    labels{3} = 'H3';
    colors{3} = 'b';
    datasets{4} = 'SNF2h2RA2uMATP1mMH3Cy3APM';
    lgndtext{4} = 'E64R/2RA SNF2h';
    labels{4} = 'H3';
    colors{4} = 'm';
elseif strcmpi(resultset,'INO80_PreboundvsNot')
    datasets{1} = 'INO8015nMATP1mM378H3Cy3';
    lgndtext{1} = '15 nM INO80, 1 mM ATP';
    labels{1} = 'H3';
    colors{1} = 'b';
    datasets{2} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{2} = '15 nM INO80, prebound 10 min, 1 mM ATP';
    labels{2} = 'H3';
    colors{2} = 'c';
end