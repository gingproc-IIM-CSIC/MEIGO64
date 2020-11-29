function assertSingleConditionAndSbmlFile(problemConfig)
%% assertSingleConditionAndSbmlFile - Check that there is only a single 
% condition file and a single SBML file specified.
%
% Syntax: assertSingleConditionAndSbmlFile(problemConfig);
%
% Inputs
%    problemConfig - Structure. YAML schema containing PEtab problem 
%                    configuration.
%
% Raises
%    NotImplementedError - If multiple condition or SBML files specified.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    errorId = 'ASSERTSINGLECONDITIONANDSBMLFILE:WrongInputError';
    errorMsg = 'Input must be a structure';
    assert(isstruct(problemConfig), errorId, errorMsg);
    
    check = numel(problemConfig.sbml_files) == 1 && ...
            numel(problemConfig.condition_files) == 1;
    errorId = 'ASSERTSINGLECONDITIONANDSBMLFILE:NotImplementedError';
    errorMsg = "Support for multiple models or condition files is not yet " ...
               + "implemented";
    assert(check, errorId, errorMsg);
% ------------- END OF CODE --------------    
end