function out = getOptimizationParameters(parameterDf)
%% getOptimizationParameters - Get optimization parameter identifiers from 
% parameters table.
%
% Syntax: out = getOptimizationParameters(parameterDf);
%
% Inputs
%   parameterDf - Table. PEtab parameters table.
%
% Outputs
%    out - String. Optimization parameter identifiers.
%
% Other m-files required: none
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

    parIds = string(parameterDf.parameterId(parameterDf.estimate == 1));
    out = transpose(parIds);
% ------------- END OF CODE --------------      
end
