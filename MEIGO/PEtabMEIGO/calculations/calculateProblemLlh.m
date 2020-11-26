function [llh, llhs]= calculateProblemLlh(simulationsTable)
%% calculateProblem - Calculates petab problem log-likelihood.
%
% Syntax: out = calculateProblem(simulationsTable);
%
% Inputs
%	simulationsTable - Table. Petab problem simulations table as returned
%                      by Petab's method getSimulationsTable.
%
% Outputs
%	llh - Numeric. Accumulated log-likelihood.
%   llhs - Numeric. Log-likelihood by observable measurement.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-Aug-2020
%% ------------- BEGIN CODE --------------

    check = istable(simulationsTable);
    errorId = 'CALCULATEPROBLEMLLH:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(check, errorId, errorMsg);
    
    measurement = simulationsTable.measurement;
    simulation = simulationsTable.simulation;
    scale = simulationsTable.observableTransformation;
    noiseDistribution = simulationsTable.noiseDistribution;
    noiseValue = simulationsTable.noiseFormula;
    
    llhs = map(@calculateSingleLlh, measurement, simulation, scale, noiseDistribution, noiseValue);
    llh = sum(llhs);
% ------------- END OF CODE --------------    
end