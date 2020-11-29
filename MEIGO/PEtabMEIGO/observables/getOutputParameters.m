function out = getOutputParameters(observableDf, sbmlModel)
%% getOutputParameters - Returns parameter ids used in observable and noise 
% formulas not defined in the SBML model.
%
% Syntax: out = getOutputParameters(parameterDf, sbmlModel);
%
% Inputs
%   observablDf - Table. PEtab observable table.
%   sbmlModel - SbmlExt. SBML model.
%
% Outputs
%    out - String. List of output parameter identifiers.
%
% Other m-files required: auxiliar/map.m, auciliar/flatten.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'observableDf', @istable);
    addRequired(p, 'sbmlModel', @SbmlExt.isSbmlExt);
    
    parse(p, observableDf, sbmlModel);
    observableDf = p.Results.observablDf;
    sbmlModel = p.Results.sbmlModel;
    % ...input parsed.
    
    obsFormula = string(observableDf.observableFormula);
    noiseFormulas = string(observableDf.noiseFormula);
    formulas = union(obsFormula, noiseFormulas);
    
    % Extract unique variables from formulas.
    variables = map(@symvar, formulas, 'UniformOutput', false);
    variables = unique(flatten(variables));
    
    % Unique variables from formulas not in SBML model. 
    out = setdiff(variables, sbmlModel.sIds.keys);
% ------------- END OF CODE --------------    
end

