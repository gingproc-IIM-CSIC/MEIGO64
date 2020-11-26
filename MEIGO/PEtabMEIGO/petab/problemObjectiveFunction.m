function [J, g, R] = problemObjectiveFunction(optPars, petab)
%% problemObjectiveFunction - Calculates problem nllh for given optimization parameters vector.
%
% Syntax: problemObjectiveFunction(optPars, petab)
%
% Inputs
%   optPars - Numeric. Vector of optimization parameters.
%   petab - Petab. Petab object.
%
% Outputs
%   J - Numeric. Negative log-likelihood.
%   g - ¿?
%   R - Numeric. Problem residuals.
    
    % Parse input...
    p = inputParser;

    addRequired(p, 'optPars', @isnumeric);
    addRequired(p, 'petab', @Petab.isPetab);

    parse(p, optPars, petab);
    optPars = p.Results.optPars;
    petab = p.Results.petab;
    % ...input parsed.

    simulationsTable = petab.getSimulationsTable(optPars);
    J = calculateProblemLlh(simulationsTable);
    g = 0;
    R = simulationsTable.simulation - simulationsTable.measurement;
    R = reshape(R, numel(R), 1);
end