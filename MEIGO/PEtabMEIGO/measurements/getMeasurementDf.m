function measurementDf = getMeasurementDf(measurementFileName) %-> [table]
%% getMeasurementDf - Read the provided measurements file into a table.
%
% Syntax: out = getMeasurementDf(measurementFileName);
%
% Inputs
%	measurementFileName - String type. File name of PEtab measurement file or 
%                         table.
%
% Outputs
%	measurementDf - Table. Measurements table.
%
% Example
%	conditionDf = getMeasurementDf('pathToFile');
%	conditionDf = getMeasurementDf(measurementTable);
%
% Other m-files required: lint/assertNoLeadingTrailingWhitespace.m, 
%                         auxiliar/isemptyExt.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    check = isStringType(measurementFileName) || istable(measurementFileName);
    errorId = 'GETMEASUREMENTDF:WrongInputError';
    errorMsg = 'Input must be a string type or a table';
    assert(check, errorId, errorMsg);
    
    if istable(measurementFileName)
        measurementDf = measurementFileName;
    else      
        check = isfile(measurementFileName);
        errorId = 'GETMEASUREMENTDF:FileNotFoundError';
        errorMsg = 'No such file or directory';
        assert(check, errorId, errorMsg);
        
        measurementDf = readtable(measurementFileName, 'FileType', 'text', ...
            'ReadVariableNames', true, 'PreserveVariableNames', true, ...
            'Delimiter', 'tab');
        
        mandatoryColumns = ["observableId", "simulationConditionId", ...
                            "measurement", "time"];
        columns = measurementDf.Properties.VariableNames;
        missingColumns = setdiff(mandatoryColumns, columns);
        
        check = isemptyExt(missingColumns);
        errorId = 'GETMEASUREMENTDF:MandatoryFieldNotInTableError';
        errorMsg = 'Measurements table missing at least one mandatory field';
        assert(check, errorId, errorMsg);
        
        assertNoLeadingTrailingWhitespace(columns, 'measurement');
    end
% ------------- END OF CODE --------------      
end
