function out = concatTables(nTable, varargin)
%% concatTables - Concatenate tables, provided as tables, or filenames and a 
% parser.
%
% Syntax: out = concatTable(nTable, fileParser);
%
% Inputs
%	nTable - Table or string type. Tables to join, as tables or filenames.
%	fileParser - Optional.Function handle. Function used to read the table in 
%                 case filenames are provided, accepting a filename as only 
%                 argument.
%
% Outputs
%   out - Table. Concatenated tables (by rows).
%
% Example
%   out = concatTables('dir/table.tsv', @getTableFunction)
%   out = concatTables(["dir/table1.tsv", "dir/table2.tsv"], @getTableFunction)
%   out = concatTables({"dir/table1.tsv", table2}, @getTableFunction)
%   out = concatTables({table2, table2}, @getTableFunction)
%
% Other m-files required: auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none
%
% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 16-May-2020
%% ------------- BEGIN CODE --------------    
    % Parse input...
    p = inputParser;
    
    addRequired(p, 'nTable', @(x) isStringType(x) || istable(x) || iscell(x));
    addOptional(p, 'fileParser', function_handle.empty, ...
                @(x) isa(x, 'function_handle'));
    
    parse(p, nTable, varargin{:});
    nTable = p.Results.nTable;
    fileParser = p.Results.fileParser;    
    % ...input parsed    
    
    % Convert string type argument to cell string.
    if isStringType(nTable), nTable = cellstr(nTable); end
    
    n = numel(nTable);
    tableCell = cell(1, n);
    for i = 1:n
        iTable = nTable{i};
        if istable(iTable)
            tableCell{i} = iTable;
        else
            tableCell{i} = fileParser(iTable);
        end
    end
    
    out = tableCell{1};
    for i = 2:n, out = union(out, tableCell{i}, 'rows', 'stable'); end
% ------------- END OF CODE --------------
end
