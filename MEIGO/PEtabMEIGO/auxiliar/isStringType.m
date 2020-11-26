function out = isStringType(input)
%% isStringType - Check if input is a string type.
% If input argument is a string, a string array, a char or a char array, returns
% true, else false.
%
% Syntax: bool = isStringType(input);
%
% Inputs
%	input - Any type object.
%
% Outputs
%   out - Logical. True if input is a string type, else false.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------
    out = ischar(input) || isstring(input);
% ------------- END OF CODE --------------    
end