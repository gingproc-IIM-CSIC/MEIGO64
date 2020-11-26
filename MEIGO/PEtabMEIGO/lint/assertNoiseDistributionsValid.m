function assertNoiseDistributionsValid(observablesDf)
%% assertNoiseDistributionsValid - Ensure that noise distributions and 
% transformations for observables are valid.
%
% Syntax: assertNoiseDistributionsValid(observablesDF);
%
% Inputs
%    observablesDf - Table. PEtab observables table.
%
% Raises
%     ObsTrafoInvalidError - If observable transformation is invalid.
%       OR
%     NoiseDistrInvalidError - If noise distribution is invalid.
%
% Other m-files required: auxiliar/map.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------
    errorId = 'ASSERTNOISEDISTRIBUTIONSVALID:WrongInputError';
    errorMsg = 'Input must be a table';
    assert(istable(observablesDf), errorId, errorMsg);
    
    OBS_TRAFOS = ["", "lin", "log", "log10"];
    NOISE_DISTR = ["", "normal", "laplace"];  
    
    columns = observable.Properties.VariableNames;    
    if ismember('observableTransformation', columns)
        obsTrafo = observablesDf.observableTransformation;
        checkFunc = @(x) isStringType(x) && ismember(x, OBS_TRAFOS);        
        check = all(map(checkFunc, obsTrafo));
        errorId = 'ASSERTNOISEDISTRIBUTIONSVALID:ObsTrafoInvalidError';
        errorMsg = 'Invalid observable transformation in observables table';
        assert(check, errorId, errorMsg);
    end
    
    if ismember('noiseDistribution', columns)
        noiseDistr = observablesDf.noiseDistribution;
        checkFunc = @(x) isStringType(x) && ismember(x, NOISE_DISTR);        
        check = all(map(checkFunc, noiseDistr));
        errorId = 'ASSERTNOISEDISTRIBUTIONSVALID:NoiseDistrInvalidError';
        errorMsg = 'Invalid noise distribution in observables table';
        assert(check, errorId, errorMsg);
    end
% ------------- END OF CODE --------------
end