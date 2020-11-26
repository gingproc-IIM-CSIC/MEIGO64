function observableDf = getObservableDf(observableFileName)
%% getObservableDf - Read the provided observables file into a table.
%
% Syntax: out = getObservableDf(observableFileName);
%
% Inputs
%   observableFileName - String type. File name of PEtab observables file or 
%                        table.
%
% Outputs
%    observableDf - table. Observable table.
%
% Example
%    observableDf = getObservableDf('pathToFile');
%    observableDf = getObservableDf(observableTable);
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
    check = isStringType(observableFileName) || istable(observableFileName);
    errorId = 'GETOBSERVABLEDF:WrongInputError';
    errorMsg = 'Input must be a string type or a table';
    assert(check, errorId, errorMsg);
    
    if istable(observableFileName)
        observableDf = observableFileName;
    else      
        check = isfile(observableFileName);
        errorId = 'GETOBSERVABLEDF:FileNotFoundError';
        errorMsg = 'No such file or directory';
        assert(check, errorId, errorMsg);
        
        observableDf = readtable(observableFileName, 'FileType', 'text', ...
            'ReadVariableNames', true, 'PreserveVariableNames', true, ...
            'Delimiter', 'tab');
        
        mandatoryColumns = ["observableId" "observableFormula" "noiseFormula"];
        columns = observableDf.Properties.VariableNames;
        missingColumns = setdiff(mandatoryColumns, columns);
        
        check = isemptyExt(missingColumns);
        errorId = 'GETOBSERVABLEDF:MandatoryFieldNotInTableError';
        errorMsg = 'Observables table missing at least one mandatory field';
        assert(check, errorId, errorMsg);
        
        assertNoLeadingTrailingWhitespace(columns, 'observable')
    end
% ------------- END OF CODE --------------         
end