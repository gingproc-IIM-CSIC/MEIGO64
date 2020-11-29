function llh = calculateSingleLlh(measurement, simulation, scale, ...
                                  noiseDistribution, noiseValue)
%% calculateSingleLlh - Calculates log-likelihood term for a single 
% observation.
%
% Syntax: calculateSingleLlh(measurement, simulation, scale, ...
%                            noiseDistribution, noiseValue);
%
% Inputs
%    measurement - Numeric. Single observable value.
%    simulation - Numeric. Single observable simulation.
%    scale - String or char. Observable scale ('lin', 'log' or 'log10').
%    noiseDistribution - String type. Noise distribution ('normal' or 
%                        'laplace').
%    noiseValue - Numeric. Observable's noise value.
%
% Outputs
%    llh - Numeric. Log-likelihood calculated for a single measurement.
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
    addRequired(p, 'scale', @isStringType);
    addRequired(p, 'noiseDistribution', @isStringType);
    addRequired(p, 'noiseValue', @isnumeric);
    
    parse(p, measurement, simulation, scale, noiseDistribution, noiseValue);
    measurement = p.Results.measurement;
    simulation = p.Results.simulation;
    scale = p.Results.scale;
    noiseDistribution = p.Results.noiseDistribution;
    noiseValue = p.Results.noiseValue;
    % ...input parsed 
    
    if strcmp(noiseDistribution, 'normal') && strcmp(scale, 'lin')
        llh = 0.5*log(2*pi*noiseValue^2) + 0.5*(calculateSingleResidual(simulation, measurement, scale) / noiseValue)^2;
    elseif strcmp(noiseDistribution, 'normal') && strcmp(scale, 'log')
        llh = 0.5*log(2*pi*noiseValue^2*measurement^2) + ...
            0.5*(calculateSingleResidual(simulation, measurement, scale) / noiseValue)^2;
    elseif strcmp(noiseDistribution, 'normal') && strcmp(scale, 'log10')
        llh = 0.5*log(2*pi*noiseValue^2*measurement^2*log(10)^2) + ...
            0.5*(calculateSingleResidual(simulation, measurement, scale) / noiseValue)^2;
    elseif strcmp(noiseDistribution, 'laplace') && strcmp(scale, 'lin')
        llh = log(2*noiseValue) + ...
            abs(calculateSingleResidual(simulation, measurement, scale) / noiseValue);
    elseif strcmp(noiseDistribution, 'laplace') && strcmp(scale, 'log')
        llh = log(2*noiseValue*measurement) + ...
            abs(calculateSingleResidual(simulation, measurement, scale) / noiseValue);
    elseif strcmp(noiseDistribution, 'laplace') && strcmp(scale, 'log10')
        llh = log(2*noiseValue*measurement*log(10)) + ...
            abs(calculateSingleResidual(simulation, measurement, scale)/ noiseValue);
    else
        errorId('CALCULATESINGLELLH:WrongScaleOrNoiseDistrError');
        errorMsg = "Scale must be 'lin', 'log' or 'log10' and noise " + "distribution 'normal' or 'laplace'";
        error(errorId, errorMsg);
    end
    
    llh = - llh;
% ------------- END OF CODE --------------      
end