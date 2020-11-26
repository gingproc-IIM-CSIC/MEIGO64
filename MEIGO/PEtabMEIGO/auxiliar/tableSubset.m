function out = tableSubset(df, columnName, columnValue)
%% tableSubset - Returns the subset of table by column value.
%
% Syntax: out = tableSubset(df, nColumnName, nColumnValue);
%
% Inputs
%	df - Table.
%	columnName - String or cell. Table column names.
%	columnValue - Any type. Column value to match.
%
% Outputs
%	out - Table. Matching table subset.
%
% Example:
%   out = tableSubset(df, "col1", 12.5);
%   out = tableSubset(df, ["col1", "col2"], {12.5 'word'});
%
% Other m-files required: auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 18-May-2020
%% ------------- BEGIN CODE -------------- 

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'df', @istable);
    addRequired(p, 'columnName', @(x) isStringType(x) || iscellstr(x));
    addRequired(p, 'columnValue');
    
    parse(p, df, columnName, columnValue);
    df = p.Results.df;
    columnName = string(p.Results.columnName);
    columnValue = p.Results.columnValue;
    % ...input parsed.
    
    columnDict = Dict(columnName, columnValue);    
    for i = columnDict.keys
        check = ismember(i, df.Properties.VariableNames);
        errorId = 'TABLESUBSET:ColumnNotInTableError';
        errorMsg = 'Column %s not in table';
        assert(check, errorId, errorMsg, i);
        
        column = df.(i);
        if iscell(column), column = string(column); end
        df = df(column == columnDict(i), :);        
    end
    
    out = df;
% ------------- END OF CODE --------------    
end