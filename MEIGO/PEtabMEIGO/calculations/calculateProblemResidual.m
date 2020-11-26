function [r, R] = calculateProblemResidual(simulationsTable)
%% calculateProblemResidual - Calculates petab problem residual.
%
% Syntax: out = calculateProblemResidual(simulationsTable);
%
% Inputs
%	simulationsTable - Table. Petab problem simulations table as calculated
%                      by Petab's method getSimulationsTable.
%
% Outputs
%	r - Numeric. Accumulated problem residual.
%   R - Numeric. Problem residual by observable measurement.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 22-Aug-2020
%% ------------- BEGIN CODE --------------

    check = istable(simulationsTable);
    errorId = 'CALCULATEPROBLEMRESIDUAL:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(check, errorId, errorMsg);
    
    measurement = simulationsTable.measurement;
    simulation = simulationsTable.simulation;
    scale = simulationsTable.observableTransformation;
    
    R = map(@calculateSingleResidual, measurement, simulation, scale);
    r = sum(R);
% ------------- END OF CODE --------------    
end