function out = measurementTableHasTimepointSpecificMappings(measurementDf)
%% measurementTableHasTimepointSpecificMappings - Checks for time-point or 
% replicate specific assignments in the measurement table.
%
% Syntax - measurementTableHasTimepointSpecificMappings(measurementDf)
%
% Inputs:
%    measurementDf - PEtab measurements table.
%
% Outputs:
%    out -  'true' if df has timepoint specific mappings, else 'false'.
%
% Other m-files required: auxiliar/tableSubset.
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@gmail.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 11-April-2020
%% ------------- BEGIN CODE --------------
    arguments
        measurementDf table;
    end    
    
    out = false;
    
    isObsPars = true;
    % If measurements table has not 'observableParameters' column names needed 
    % for checking are only 'observableId' and 'time'.
    measDfColumns = ["observableId" "time" "observableParameters"];
    if ~ismember('observableParameters', ...
                 measurementDf.Properties.VariableNames)
             isObsPars = false;
             measDfColumns = measDfColumns(1:2);
    end
    
    simCondDf = getSimulationConditions(measurementDf);   
    n = height(simCondDf);    
    
    simCondDf.Count = [];
    simCondColumns = simCondDf.Properties.VariableNames;
    % Measurement table subset by simulation condition.
    for i = 1:n
        iMeasDf = tableSubset(measurementDf, simCondColumns, simCondDf{i, :});
        iMeasDf = iMeasDf(:, measDfColumns);
        % Measurement table subset by simulation condition AND observable Id.
        for j = 1:numel(iMeasDf.observableId)
            jObsId = iMeasDf.observableId{j};
            jMeasDf = tableSubset(iMeasDf, 'observableId', jObsId);
            
            uniqTimes = unique(jMeasDf.time);
            if isObsPars
                % If measurements table has 'observableParameters', check for
                % timepoints specific observable mapping and replicated 
                % measurements...
                uniqObsPars = unique(jMeasDf.observableParameters);                
                
                test = (numel(uniqTimes) < numel(jMeasDf.time)) || ...
                       (numel(uniqObsPars) > 1);                   
                if test, out = true; end
            else
                %...else, check only for replicated measurements.
                test = numel(uniqTimes) < numel(jMeasDf.time);
                if test, out = true; end
            end
        end
    end   
% ------------- END OF CODE --------------    
end