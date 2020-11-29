function out = getOptimizationParameterScales(parameterDf)
%% getOptimizationParameterScales - Get optimization parameters as a (parameter 
% id - parameter scale) dictionary.
%
% Syntax: out = getOptimizationParameterScales(parameterDf);
%
% Inputs
%   parameterDf - Table. PEtab parameters table.
%
% Outputs
%    out - Dict. Optimization parameters dictionary.
%
% Other m-files required: parameters/getOptimizationParameters.m,
%                         auxiliar/Dict.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    check = istable(parameterDf);
    errorId = 'WrongInputError';
    errorMsg = 'Input must be a table';
    assert(check, errorId, errorMsg);
    
    parameterScales = parameterDf.parameterScale(parameterDf.estimate == 1);    
    out = Dict(getOptimizationParameters(parameterDf), parameterScales);
% ------------- END OF CODE --------------  
end

