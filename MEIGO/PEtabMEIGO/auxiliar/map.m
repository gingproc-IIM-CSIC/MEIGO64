function varargout = map(varargin)
%% map - Wrapper function to built-ins 'arrayfun' and 'cellfun'.
%
% Syntax: out = map(varargin)
%
% Inputs
%	varargin - Same arguments as in built-in arrayfun and cellfun. 
%
% Outputs
%	out - Cell, string or numeric.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% See also: arrayfun, cellfun (built-in)

% Author: Tacio Camba Espí
% email: info@taciocamba
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------
    if iscell(varargin{2})
        [varargout{1:nargout}] = cellfun(varargin{:});
    else
        [varargout{1:nargout}] = arrayfun(varargin{:});
    end
% ------------- END OF CODE -------------- 
end