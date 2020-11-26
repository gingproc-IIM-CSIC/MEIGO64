function [chi2, chi2s] = calculateProblemChi2(simulationsTable)
%% calculateProblemChi2 - Calculates petab problem chi-squared.
%
% Syntax: out = calculateProblemChi2(simulationsTable);
%
% Inputs
%	simulationsTable - Table. Petab problem simulations table as returned
%                      by Petab's method getSimulationsTable.
%
% Outputs
%	chi2 - Numeric. Accumulated chi-squared.
%   chi2s - Numeric. Chi-Squared by observable measurement.
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
    errorId = 'CALCULATEPROBLEMCHI2:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(check, errorId, errorMsg);
    
    measurement = simulationsTable.measurement;
    simulation = simulationsTable.simulation;
    scale = simulationsTable.observableTransformation;
    noiseValue = simulationsTable.noiseFormula;
    
    chi2s = map(@calculateSingleChi2, measurement, simulation, noiseValue, scale);
    chi2 = sum(chi2s);
% ------------- END OF CODE --------------    
end