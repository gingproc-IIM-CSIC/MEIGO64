function out = toNumericIfNumeric(input)
%% toNumericIfNumeric - Convert input argument to numeric if it is a valid 
% representation of a number.
%
% Syntax: out = toNumericIfNumeric(input);
%
% Inputs
%	input - Any type. Object to convert to float.
%
% Outputs
%	out - Numeric. Numeric representation of input argument.
%
% Example
%	out = toNumericIfNumeric('1.5'); -> 1.5
%   out = toNumericIfNumeric(12); -> 12
%   out = toNumericIfNumeric("input"); -> "input"
%
% Other m-files required: auxiliar/isemptyExt.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 18-May-2020
%% ------------- BEGIN CODE --------------    
    if isnumeric(input)
        out = input;
    else
        out = str2num(input);        
        if isemptyExt(out), out = input; end
    end
% ------------- END OF CODE --------------
end