function conditionDf = getConditionDf(conditionFileName)
%% getConditionDf - Read the provided condition file into a table.
% Conditions are rows, parameters are columns.
%
% Syntax: out = getConditionDf(conditionFileName);
%
% Inputs
%	conditionFileName - String type or table. File name of PEtab condition 
%                         file or table.
%
% Outputs
%	conditionDf - Table. Condition table.
%
% Example
%	conditionDf = getConditionDf('pathToFile');
%	conditionDf = getConditionDf(conditionTable);
%
% Other m-files required: lint/assertNoLeadingTrailingWhitespace.m,
%                          auxiliar/isStringType
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    check = isStringType(conditionFileName) || istable(conditionFileName);
    errorId = 'GETCONDITIONDF:WrongInputError';
    errorMsg = 'Input must be a string type or a table';
    assert(check, errorId, errorMsg);
    
    if istable(conditionFileName)
        conditionDf = conditionFileName;
    else    
        check = isfile(conditionFileName);
        errorId = 'GETCONDITIONDF:FileNotFoundError';
        errorMsg = 'No such file or directory';
        assert(check, errorId, errorMsg);
    
        conditionDf = readtable(conditionFileName, 'FileType', 'text', ...
            'ReadVariableNames', true, 'PreserveVariableNames', true, ...
            'Delimiter', 'tab');
                        
        columns = conditionDf.Properties.VariableNames;
        check = ismember('conditionId', columns);
        errorId = 'GETCONDITIONDF:MandatoryFieldNotInTableError';
        errorMsg = 'Condition table missing mandatory field conditionId';        
        assert(check, errorId, errorMsg);
    
        assertNoLeadingTrailingWhitespace(columns, 'condition');
    end
% ------------- END OF CODE --------------    
end