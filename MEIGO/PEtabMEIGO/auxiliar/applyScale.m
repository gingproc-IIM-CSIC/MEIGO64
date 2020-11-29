function out = applyScale(input, scaleStr)
%% applyScale - Apply log or log10 scale.
% Applies scale as given in scaleStr (which can be '', 'lin', 'log' or 
% 'log10') to input argument.
%
% Syntax: out = applyScale(input, scaleStr);
%
% Inputs
%	input - Numeric. Value to be scaled.
%	scaleStr - String type. One of 'lin' (synonymous with ''), 'log' or 
%               'log10'.
%
% Outputs
%	out - Numeric. Scaled input argument.
%
% Example
%	out = applyScale(2.5, ''); -> 2.5
%	out = applyScale(100, 'log10'); -> 2
%
% Other m-files required: auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 16-May-2020
%% ------------- BEGIN CODE --------------
    % Parse input...
    p = inputParser;
    
    addRequired(p, 'input', @isnumeric);
    addRequired(p, 'scaleStr', @isStringType);    
    
    parse(p, input, scaleStr);
    input = p.Results.input;
    scaleStr = p.Results.scaleStr;
    % ...input parsed.
    
    if ismember(scaleStr, ["" "lin"])
        out = input;
    elseif strcmp(scaleStr, 'log')
        out = log(input);
    elseif strcmp(scaleStr, 'log10')
        out = log10(input);
    else
        errorId = 'APPLYSCALE:WrongScaleError';
        errorMsg = "Scale must be 'lin' (or ''), log or log10";
        error(errorId, errorMsg);
    end
% ------------- END OF CODE --------------    
end