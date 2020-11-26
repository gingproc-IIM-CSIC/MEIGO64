function out = getNotNullColumns(df, candidates)
%% getNotNullColumns - Return list of 'df' columns in 'candidates' which are 
%                      not all NaN.
%
% Syntax: out = getNotNullColumns(df, candidates);
%
% Inputs
%	df - Table.
%	candidates - String. List of column names of df to consider.
%
% Outputs
%	out - String. df columns in candidates which are not all NaN..       
%
% Other m-files required: auxiliar/isemptyExt.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'df', @istable);
    addRequired(p, 'candidates', @(x) isStringType(x) || iscell(x));
    
    parse(p, df, candidates);
    df = p.Results.df;
    candidates = p.Results.candidates;    
    % ...input parsed.
    
    nColumnName = df.Properties.VariableNames;
    [~, idx] = intersect(nColumnName, candidates, 'stable');
    
    nColumnName = string(nColumnName(idx));
    mapFunc = @(x) isnumeric(df.(x)) && all(isnan(df.(x)));
    columnMask = ~map(mapFunc, nColumnName);
    out = nColumnName(columnMask);    
% ------------- END OF CODE -------------- 
end