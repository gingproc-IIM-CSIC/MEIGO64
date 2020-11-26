function res = calculateSingleResidual(measurement, simulation, varargin)
%% calculateSingleResidual - Calculates residual for a single observation 
% according to:
%
%       $res = s_i - m_i$
%
%       $s_i$ - observable measured value for a specific timepoint.
%       $m_i$ - observable simulated value for a specific timepoint.
%
% If a scale argument is provided, residual is transformed accordingly.
%
% Syntax: calculateSingleResidual(measurement, simulation);
%
% Inputs
%    measurement - Numeric. Single observable value.
%    simulation - Numeric. Single observable simulation.
%    scale - String type. Observable scale.
%
% Outputs
%    res - Numeric. Residual.
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    
    % Parse input...
    p = inputParser;
    
    addRequired(p, 'measurement', @isnumeric);
    addRequired(p, 'simulation', @isnumeric);
    addOptional(p, 'scale', 'lin', @isStringType);    
    
    parse(p, measurement, simulation, varargin{:});
    measurement = p.Results.measurement;
    simulation = p.Results.simulation;
    scale = p.Results.scale;
    % ...input parsed 
    
    res = applyScale(simulation, scale) - applyScale(measurement, scale);
% ------------- END OF CODE --------------    
end