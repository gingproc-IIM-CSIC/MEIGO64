function out = isNear(a, b, varargin)
%% isNear - Check if two numbers are nearly equal.
% If the difference between two numbers is within a specific tolerance, returns
% true, else false.
%
% Syntax: out = isNear(a, b, tol);
%
% Inputs
%	a - Numeric. A number.
%	b - Numeric. A number.
%	tol - Optional. Numeric. Tolerance. Defaults to 
%          sqrt(eps(max(abs(a),abs(b)))).
%
% Outputs
%	out - Logical. True if the inputs are nearly equal, else false.
%
% Other m-files required: auxiliar/isemptyExt.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'a', @isnumeric);
    addRequired(p, 'b', @isnumeric);
    addOptional(p, 'tol', [], @isnumeric);
    
    parse(p, a, b, varargin{:});
    a = p.Results.a;
    b = p.Results.b;
    tol = p.Results.tol;    
    % ...input parsed
    
    if isemptyExt(tol), tol = sqrt(eps(max(abs(a),abs(b)))); end
    
    check = all(size(a) == size(b));
    errorId = 'ISNEAR:InputSizesError';
    errorMsg = 'A and B must be the same size';
    assert(check, errorId, errorMsg);  
      
    out = abs(a - b) <= abs(tol);
% ------------- END OF CODE --------------     
end