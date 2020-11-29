function simCondDf = getSimulationConditions(measurementDf)
%% getSimulationConditions - Create a table of separate simulation conditions. 
% A simulation condition is a specific combination of simulationConditionId 
% and preequilibrationConditionId.
%
% Syntax: out = getSimulationConditions(measurementDf);
%
% Inputs
%   measurementDf - Table. PEtab measurements table.
%
% Outputs
%    simCondDf - Table. Table with columns simulationConditionId and 
%                preequilibrationConditionId. All null columns will be 
%                omitted.
%
% Other m-files required: auxiliar/getNotnullColumns.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    errorId = 'GETSIMULATIONCONDITIONS:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(istable(measurementDf), errorId, errorMsg);    
    
    groupingCols = getNotNullColumns(measurementDf,  ...
        ["preequilibrationConditionId", "simulationConditionId"]);    
    simCondDf = measurementDf(:, groupingCols);
    simCondDf = unique(simCondDf, 'rows', 'stable');
% ------------- END OF CODE --------------      
end