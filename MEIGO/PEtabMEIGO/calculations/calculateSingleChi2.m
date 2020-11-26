function chi2 = calculateSingleChi2(measurement, simulation, noiseValue, scale)
%% calculateSingleChi2 - Calculates chi2 term for a single observation 
% according to:
%
%       $chi2 = \sum_{i = 1}^n \frac{s_i - m_i}{\sigma}$
%
%       $s_i$ - observable measured value for a specific timepoint.
%       $m_i$ - observable simulated value for a specific timepoint.
%       $\sigma$ - observable noise value.
%
% Syntax: calculateSingleChi2(measurement, simulation, noiseValue, scale);
%
% Inputs
%    measurement - Numeric. Single observable value.
%    simulation - Numeric. Single observable simulation.
%    noiseValue - Numeric. Noise value for observable.
%    scale - String type. Observable scale ('lin', 'log' or 'log10').
%
% Outputs
%    chi2 - Numeric. Chi2.
%
% Other m-files required: calculation/calculateSingleResidual.m, 
%                         auxiliar/isStringType.m
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
    addRequired(p, 'noiseValue', @isnumeric);
    addRequired(p, 'scale', @isStringType);
    
    parse(p, measurement, simulation, noiseValue, scale);
    measurement = p.Results.measurement;
    simulation = p.Results.simulation;  
    noiseValue = p.Results.noiseValue; 
    scale = p.Results.scale; 
    % ...input parsed 
    
    chi2 = (calculateSingleResidual(measurement, simulation, scale) / noiseValue)^2;
% ------------- END OF CODE --------------    
end