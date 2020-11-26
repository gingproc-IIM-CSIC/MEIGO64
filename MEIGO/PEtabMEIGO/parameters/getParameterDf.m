function parameterDf = getParameterDf(parameterFileName)
%% getParameterDf - Read the provided parameters file into a table.
%
% Syntax:   out = getParameterDf(parameterFileName)
%
% Inputs:
%   observableFileName - String array or char containing file name of PEtab 
%                        observables file.
%
% Outputs:
%    parameterDf - Parameters table.
%
% Example:
%    parameterDf = getParameterDf('pathToFile');
%    parameterDf = getParameterDf(parameterTable);
%
% Other m-files required: lint/assertNoLeadingTrailingWhitespace.m, 
%                         auxiliar/isemptyExt.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 11-April-2020
%% ------------- BEGIN CODE --------------
    check = isStringType(parameterFileName) || istable(parameterFileName);
    errorId = 'GETPARAMETERDF:WrongInputError';
    errorMsg = 'Input must be a string type or a table';
    assert(check, errorId, errorMsg);
    
    if istable(parameterFileName)
        parameterDf = measurementFileName;
    else      
        check = isfile(parameterFileName);
        errorId = 'GETPARAMETERDF:FileNotFoundError';
        errorMsg = 'No such file or directory';
        assert(check, errorId, errorMsg);
        
        parameterDf = readtable(parameterFileName, 'FileType', 'text', ...
            'ReadVariableNames', true, 'PreserveVariableNames', true, ...
            'Delimiter', 'tab');
        
        mandatoryColumns = ["parameterId", "parameterScale", "lowerBound", ...
                            "upperBound", "nominalValue", "estimate"];
        columns = parameterDf.Properties.VariableNames;
        missingColumns = setdiff(mandatoryColumns, columns);
        
        check = isemptyExt(missingColumns);
        errorId = 'GETPARAMETERDF:MandatoryFieldNotInTableError';
        errorMsg = 'Parameters table missing at least one mandatory field';
        assert(check, errorId, errorMsg);
        
        assertNoLeadingTrailingWhitespace(columns, 'parameter');
    end
% ------------- END OF CODE --------------  
end