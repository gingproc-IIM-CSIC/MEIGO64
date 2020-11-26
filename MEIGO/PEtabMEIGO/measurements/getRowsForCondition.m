function out = getRowsForCondition(measurementDf, condition)
%% getMeasurementDf - Extract rows in measurement table for condition according
% to preequilibrationConditionId and simulationConditionId in condition.
%
% Syntax: out = getMeasurementDf(measurementDf, condition);
%
% Inputs
%   measurementDf - PEtab measurement table.
%   condition - Table. Table with single row and columns 
%               preequilibrationConditionId and simulationConditionId. Or a 
%               dictionary with those keys.
%
% Outputs
%    out - Table. Subselection of rows in measurement table for given condition.
%
% Other m-files required: lint/assertNoLeadingTrailingWhitespace.m,
%                         auxiliar/tableSubset.m, auxiliar/tableSubset.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'measurementDf', @istable);
    addRequired(p, 'condition', @(x) istable(x) || Dict.isDict(x));
    
    parse(p, measurementDf, condition);
    measurementDf = p.Results.measurementDf;
    condition = p.Results.condition;
    % ...input parsed.
    
    if istable(condition)
        columns = condition.Properties.VariableNames;
        conditionIds = condition{1, :};
    else 
        columns = condition.keys;
        conditionIds = string(condition.values);
    end
    
    out = tableSubset(measurementDf, columns, conditionIds);
% ------------- END OF CODE --------------     
end