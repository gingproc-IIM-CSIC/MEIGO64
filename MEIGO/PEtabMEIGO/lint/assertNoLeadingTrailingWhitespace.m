function assertNoLeadingTrailingWhitespace(nName, nameId)
%% assertNoLeadingTrailingWhitespace - Check for trailing whitespaces in string 
% type object.
%
% Syntax: assertNoLeadingTrailingWhitespace(nName, name);
%
% Inputs
%   nName - String type. List of names to check for whitespace.
%   nameId - String type. Name of nName argument, for error message.
%
% Raises
%    TrailingWhitespaceError - If there is trailing whitespace around any 
%                              element of nName argument.
%
% Other m-files required: auxiliar/map.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------

    % Parse input...
    p = inputParser;

    addRequired(p, 'nName', @(x) isStringType(x) || iscell(x));
    addRequired(p, 'nameId', @isStringType);

    parse(p, nName, nameId);
    nName = string(p.Results.nName);
    nameId = p.Results.nameId;
    % ...input parsed.
    
    for i = 1:numel(nName)
        iName = nName(i);        
        check = numel(i) == numel(strtrim(iName));
        errorId = 'ASSERTNOLEADINGTRAILINGWHITESPACE:TrailingWhitespaceError';
        errorMsg = 'Trailing whitespaces in %s nName(i): %s';
        assert(check, errorId, errorMsg, nameId, i, iName)
    end
% ------------- END OF CODE --------------    
end