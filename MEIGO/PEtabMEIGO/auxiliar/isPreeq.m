function out = isPreeq(df)
%% isPreeq - Checks df argument for valid preequilibrationConditionId column.
%
% Syntax: out = isPreeq(df)
%
% Inputs
%   df - Table. Any PEtab table.
%
% Outputs
%   out - Logical. True if df has a valid preequilibrationConditionId column, 
%         else false.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------
    errorId = 'ISPREEQ:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(istable(df), errorId, errorMsg);
    
    out = false;    
    
    columnNames = df.Properties.VariableNames;
    preeqTest = ismember('preequilibrationConditionId', columnNames) && ...
                ~isnumeric(df.preequilibrationConditionId);
    if preeqTest, out = true; end
% ------------- END OF CODE --------------    
end