function out = isemptyExt(input)
%% isemptyExt - Check if input argument is empty.
% Extends built-in isempty function to account for string "" as an empty object.
%
% Syntax: out = isemptyExt(input);
%
% Inputs
%	input - Any type. Object to check.
%
% Outputs
%	out - Logical. True if input argument is empty, else false.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: isempty (built-in)

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 11-April-2020
%% ------------- BEGIN CODE --------------
    out = isempty(input) || isequal(input, "");
% ------------- END OF CODE --------------  
end