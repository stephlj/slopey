% function [datasets,labels,legends,colors] = ListGoodResults_Slopey(resultset)
%
% Input can be:
% 'SNF2hWvsNoyS'
% 'APM'
% 'INO80_PreboundvsNot'
% 'INO80_PreboundvsNot_Lengths'
% 'INO80_Lengths'
% 'INO80_Lengths_Prebound'
% 'INO80_prebound_ATPconccurve'
% 'INO80_Cen7878_PreboundvsNot'
% 'INO80_Cen_Lengths_Prebound'
%
% Steph 11/2016

function [datasets,labels,lgndtext,colors,XTickLabels] = ListGoodResults_Slopey(resultset)

if strcmpi(resultset,'SNF2hWvsNoyS')
    datasets{1} = 'SNF2h103nMATP1mM';
    lgndtext{1} = '103 nM SNF2h, 1 mM ATP';
    labels{1} = 'H2A';
    colors{1} = 'k';
    datasets{2} = 'SNF2h103nMATP1mMyS1mM';
    lgndtext{2} = '103 nM SNF2h, 1 mM ATP, 1 mM ATP';
    labels{2} = 'H2A';
    colors{2} = 'b';
    XTickLabels = {'wait';'p_1';'p_2'};
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
    XTickLabels = {'wait';'p_1';'p_2'};
elseif strcmpi(resultset,'INO80_PreboundvsNot')
    datasets{1} = 'INO8015nMATP1mM378H3Cy3';
    lgndtext{1} = '15 nM INO80, 1 mM ATP';
    labels{1} = 'H3';
    colors{1} = 'c';
    datasets{2} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{2} = '15 nM INO80, pre-incubation 10 min, 1 mM ATP';
    labels{2} = 'H3';
    colors{2} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_PreboundvsNot_Lengths')
    datasets{1} = 'INO8015nMATP1mM360H3Cy3';
    lgndtext{1} = '3/60, no pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'g';
    datasets{2} = 'INO8015nMATP1mM378H3Cy3';
    lgndtext{2} = '3/78, no pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'c';
    datasets{3} = 'INO8015nMpreboundATP1mM360H3Cy3';
    lgndtext{3} = '3/60, pre-incubation';
    labels{3} = 'H3';
    colors{3} = 'y';
    datasets{4} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{4} = '3/78, pre-incubation';
    labels{4} = 'H3';
    colors{4} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_Lengths_Prebound')
    datasets{1} = 'INO8015nMpreboundATP1mM360H3Cy3';
    lgndtext{1} = '3/60, pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'y';
    datasets{2} = 'INO8015nMpreboundATP1mM370H3Cy3';
    lgndtext{2} = '3/70, pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'g';
    datasets{3} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{3} = '3/78, pre-incubation';
    labels{3} = 'H3';
    colors{3} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_Lengths')
    datasets{1} = 'INO8015nMATP1mM360H3Cy3';
    lgndtext{1} = '3/60, no pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'g';
    datasets{2} = 'INO8015nMATP1mM378H3Cy3';
    lgndtext{2} = '3/78, no pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'c';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_prebound_ATPconccurve')
    datasets{1} = 'INO8015nMpreboundATP100uM378H3Cy3';
    lgndtext{1} = '0.1 mM ATP';
    labels{1} = 'H3';
    colors{1} = 'r';
    datasets{2} = 'INO8015nMpreboundATP200uM378H3Cy3';
    lgndtext{2} = '0.2 mM ATP';
    labels{2} = 'H3';
    colors{2} = 'm';
    datasets{3} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{3} = '1 mM ATP';
    labels{3} = 'H3';
    colors{3} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_Cen7878_PreboundvsNot')
    datasets{1} = 'INO8015nMATP1mMCen7878H3Cy3';
    lgndtext{1} = '78/78, no pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'c';
    datasets{2} = 'INO8015nMpreboundATP1mMCen7878H3Cy3';
    lgndtext{2} = '78/78, 10 min pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_Cen_Lengths_Prebound')
    datasets{1} = 'INO8015nMpreboundATP1mMCen6060H3Cy3';
    lgndtext{1} = '60/60, pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'y';
    datasets{2} = 'INO8015nMpreboundATP1mMCen7878H3Cy3';
    lgndtext{2} = '78/78, pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
elseif strcmpi(resultset,'INO80_CenVsEnd_Lengths_Prebound')
    datasets{1} = 'INO8015nMpreboundATP1mM360H3Cy3';
    lgndtext{1} = '3/60, pre-incubation';
    labels{1} = 'H3';
    colors{1} = 'g';
    datasets{2} = 'INO8015nMpreboundATP1mMCen6060H3Cy3';
    lgndtext{2} = '60/60, pre-incubation';
    labels{2} = 'H3';
    colors{2} = 'y';
    datasets{3} = 'INO8015nMpreboundATP1mM378H3Cy3';
    lgndtext{3} = '3/78, pre-incubation';
    labels{3} = 'H3';
    colors{3} = 'c';
    datasets{4} = 'INO8015nMpreboundATP1mMCen7878H3Cy3';
    lgndtext{4} = '78/78, pre-incubation';
    labels{4} = 'H3';
    colors{4} = 'b';
    XTickLabels = {'p_{initial}';'p_{secondary}';'p_{tertiary}'};
end