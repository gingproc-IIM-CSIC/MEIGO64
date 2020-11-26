classdef Petab < matlab.mixin.Copyable
%% Petab - PEtab parameter estimation problem as defined by:
%
% - SBML model.
% - conditions table.
% - measurements table.
% - parameters table.
% - observables table.
%
% Optionally it may contain visualization tables.
%
% Properties
%	sbmlModel - SbmlExt. SBML model.
%	conditionDf - Table. PEtab conditions table.
%	measurementDf - Table. PEtab measurements table.
%   parameterDf - Table. PEtab parameters table.
%	observableDf - Table. PEtab observables table.
%
%   parsedMeasurementTable - Table. Parsed measurement table as returned by getParsedMeasurementTable.
%
% Object Methods
%	Petab - Constructor for class Petab.
%   getModelSpeciesIds - Get string array of model species.
%   getOptimizationParameters - Get string array of optimization parameter identifiers from parameters table.
%   getOptimizationParametersScales - Get dictionary with optimization parameter identifiers mapped to parameter scaling
%                                     strings.
%   getModelParameters - Returns parameters in SBML model not in parameters table.
%   getModelParametersNominalValues - Returns model parameters nominal values.
%   getObservableIds - Observable identifiers.
%   xIds - Parameters indentifiers.
%   xFreeIds - Parameter identifiers, for free parameters.
%   xFixedIds - Parameter identifiers, for fixed parameters.
%   xNominal - Parameters nominal values.
%   xNominalFree - Free parameters nominal values.
%   xNominalFixed - Fixed parameters nominal values.
%   xNominalScaled - Parameters nominal values with applied scale.
%   xNominalFreeScaled - Free parameters nominal values with applied scale.
%   xNominalFixedScaled - Fixed parameters nominal values with applied scale.
%   lb - Parameters lower bounds.
%   lbFree - Free parameters lower bounds.
%   lbFixed - Fixed parameters lower bounds.
%   lbScaled - Parameters lower bounds scaled.
%   ub - Parameters upper bounds.
%   ubFree - Free parameters upper bounds.
%   ubFixed - Fixed parameters upper bounds.
%   ubScaled - Parameters upper bounds scaled.
%   getSimulationConditionsFromMeasurementDf - Create a table of separate simulation conditions from measurements table.
%   objectiveFunction - Calculates problem nllh for given optimization parameters vector. 
%   isPreeq - Test if Petab problem has preequilibration.
%   getParsedMeasurementTable - Returns measurement table including parsed observables and noise formulas and scales.
%   saveParsedMeasurementTableToTsv - Writes parsed measurement table to given path as TSV file.
%   loadParsedMeasurementTable - Loads parsed measurement table from given path.
%   createProblemFiles - Creates ODEs and simulation functions for model experimental conditions.
%   getSimulationsTable - Returns parsed measurement table including simulations for given free parameters array.
%   getConditionsDictionary - Returns condition table as a (element id : value/expression) dictionary.
%   getModelForCondition - Returns model parsed for specific condition.
%   removeTempFiles - Removes petab problem from PetabTemp and from path.
%
% Static Methods
%   fromFiles - Load model and tables from files.
%   fromYaml - Load model and tables as specified by YAML file.
%   isPetab - Test if input is a Petab object.
%   writeODEsForCondition - Write model ODEs function to a file named ODEsFunc_{conditionId} in Petab temporary folder.
%   writeSimFuncForCondition - Write model simulation function to a file named simFunc_{conditionId} in Petab temporary 
%                              folder.
%   cleanTempFiles - Removes PetabTemp folder and all its contents.
%
% Other m-files required: auxiliar/isemptyExt.m, auxiliar/map.m,
%                         auxiliar/SbmlExt.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 22-Aug-2020
%% ------------- BEGIN CODE --------------

% PROPERTIES
    properties (SetAccess = private)
        problemPath string = string.empty;
        rrModel RoadRunner = RoadRunner.empty;
        modelsDict Dict = Dict.empty;
        observableFormulaDict = Dict.empty;
        noiseFormulaDict = Dict.empty;
    end
    
    properties
        sbmlModel SbmlExt = SbmlExt.empty;
        conditionDf table = table.empty;
        measurementDf table = table.empty;
        parameterDf table = table.empty;
        observableDf table = table.empty;        
        
        parsedMeasurementTable table = table.empty;
    end
    
    methods
% CLASS CONSTRUCTOR
        function obj = Petab(varargin)
        % Class constructor.
        
            % Parse input...
            p = inputParser;

            addOptional(p, 'problemPath', string.empty, @isStringType);
            addOptional(p, 'sbmlModel', SbmlExt.empty, @SbmlExt.isSbmlExt);                    
            addOptional(p, 'conditionDf', table.empty, @istable);
            addOptional(p, 'measurementDf', table.empty, @istable);
            addOptional(p, 'parameterDf', table.empty, @istable);
            addOptional(p, 'observableDf', table.empty, @istable);
            addOptional(p, 'parsedMeasurementDfPath', string.empty, @isStringType)

            parse(p, varargin{:});
            problemPath = p.Results.problemPath;
            sbmlModel = p.Results.sbmlModel;
            conditionDf = p.Results.conditionDf;
            measurementDf = p.Results.measurementDf;
            parameterDf = p.Results.parameterDf;
            observableDf = p.Results.observableDf;
            parsedMeasurementDfPath = p.Results.parsedMeasurementDfPath;
            
            % ...input parsed.                       
            
            obj.problemPath = problemPath;            
            obj.sbmlModel = sbmlModel;
            obj.conditionDf = conditionDf;
            obj.measurementDf = measurementDf;
            obj.parameterDf = parameterDf;
            obj.observableDf = observableDf;
            
            % Dump parameter table nominal values into sbml model.
            tableParIds = obj.xIds;
            tableParVals = obj.xNominal;
            for i = 1:numel(tableParIds)
                sId = tableParIds(i);
                value = tableParVals(i);                
                if ismember(sId, obj.sbmlModel.parameter.keys)
                    obj.sbmlModel.setElementBySId(sId, value);
                end
            end
            
            obj.sbmlModel.applyInitialAssignments;
            obj.sbmlModel.applyAssignmentRules;              
            obj.sbmlModel.updateCurrentSbmlModel;
            
            [~, modelName] = fileparts(obj.problemPath);
            defaultPath = fullfile('.', 'PetabTemp', modelName, "parsed_measurement_table_" + modelName + ".tsv");
            if isemptyExt(parsedMeasurementDfPath)
                if exist(defaultPath, 'file')
                    obj.loadParsedMeasurementTable;
                else
                    obj.modelsDict = obj.getModelsDictionary;            
                    obj.parsedMeasurementTable = obj.getParsedMeasurementTable;           
                    obj.saveParsedMeasurementTableToTsv;
                end
            else
                obj.loadParsedMeasurementTable(parsedMeasurementDfPath);
            end
            
            obj.createProblemFiles;
            obsFormulas = unique(transpose(obj.parsedMeasurementTable.observableFormula));
            obj.observableFormulaDict = obj.getFormulaFunctionDict(obsFormulas);
            noiseFormulas = unique(transpose(obj.parsedMeasurementTable.noiseFormula));
            obj.noiseFormulaDict= obj.getFormulaFunctionDict(noiseFormulas);            
        end
        
% OBJECT METHODS
        function out = getModelSpecies(obj)
        %% getModelSpecies - Get model species ids.
        %
        % See also: auxiliar/SbmlExt.getSpecies
        
            out = obj.sbmlModel.getSpecies;
        end

        function out = getOptimizationParameters(obj)
        %% getOptimizationParameters - Get optimization parameters ids.
        %
        % See also: parameters/getOptimizationParameters            
            out = getOptimizationParameters(obj.parameterDf);
        end
        
        function out = getOptimizationParametersScales(obj)
        %% getOptimizationParameterScales - Get optimization parameters as a 
        % (parameter id : parameter scale) dictionary.
        %
        % See also: parameters/getOptimizationParameterScales            
            out = getOptimizationParameterScales(obj.parameterDf);
        end
        
        function out = getModelParameters(obj)
        %% getModelParameters - Returns parameters in SBML model not in 
        % parameters table.
        %
        % Syntax: out = obj.getModelParameters;
        %
        % Outputs
        %   out - String. SBML model parameters not in parameters table.            
            out = setdiff(obj.sbmlModel.parameter.keys, obj.xIds);
        end
        
        function out = getModelParametersNominalValues(obj)
        %% getModelParametersNominalValues - Returns model parameters nominal 
        % values.
        %
        % Syntax: out = obj.getModelParametersNominalValues;
        %
        % Outputs
        %   out - Numeric. Nominal values.            
            modelPars = obj.getModelParameters;            
            out = zeros(1, numel(modelPars));
            for i = 1:numel(modelPars)
                parId = modelPars(i);
                parStruct = obj.sbmlModel.parameter(parId);
                out(i) = parStruct.value;
            end            
        end        
        
        function out = getObservableIds(obj)
        %% getObservableIds - Returns observable ids.
        %
        % Syntax: obj.getObservableIds;
        %
        % Outputs
        %   out - String. Observable identifiers.            
            out = string(obj.observableDf.observableId);
            out = transpose(out);
        end
        
        function out = xIds(obj)
        %% xIds - Returns parameter ids.
        %
        % Syntax: obj.xIds;
        %
        % Outputs
        %   out - String. Parameter identifiers.         
            out = obj.getXIds;
        end
        
        function out = xFreeIds(obj)
        %% xFreeIds - Returns parameter ids for free parameters.
        %
        % Syntax: obj.xFreeIds;
        %
        % Outputs
        %   out - String. Free parameter identifiers.            
            out = obj.getXIds(true, false);
        end
        
        function out = xFixedIds(obj)
        %% xFixedIds - Returns parameter ids for fixed parameters.
        %
        % Syntax: obj.xFixedIds;
        %
        % Outputs
        %   out - String. Fixed parameter identifiers.            
            out = obj.getXIds(false, true);
        end
        
        function out = xNominal(obj)
        %% xNominal - Returns parameter nominal values.
        %
        % Syntax: obj.xNominal;
        %
        % Outputs
        %   out - Numeric. Nominal values of parameters.            
            out = obj.getXNominal;
        end
        
        function out = xNominalFree(obj)
        %% xNominalFree - Returns free parameter nominal values.
        %
        % Syntax: obj.xNominalFree;
        %
        % Outputs
        %   out - Numeric. Nominal values of free parameters.            
            out = obj.getXNominal(true, false);
        end
        
        function out = xNominalFixed(obj)
        %% xNominalFixed - Returns fixed parameter nominal values.
        %
        % Syntax: obj.xNominalFixed;
        %
        % Outputs
        %   out - Numeric. Nominal values of fixed parameters.            
            out = obj.getXNominal(false, true);
        end
        
        function out = xNominalScaled(obj)
        %% xNominalScaled - Returns scaled parameter nominal values.
        %
        % Syntax: obj.xNominalScaled;
        %
        % Outputs
        %   out - Numeric. Scaled nominal values of parameters.             
            out = obj.getXNominal(true, true, true);
        end
        
        function out = xNominalFreeScaled(obj)
        %% xNominalFreeScaled - Returns free scaled parameter nominal values.
        %
        % Syntax: obj.xNominalFreeScaled;
        %
        % Outputs
        %   out - Numeric. Scaled nominal values of free parameters.
            out = obj.getXNominal(true, false, true);
        end
        
        function out = xNominalFixedScaled(obj)
        %% xNominalFixedScaled - Returns fixed scaled parameter nominal values.
        %
        % Syntax: obj.xNominalFixedScaled;
        %
        % Outputs
        %	out - Numeric. Scaled nominal values of fixed parameters.
            out = obj.getXNominal(false, true, true);
        end
        
        function out = lb(obj)
        %% lb - Returns parameter lower bounds.
        %
        % Syntax: obj.lb;
        %
        % Outputs
        %    out - Numeric. Parameter lower bounds.
            out = obj.getLb;
        end
        
        function out = lbFree(obj)
        %% lbFree - Returns free parameter lower bounds.
        %
        % Syntax: obj.lbFree;
        %
        % Outputs
        %    out - Numeric. Free parameter lower bounds.
            out = obj.getLb(true, false);
        end
        
        function out = lbFixed(obj)
        %% lbFixed - Returns fixed parameter lower bounds.
        %
        % Syntax: obj.lbFixed;
        %
        % Outputs
        %    out - Numeric. Fixed parameter lower bounds.
            out = obj.getLb(false, true);
        end           
        
        function out = lbScaled(obj)
        %% lbScaled - Returns scaled parameter lower bounds.
        %
        % Syntax: obj.lbScaled;
        %
        % Outputs
        %    out - Numeric. Scaled parameter lower bounds.
            out = obj.getLb(true, true, true);
        end
        
        function out = ub(obj)
        %% ub - Returns parameter upper bounds.
        %
        % Syntax: obj.ub;
        %
        % Outputs
        %    out - Numeric. Parameter upper bounds.
            out = obj.getUb;
        end
        
        function out = ubFree(obj)
        %% ubFree - Returns free parameter upper bounds.
        %
        % Syntax: obj.ubFree;
        %
        % Outputs
        %    out - Numeric. Free parameter upper bounds.
            out = obj.getUb(true, false);
        end
        
        function out = ubFixed(obj)
        %% ubFixed - Fixed parameters upper bounds.
        %
        % Syntax: obj.ubFixed;
        %
        % Outputs
        %    out - Numeric. Fixed parameter upper bounds.            
            out = obj.getUb(false, true);
        end         
        
        function out = ubScaled(obj)
        %% ubScaled - Scaled parameters upper bounds.
        %
        % Syntax: obj.ubScaled;
        %
        % Outputs
        %    out - Numeric. Scaled parameter upper bounds.  
            out = obj.getUb(true, true, true);
        end
        
        function out = getSimulationConditionsFromMeasurementDf(obj)
        %% getSimulationConditionsFromMeasurementDf - Create a table of 
        % separate simulation conditions from measurement table.
        %
        % See measurements/getSimulationConditions            
            out = getSimulationConditions(obj.measurementDf);
        end
        
        function out = isPreeq(obj)
        %% isPreeq - Check if Petab problem has preequilibration.
        %
        % Syntax: obj.isPreeq;
        %
        % Outputs
        %   out - Logical. True if Petab problem has preequilibration, else 
        %         false.
        %
        % See auxiliar/isPreeq
            out = isPreeq(obj.measurementDf);
        end
        
        function out = getModelsDictionary(obj)
        %% getModelsDictionary - Returns a dictionary with model conditions as keys and SbmlExt object for each
        % condition as values.
        %
        % Syntax: obj.getModelsDictionary
        %
        % Outputs
        %   out - Dict. ConditionId/SbmlExt model dictionary.
        
            condDf = obj.getSimulationConditionsFromMeasurementDf;
            if obj.isPreeq
                condIds = horzcat(string(transpose(condDf.preequilibrationConditionId)), ...
                                  string(transpose(condDf.simulationConditionId)));
            else
                condIds = string(transpose(condDf.simulationConditionId));
            end
            
            out = Dict();
            for i = condIds
                out(i) = obj.getModelForCondition(i);
            end
        end
        
        function out = getParsedMeasurementTable(obj)
        %% getParsedMeasurementTable - Returns measurement table including 
        % parsed observables and noise formulas and scales.
        %
        % Syntax: obj.getParsedMeasurementTable;
        %
        % Outputs
        %   out - Table. Parsed measurement table.
            
            % Load observables table and make some workarounds...
            obsTable = obj.observableDf;            
            obsTable.observableFormula = string(obsTable.observableFormula);
            obsTable.noiseFormula = string(obsTable.noiseFormula);
            obsTable.Properties.RowNames = obsTable.observableId;
            obsTable.observableId = [];
            obsColumns = obsTable.Properties.VariableNames;            
            
            % Load measurements table.
            measTable = obj.measurementDf;
            % Init new columns.
            n = height(measTable);
            measTable.observableFormula = strings(n, 1);
            measTable.noiseFormula = strings(n, 1);
            measTable.observableTransformation = repmat("lin", n, 1);
            measTable.noiseDistribution = repmat("normal", n, 1);
            measColumns = measTable.Properties.VariableNames;
            
            for i = 1:n
                obsId = measTable.observableId{i};
                obsFormula = obsTable.observableFormula(obsId);                
                noiseFormula = obsTable.noiseFormula(obsId);

                % Parse observable formulas.
                if ismember('observableParameters', measColumns)
                    if isnumeric(measTable.observableParameters)
                        replList = {measTable.observableParameters(i)};
                    else
                        nObsPar = measTable.observableParameters{i};
                        replList = splitParameterReplacementList(nObsPar);
                    end

                    for j = 1:numel(replList)
                        jObsPar = sprintf('observableParameter%d_%s', j, obsId);
                        obsFormula = mathReplace(obsFormula, jObsPar, replList{j});
                    end
                end        
                measTable.observableFormula(i) = obsFormula;

                % Parse noise formulas.
                if ismember('noiseParameters', measColumns)
                    if isnumeric(measTable.noiseParameters)
                        replList = {measTable.noiseParameters(i)};
                    else
                        nNoisePar = measTable.noiseParameters{i};
                        replList = splitParameterReplacementList(nNoisePar);
                    end

                    for j = 1:numel(replList)
                        jNoisePar = sprintf('noiseParameter%d_%s', j, obsId);
                        noiseFormula = mathReplace(noiseFormula, jNoisePar, replList{j});
                    end
                end        
                measTable.noiseFormula(i) = noiseFormula;

                % Add observable scale.
                if ismember('observableTransformation', obsColumns)
                	obsTrafo = obsTable.observableTransformation{obsId};
                    measTable.observableTransformation(i) = string(obsTrafo);
                end

                % Add noise distribution.        
                if ismember('noiseDistribution', obsColumns)
                	noiseDistr = obsTable.noiseDistribution{obsId};
                	measTable.noiseDistribution(i) = string(noiseDistr);                
                end        
            end

            % Select the proper measurement columns in order.
            if isPreeq(measTable)
                columnMask = ["observableId" "preequilibrationConditionId" "simulationConditionId" "time" ...
                              "measurement" "observableFormula" "noiseFormula" "observableTransformation" ...
                              "noiseDistribution"];
                measTable.preequilibrationConditionId = string(measTable.preequilibrationConditionId);
            else
                columnMask = ["observableId" "simulationConditionId" "time" "measurement" "observableFormula" ...
                              "noiseFormula" "observableTransformation" "noiseDistribution"];
            end            
            
            out = measTable(:, columnMask);
            out.observableId = string(out.observableId);
            out.simulationConditionId = string(out.simulationConditionId);
            
            if isemptyExt(obj.modelsDict)
                modelDict = obj.getModelsDictionary;
            else
                modelDict = obj.modelsDict;
            end
            
            for i = 1:n
                iSimCondId = out.simulationConditionId(i);
                iObsFormula = out.observableFormula(i);
                iNoiseFormula = out.noiseFormula(i);
                iModel = modelDict(iSimCondId);
                
                % Parse observable and noise formula for sbml model
                for j = iModel.sIds.keys
                    bool = ~strcmp(iModel.sIds(j), "reaction") && ~strcmp(iModel.sIds(j), "species") && ...
                           ~contains(iModel.sIds(j), obj.xFreeIds);
                    
                    if bool 
                        iObsFormula = mathReplace(iObsFormula, j, iModel.getElementBySId(j).value);
                        iNoiseFormula = mathReplace(iNoiseFormula, j, iModel.getElementBySId(j).value);
                    end
                end

                % Parse observable and noise formula for parameter table
                parTableDict = Dict(obj.xIds, obj.xNominal);
                for j = parTableDict.keys
                    if ~contains(j, obj.xFreeIds)
                        iObsFormula = mathReplace(iObsFormula, j, parTableDict(j));
                        iNoiseFormula = mathReplace(iNoiseFormula, j, parTableDict(j));
                    end
                end
                
                out.observableFormula(i) = iObsFormula;
                out.noiseFormula(i) = iNoiseFormula;
            end
            
            out.observableFormula = map(@toNumericIfNumeric, out.observableFormula);
            out.noiseFormula = map(@toNumericIfNumeric, out.noiseFormula);
        end
        
        function saveParsedMeasurementTableToTsv(obj, varargin)
        %% saveParsedMeasurementTableToTsv - Writes parsed measurement table to given path as TSV file.
        %
        % Syntax: obj.saveParsedMeasurementTableToTsv('path/to/file.tsv')
        %
        % Inputs;
        %   filepath - String. Optional. Save path of csv table. Defaults to 
        %              './PetabTemp/{modelName}/parsed_measurement_table_{modelname}.tsv'        
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @Petab.isPetab);
            addOptional(p, 'filepath', string.empty, @isStringType);       

            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            filepath = p.Results.filepath;
            % ...input parsed
            
            if isemptyExt(filepath)
                [~, modelName] = fileparts(obj.problemPath);
                tempDir = fullfile(pwd, 'PetabTemp', modelName);
                if ~isfolder(tempDir), mkdir(tempDir); end
                addpath(genpath(fullfile(pwd, 'PetabTemp')));
                filepath = fullfile('.', 'PetabTemp', modelName, "parsed_measurement_table_" + modelName + ".tsv");
            end
            
            writetable(obj.parsedMeasurementTable, filepath, 'FileType', 'text', 'Delimiter', 'tab') 
        end
        
        function loadParsedMeasurementTable(obj, filepath)
        %% loadParsedMeasurementTable - Loads parsed measurement table from given path.
        %
        % Syntax: obj.loadParsedMeasurementTable('path/to/file.tsv')
        %
        % Inputs;
        %   filepath - String. Optional. Load path of tsv table. Defaults to 
        %              './PetabTemp/{modelName}/parsed_measurement_table_{modelname}.tsv'        
            
            if nargin < 2
                [~, modelName] = fileparts(obj.problemPath);
                filepath = fullfile('.', 'PetabTemp', modelName, "parsed_measurement_table_" + modelName + ".tsv");
            end
            
            df = readtable(filepath, 'FileType', 'text', 'ReadVariableNames', true, 'PreserveVariableNames', ...
                           true, 'Delimiter', 'tab');
                        
            for column = string(df.Properties.VariableNames)
                if iscell(df.(column))
                    df.(column) = string(df.(column));
                end
            end
            
            obj.parsedMeasurementTable = df;
        end        
        
        function [t, x] = rrSimulation(obj, model, freeParameters, tStart, tStop)
        %% rrSimulation - Simulates SBML model.
        %
        % Syntax: out = obj.rrSimulation(modelForCondition);
        %
        % Inputs
        %   modelForCondition - SbmlExt. Sbml model.
        %   tStart - Numeric. Starting simulation time.
        %   tStop - Numeric. Stopping simulation time.
        %
        % Outputs
        %   t - Numeric array. Simulation times.
        %   x - Numeric array. Model's simulated states.
        
            check = SbmlExt.isSbmlExt(model) & isnumeric(freeParameters);
            errorId = 'RRSIMULATION:WrongInputError';
            errorMsg = 'Wrong input error';
            assert(check, errorId, errorMsg);
            
            % Add a temporary folder to MATLAB root path if needed.
            [~, modelName] = fileparts(obj.problemPath);
            tempDir = fullfile(pwd, 'PetabTemp', modelName);
            if ~isfolder(tempDir), mkdir(tempDir); end
            addpath(genpath(fullfile(pwd, 'PetabTemp')));
            
            % Instantiate RoadRunner object of current sbml model
            if ~isemptyExt(obj.rrModel)
                delete(obj.rrModel)
                obj.rrModel = RoadRunner.empty();
            end
            
            rrPath = char(fullfile(pwd, 'PetabTemp', modelName, 'rr.xml'));
            model.saveCurrentModel(rrPath)                
            obj.rrModel = RoadRunner(rrPath);           
            
            % Set rr model parameters to given values
            freeIds = obj.xFreeIds;
            modelFreeIds = obj.rrModel.getGlobalParameterIds;
            for i = 1:numel(freeParameters)
                idx = find(modelFreeIds == freeIds(i));
                
                if ~isemptyExt(idx)
                    obj.rrModel.setGlobalParameterByIndex(idx, freeParameters(i))
                end
            end
                        
            % Load rr and simulate
            obj.rrModel.configTimeCourseSimulation(tStart, tStop);
            [t, x] = obj.rrModel.simulate;            

        end
        
        function createProblemFiles(obj)
        %% createProblemFile - Creates ODEs and simulation functions for model experimental conditions.
        %
        % Syntax: obj.createProblemFiles
            [~, modelName] = fileparts(obj.problemPath);
            tempDir = fullfile(pwd, 'PetabTemp', modelName);        
            simConds = obj.getSimulationConditionsFromMeasurementDf;
            for simCond = transpose(simConds.simulationConditionId)
                simFuncName = "simFunc_" + modelName + "_" + simCond{1};

                % Create nonexistent simulation function for each condition
                if ~exist(fullfile(tempDir, simFuncName), 'file')
                    obj.writeSimFuncForCondition(simCond{1})
                end
            end
        end
        
        function out = getSimulationsTable(obj, freeParameters, varargin)
        %% getSimulationsTable - Returns parsed measurement table 
        % includding simulations for given free parameters array.
        %
        % Syntax: out = obj.getSimulationsTable(freeParameters, useRR);
        %
        % Inputs
        %   freeParameters - Array. Free parameters.
        %   useRR - Logical. If true, uses roadrunner simulations.
        %
        % Outputs
        %   out - Table. Simulations table for given parameters values.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @Petab.isPetab);
            addRequired(p, 'freeParameters', @isnumeric);                    
            addOptional(p, 'useRR', false, @islogical);

            parse(p, obj, freeParameters, varargin{:});
            obj = p.Results.obj;
            freeParameters = p.Results.freeParameters;
            useRR = p.Results.useRR;            
            % ...input parsed.          
        
            [~, modelName] = fileparts(obj.problemPath);            
            
            % Work on top of parsed measurements table.
            parsedTable = obj.parsedMeasurementTable;
            
            % Init simulations and noise column.
            simColumn = zeros(height(parsedTable), 1);
            noiseColumn = simColumn;            
            
            if ~useRR
                simDict = Dict();
                for iSimCond = string(transpose(obj.getSimulationConditionsFromMeasurementDf.simulationConditionId))
                    simFuncName = "simFunc_" + modelName + "_" + iSimCond;
                    [t, x] = feval(simFuncName, freeParameters);
                    simDict(iSimCond) = {t, x};
                end
                
                for i = 1:height(parsedTable)                                    
                    iTime = parsedTable.time(i);
                    iObsFormula = string(parsedTable.observableFormula(i));
                    iNoiseFormula = string(parsedTable.noiseFormula(i));
                    iSimCond = parsedTable.simulationConditionId(i);

                    simFunc = simDict(iSimCond);         
                    t = simFunc{1};
                    x = simFunc{2};
                    % Get states array for simulation time
                    currentStates = x(t == iTime, :);
                    
                    func = obj.observableFormulaDict(iObsFormula);
                    simColumn(i) = func(freeParameters, currentStates);
                    func = obj.noiseFormulaDict(iNoiseFormula);
                    noiseColumn(i) = func(freeParameters, currentStates);                
                end
            else
                modelDict = obj.modelsDict;
                
                for i = 1:height(parsedTable)
                    if obj.isPreeq
                        iPreeqCond = parsedTable.preequilibrationConditionId{i};
                        iModel = modelDict(iPreeqCond);                        
                        
                        [~, x] = obj.rrSimulation(iModel, freeParameters, 0, 1E8);
                        
                        x0 = x(end, :);                        
                    end                   
                    
                    iSimCond = parsedTable.simulationConditionId{i};
                    iModel = modelDict(iSimCond);
                    if obj.isPreeq
                        speciesIds = iModel.species.keys;
                        for idx = 1:numel(speciesIds)
                            speciesId = speciesIds(idx);
                            
                            notInConditions = ~ismember(speciesId, obj.conditionDf.Properties.VariableNames);                           
                            if notInConditions
                                iModel.setInitialAssignment(speciesId, x0(idx));
                            end
                        end
                        
                        iModel.applyInitialAssignments;
                        iModel.updateCurrentSbmlModel;
                    end
                    
                    iTime = parsedTable.time(i);
                    iObsFormula = string(parsedTable.observableFormula(i));
                    iNoiseFormula = string(parsedTable.noiseFormula(i));

                    [t, x] = obj.rrSimulation(iModel, freeParameters, 0, max(parsedTable.time));         
                    % Get states array for simulation time
                    currentStates = interp1(t, x, iTime);
                    
                    % Parse observable and noise formula for current states
                    speciesKeys = obj.sbmlModel.species.keys;
                    for j = 1:numel(currentStates)                    
                        iObsFormula = mathReplace(iObsFormula, speciesKeys(j), currentStates(j));
                        iNoiseFormula = mathReplace(iNoiseFormula, speciesKeys(j), currentStates(j));
                    end

                    % Parse observable and noise formula for sbml model
                    for j = iModel.sIds.keys
                        if ~strcmp(iModel.sIds(j), "reaction")
                            iObsFormula = mathReplace(iObsFormula, j, iModel.getElementBySId(j).value);
                            iNoiseFormula = mathReplace(iNoiseFormula, j, iModel.getElementBySId(j).value);
                        end
                    end

                    % Parse observable and noise formula for parameter table
                    parTableDict = Dict(obj.xIds, obj.xNominal);
                    for j = parTableDict.keys
                        iObsFormula = mathReplace(iObsFormula, j, parTableDict(j));
                        iNoiseFormula = mathReplace(iNoiseFormula, j, parTableDict(j));
                    end                

                    simColumn(i) = toNumericIfNumeric(iObsFormula);
                    noiseColumn(i) = toNumericIfNumeric(iNoiseFormula);
                end                
            end           
            
            parsedTable.noiseFormula = noiseColumn;
            
            sim_table = table;
            sim_table.simulation = simColumn;
            out = [parsedTable(:, 1:end - 4) sim_table parsedTable(:, end - 3:end)];
        end
        
        function [J, g, R] = objectiveFunction(obj, optPars)
        %% objectiveFunction - Calculates problem nllh for given optimization parameters vector.
        %
        % Syntax: obj.problemObjectiveFunction(optPars, petab)
        %
        % Inputs
        %   optPars - Numeric. Vector of optimization parameters.
        %   petab - Petab. Petab object.
        %
        % Outputs
        %   J - Numeric. Negative log-likelihood.
        %   g - ¿?
        %   R - Numeric. Problem residuals.
        
            [J, g, R] = problemObjectiveFunction(optPars, obj);
        end
        
        function out = getConditionsDictionary(obj)
        %% getConditionsDictionary - Returns condition table as a (element id - 
        % value/expression) dictionary.
        %
        % Syntax: out = obj.getConditionsDictionary;
        %
        % Outputs
        %    out - Dict. Conditions dictionary.            
            condTable = obj.conditionDf;
            columns = condTable.Properties.VariableNames;
            
            conditionIds = transpose(string(condTable.conditionId));
            elementIds = setdiff(columns, ["conditionId" "conditionName"]);
            
            out = Dict(conditionIds, cell(1, numel(conditionIds)));
            if ~isemptyExt(elementIds)
                for i = 1:numel(conditionIds)
                    conditionDict = Dict;
                    for j = elementIds
                        value = condTable{i, j};
                        if iscell(value), value = string(value); end                        
                        conditionDict(j) = value;
                    end
                    out(conditionIds(i)) = conditionDict;
                end
            end
        end
        
        function out = getModelForCondition(obj, conditionId)
        %% getModelForCondition - Returns model parsed for specific condition.
        %
        % Syntax: obj.getModelForCondition(conditionID);
        %
        % Inputs
        %   conditionId - String type. Condition id.
        %
        % Outputs
        %   out - SbmlExt. Parsed SBML.
            errorId = 'GETSBMLFORCONDITION:WrongInputError';
            errorMsg = 'Input type must be a string or a char';
            assert(isStringType(conditionId), errorId, errorMsg);            
            
            conditions = obj.getConditionsDictionary;            
            check = ismember(conditionId, conditions.keys);
            errorId = 'GETSBMLFORCONDITION:ConditionIdError';
            errorMsg = 'Wrong condition identifier';
            assert(check, errorId, errorMsg);            
            
            out = obj.sbmlModel.copy;
            condDict = conditions(conditionId);
            if isempty(condDict), return; end            
                      
            for condKey = condDict.keys
                condVal = condDict(condKey);
                
                % Parse condition values
                if isStringType(condVal)
                    % Parse for parameter table
                    for i = 1:numel(obj.xIds)
                        xIds = obj.xIds;
                        xNominal = obj.xNominal;
                        condVal = mathReplace(condVal, xIds(i), xNominal(i));
                    end
                    
                    % Parse for model elements
                    for sId = out.sIds.keys
                        if ~strcmp(out.sIds(sId), "reaction")
                            condVal = mathReplace(condVal, sId, out.getElementBySId(sId).value);
                        end
                    end
                    
                    condVal = toNumericIfNumeric(condVal);
                end                

                % Set condition value in sbml model
                out.setElementBySId(condKey, condVal);
                % Set initial assignment
                out.setInitialAssignment(condKey, condVal);
            end
            
            out.applyInitialAssignments;
            out.updateCurrentSbmlModel;
        end
        
        function writeODEsForCondition(obj, conditionId, varargin)
        %% writeODEsForCondition - Write model ODEs function to a file named 
        % ODEsFunc_{conditionId} in Petab temporary folder.
        %
        % ODEs function returns species rates values given time, and arrays of 
        % species quantities and optimization parameters.
        %
        % Syntax: obj.writeODEsForCondition(conditionId);
        %
        % Inputs
        %   conditionId - String type. Condition id.
        %   model - Optional. SbmlExt. Model for condition id as returned by
        %           method sbmlModelForCondition.
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addRequired(p, 'conditionId', @isStringType);
            addOptional(p, 'model', SbmlExt.empty, @SbmlExt.isSbmlExt);
            
            parse(p, obj, conditionId, varargin{:});
            obj = p.Results.obj;
            conditionId = p.Results.conditionId;
            model = p.Results.model;
            % ..input parsed           
            
            % Add a temporary folder to MATLAB root path if needed.
            [~, modelName] = fileparts(obj.problemPath);
            tempDir = fullfile(pwd, 'PetabTemp', modelName);
            if ~isfolder(tempDir), mkdir(tempDir); end
            addpath(genpath(fullfile(pwd, 'PetabTemp')));            
            
            functionName = "ODEsFunc_" + modelName + '_' + string(conditionId);            
            try	
                fileId = fopen(fullfile(tempDir, functionName + ".m"), 'w');
            catch
                % Close all open files...
                fclose('all');
                % ...and throw an error.
                errorId = 'WRITEODESFORCONDITION:WriteFunctionError';
                errorMsg = 'An error occurred during ODEs writing';
                error(errorId, errorMsg);
            end   
            
            % Write function header.
            fprintf(fileId, "function dx = %s(t, x, p)\n", functionName);

            if isemptyExt(model)
                model = obj.getModelForCondition(conditionId);
            end

            % Map time symbol. 
            if ~isemptyExt(model.CurrentSbmlModel.time_symbol)
                timeSymbol = model.CurrentSbmlModel.time_symbol;                    
                if ~strcmp(timeSymbol, 't')
                    fprintf(fileId, "\t%% Time symbol mapping.\n");
                    fprintf(fileId, "\t%s = t;\n\n", timeSymbol);
                end
            end

            % Write function definitions.                
            if ~isemptyExt(model.functionDefinition)
                fprintf(fileId, "\t%% Model function definitions.\n");                    
                for i = model.functionDefinition.keys
                    functionDef = model.functionDefinition();                        
                    fprintf(fileId, "\t%s = %s;\n", i, functionDef);
                end
                fprintf(fileId, "\n");
            end

            % Write parameter mapping.
            fprintf(fileId, "\t%% Parameter mapping\n");
            nFreeParId = obj.xFreeIds;
            for i = 1:numel(nFreeParId)
                iParId = nFreeParId(i);
                if ismember(iParId, model.parameter.keys)
                    fprintf(fileId, "\t%s = p(%d);\n", iParId, i);
                end
            end
            fprintf(fileId, "\n");

            % Write species mapping.
            fprintf(fileId, "\t%% Species mapping\n");
            freeSpecies = string.empty;
            fixedSpecies = string.empty;
            for i = model.species.keys
                speciesStruct = model.species(i);
                check = speciesStruct.isConstant || speciesStruct.isBoundary;
                if check
                    fixedSpecies = horzcat(fixedSpecies, i);
                else
                    freeSpecies = horzcat(freeSpecies, i);
                end
            end                
            for i = 1:numel(freeSpecies)
                fprintf(fileId, "\t%s = x(%d);\n", freeSpecies(i), i);                    
            end
            fprintf(fileId, "\n");

            % Write compartments initial sizes.
            if ~isemptyExt(model.compartment)
                fprintf(fileId, "\t%% Compartments initial sizes.\n");
                for i = model.compartment.keys
                    compartmentStruct = model.compartment(i);
                    size = string(compartmentStruct.value);                        
                    fprintf(fileId, "\t%s = %s;\n", i, size);
                end
                fprintf(fileId, "\n");
            end

            % Write fixed species quantities.                
            if ~isemptyExt(fixedSpecies)
                fprintf(fileId, "\t%% Fixed species initial quantities.\n");
                for i = fixedSpecies
                    speciesStruct = model.species(i);
                    quantity = string(speciesStruct.value);                        
                    fprintf(fileId, "\t%s = %s;\n", i, quantity);
                end
                fprintf(fileId, "\n");
            end

            % Write fixed model parameters.
            fixedPars = setdiff(model.parameter.keys, obj.getOptimizationParameters, 'stable');
            if ~isemptyExt(fixedPars)
                fprintf(fileId, "\t%% Fixed parameters values.\n");
                for i = fixedPars
                    parameterStruct = model.parameter(i);
                    value = string(parameterStruct.value);                        
                    fprintf(fileId, "\t%s = %s;\n", i, value);
                end
                fprintf(fileId, "\n");
            end

            % Write species stoichiometries.
            fprintf(fileId, "\t%% Stoichiometries.\n"); 
            for i = model.sIds.keys
                if ismember(model.sIds(i), ["product" "reactant"])
                    speciesStruct = model.getElementBySId(i);
                    stoichiometry = string(speciesStruct.value);
                    fprintf(fileId, "\t%s = %s;\n", i, stoichiometry);
                end 
            end 
            fprintf(fileId, "\n");

            % Write initial assignments.
            if ~isemptyExt(model.initialAssignment)
                isCommentWrited = false;
                for i = model.initialAssignment.keys
                    assignmentStruct = model.getInitialAssignmentStruct(i);

                    check = strcmp(assignmentStruct.notes, 'SbmlExt') && ismember(i, obj.xFreeIds);                        
                    if check
                        if ~isCommentWrited
                            fprintf(fileId, "\t%% Initial assignments.\n");
                            isCommentWrited = true;
                        end

                        ode = string(model.initialAssignment(i));
                        fprintf(fileId, "\t%s = %s;\n", i, ode);
                    end
                end                    
                if isCommentWrited, fprintf(fileId, "\n"); end   
            end

            % Write assignment rules to file.
            if ~isemptyExt(model.assignmentRule)
                isCommentWrited = false;                    
                for i = model.assignmentRule.keys
                    if ~strcmp(model.sIds(i), 'species')
                        fprintf(fileId, "\t%% Assignment rules.\n");
                        isCommentWrited = true;
                    end
                    
                    ode = string(model.assignmentRule(i));
                    fprintf(fileId, "\t%s = %s;\n", i, ode);
                end                    
                if isCommentWrited, fprintf(fileId, "\n"); end
            end                

            % Init ODEs array.
            n = numel(model.dxdt.keys);
            fprintf(fileId, "\tdx = zeros(%d, 1);\n", n);
            % Write ODEs.
            fprintf(fileId, "\t%% ODEs.\n");                
            for i = 1:n
                speciesId = model.dxdt.keys(i);
                ode = model.dxdt(speciesId);
                fprintf(fileId, "\tdx(%d) = %s;\n", i, ode);                    
            end                
            fprintf(fileId, "end");
         
            fclose(fileId);
        end
        
        function writeSimFuncForCondition(obj, condId, varargin)
        %% writeSimFuncForCondition - Write model simulation function to a file 
        % named simFunc_{conditionId} in Petab temporary folder.
        %
        % Simulation function returns simulation times and species quantities
        % for a specific model condition.
        %
        % Syntax: obj.writeSimFuncForCondition(conditionId, useRR);
        %
        % Inputs
        %   condId - String type. Condition id.
        %   useRR - Optional. Logical. If true, model is simulated using
        %           Roadrunner C library, else, ode15s MATLAB built-in is used.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addRequired(p, 'condId', @isStringType);
            addOptional(p, 'useRR', false, @islogical);
            
            parse(p, obj, condId, varargin{:});
            obj = p.Results.obj;
            condId = p.Results.condId;
            % ...input parsed
            
            % condId argument must be a simulation condition id.
            simCondTable = obj.getSimulationConditionsFromMeasurementDf;
            check = ismember(condId, simCondTable.simulationConditionId);
            errorId = 'WRITESIMFUNCFORCONDITION:WrongConditionId';
            errorMsg = 'Input condition must be a simulation condition';
            assert(check, errorId, errorMsg);
                                   
            % Add a temporary folder to MATLAB root path if needed.
            [~, modelName] = fileparts(obj.problemPath);
            tempDir = fullfile(pwd, 'PetabTemp', modelName);
            if ~isfolder(tempDir), mkdir(tempDir); end
            addpath(genpath(fullfile(pwd, 'PetabTemp'))); 
            
            % Create simulation ODEs for condId argument function if needed.
            model = obj.modelsDict(condId);
            ODEFuncName = "ODEsFunc_" + modelName + "_" + condId;
            ODEFuncPath = fullfile(tempDir, ODEFuncName + ".m");
            if ~isfile(ODEFuncPath)
                obj.writeODEsForCondition(condId, model);
            end
            
            % Create preequilibration ODEs function if needed.            
            if obj.isPreeq
                simCondTable = tableSubset(simCondTable, 'simulationConditionId', condId);
                preeqId = simCondTable.preequilibrationConditionId{1};                
                preeqModel = obj.modelsDict(preeqId);
                preeqFuncName = "ODEsFunc_" + modelName + "_" + preeqId;
                ODEFuncPath = fullfile(tempDir, preeqFuncName + ".m");
                if ~isfile(ODEFuncPath)
                    obj.writeODEsForCondition(preeqId, preeqModel);
                end                
            end
            
            % Get condition specific simulation times from measurement table.
            measurementDfForCondition = tableSubset(obj.measurementDf, 'simulationConditionId', condId);
            measurementTimes = sort(unique(measurementDfForCondition.time));
            % Parse measurement times for simulation.
            if measurementTimes(1) == 0
                simulationTimes = measurementTimes;
                simulationTimes(1) = eps;
            else
                simulationTimes = vertcat(0, measurementTimes);
            end
            
            functionName = "simFunc_" + modelName + "_" + condId;
            try                
                fileId = fopen(fullfile(tempDir, functionName + ".m"), 'w');
            catch
                % Close all open files...
                fclose('all');
                % ...and throw an error.
                errorId = 'WRITESIMFUNCFORCONDITION:WriteFunctionError';
                errorMsg = 'An error occurred during simulation function writing';
                error(errorId, errorMsg);
            end   
            
            % Write function header.
            fprintf(fileId, "function [t, x] = %s(p)\n", functionName);
            fprintf(fileId, "\tmeasTime = %s;\n", mat2str(measurementTimes));            
            fprintf(fileId, "\tsimTime = %s;\n\n", mat2str(simulationTimes));
                       
            if obj.isPreeq
                % Write event function.
                fprintf(fileId, "\t%% Preequilibration.\n");
                fprintf(fileId, "\tfunction [dx, isterm, dir] = event(t, x, p)\n");                 
                fprintf(fileId,  "\t\tdx = %s(t, x, p);\n", preeqFuncName);
                fprintf(fileId, "\t\tdx = norm(dx) - 1E-6;\n\n");
                fprintf(fileId, "\t\tisterm = 1;\n");
                fprintf(fileId, "\t\tdir = 0;\n");
                fprintf(fileId, "\tend\n");

                fprintf(fileId, "\topts = odeset('Events', @event);\n");                    
                funcString = sprintf("@%s", preeqFuncName);                
                fprintf(fileId, "\tx0 = %s;\n", mat2str(preeqModel.getX0));                   
                fprintf(fileId, "\t[~, x] = ode15s(" + funcString + ", [0 Inf], x0, opts, p);\n\n");
                fprintf(fileId, "\t%% Species initial quantities.\n");                    
                fprintf(fileId, "\tx0 = x(end, :);\n\n");

                % Correction of initial quantities in case any of them is a condition.
                for i = 1:numel(model.species.keys)
                    specie = model.species.keys(i);

                    condDict = obj.getConditionsDictionary;
                    condDict = condDict(preeqId);

                    if ismember(specie, condDict.keys)
                        speciesVal = preeqModel.getX0;                            
                        fprintf(fileId, "\tx0(%d) = %d;\n\n", i, speciesVal(i));                            
                    end
                end                    
            else
                fprintf(fileId, "\t%% Species initial quantities.\n");                    
                fprintf(fileId, "\tx0 = %s;\n", mat2str(model.getX0));
            end

            fprintf(fileId, "\t%% Simulation.\n");
            funcString = sprintf("@%s", ODEFuncName);
            fprintf(fileId, "\t[t, x] = ode15s(" + funcString + ", simTime, x0, [], p);\n\n");

            % Correction of 0 replacement.
            if measurementTimes(1) == 0, fprintf(fileId, '\tt(1) = 0;\n'); end

            fprintf(fileId, "\t[~, idx] = intersect(t, " + "measTime, 'stable');\n");                
            fprintf(fileId, "\tt = measTime;\n");                
            fprintf(fileId, "\tx = x(idx, :);\n");

            fprintf(fileId, "end");
         
            fclose(fileId);
        end
        
        function result = getFormulaFunctionDict(obj, formulas)
        %% getFormulaFunctionDict - Returns a dictionary with given formula strings as keys and formula function 
        % handlers as values.
        %
        % Syntax: obj.getFormulaFunctionDict
        %
        % Outputs
        %    result - Dict. Formula String/Formula function handler dictionary.
        
            freePars = obj.xFreeIds;
            species = obj.sbmlModel.species.keys;
            
            result = Dict();
            for i = 1:numel(formulas)
                formula = string(formulas(i));
                for j = 1:numel(freePars)
                    formula = mathReplace(formula, freePars(j), sprintf('p(%d)', j));
                end
                
                for j = 1:numel(species)
                    formula = mathReplace(formula, species(j), sprintf('s(%d)', j));
                end
                result(formulas(i)) = str2func("@(p, s) " + formula);
            end           
        end       
        
        function removeTempFiles(obj)
        %% removeTempFiles - Removes petab problem from PetabTemp and from path.
        %
        % Syntax: obj.removeTempFiles;            
            [~, modelName] = fileparts(obj.problemPath);
            modelPath = fullfile(pwd, 'PetabTemp', modelName);
            
            if isfolder(modelPath)                
                rmpath(genpath(modelPath));
                
                check = logical(rmdir(modelPath, 's'));
                errorId = 'REMOVETEMPFILES:TemporaryFilesRemovalError';
                errorMsg = 'An error occurred when deleting temporary files';
                assert(check, errorId, errorMsg);      
            end
        end
    end
    
    methods (Static)
% STATIC METHODS
        function petab = fromFiles(varargin)
        %% fromFiles - Load model and tables from files.
        %
        % Syntax: fromFiles(problemDirectory, sbmlFile, conditionFile,
        %                   mesurementFile, parameterFile, observableFile)
        % Inputs
        %	problemPath - Optional. String type. PEtab problem root directory 
        %                 path. Defaults to an empty string.
        %   sbmlFile - Optional. String type. SBML model file path. Defaults to 
        %              an empty string.
        %   conditionFile - Optional. String type. PEtab conditions table file 
        %                   path. Defaults to an empty string.
        %   measurementFile - Optional. String type. PEtab mesurements table 
        %                     file path. Defaults to an empty string.
        %   parameterFile - Optional. PEtab parameters table file path. 
        %                   Defaults to an empty string.
        %   observablesFile - Optional. PEtab observables table file path.
        %                     Defaults to an empty string.
        %
        % Outputs
        %	petab - Petab. Petab object.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'problemPath', @isStringType)
            addRequired(p, 'sbmlFile', @isStringType)
            addRequired(p, 'conditionFile', @isStringType)
            addRequired(p, 'measurementFile', @isStringType)
            addRequired(p, 'parameterFile', @isStringType)
            addRequired(p, 'observableFile', @isStringType)
            
            parse(p, varargin{:})            
            problemPath = what(p.Results.problemPath).path;            
            sbmlFile = p.Results.sbmlFile;
            conditionFile = p.Results.conditionFile;
            measurementFile = p.Results.measurementFile;
            parameterFile = p.Results.parameterFile;
            observableFile = p.Results.observableFile;            
            % ...input parsed.
            
            % Load SBML model.
            if ~isemptyExt(sbmlFile), sbmlModel = SbmlExt(sbmlFile); end
            % Load condition table.            
            if ~isemptyExt(conditionFile) 
                conditionDf = getConditionDf(conditionFile);
            end
            % Load measurements table.
            if ~isemptyExt(measurementFile)
                measurementDf = ...
                    concatTables(measurementFile, @getMeasurementDf);
            end
            % Load parameters table.
            if ~isemptyExt(parameterFile)
                parameterDf = getParameterDf(parameterFile);
            end
            % Load observables table.
            if ~isemptyExt(observableFile)
                observableDf = concatTables(observableFile, @getObservableDf);
            end
            
            petab = Petab(problemPath, sbmlModel, conditionDf, measurementDf, parameterDf, observableDf);
        end
        
        function petab = fromYaml(yamlOrPath, varargin)
        %% fromYaml - Load model and tables as specified by YAML file.
        %
        % Syntax: fromYaml(dirOrPath, modelName);
        %
        % Inputs
        %   yamlOrPath - String type or struct. Path to YAML file or loaded YAML
        %                structure containing PEtab configuration.
        %   modelName - Optional. String type. if specified, overrides the
        %               model component in the file names. Defaults to the last
        %               component in yamlOrPath argument.
        %
        % Outputs
        %   petab - Petab. Petab object.
        %
        % Example
        %   petab = fromYaml('fullPathToYamlFile');
        %   petab = fromYaml('pathToYamlFileFolder', 'modelName');
        %   petab = fromYaml(yamlStructure);
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'yamlOrPath', @(x) isStringType(x) || isstruct(x));
            addOptional(p, 'modelName', string.empty, @iStringType);
            
            parse(p, yamlOrPath, varargin{:})
            yamlOrPath = p.Results.yamlOrPath;
            modelName = p.Results.modelName;
            % ...input parsed.
            
            if isstruct(yamlOrPath)
                problemPath = what(yamlOrPath).path;
                yamlConfig = yamlOrPath;
            else
                % Conversion required because Yaml importer restrictions.
                yamlOrPath = char(yamlOrPath);
                if isemptyExt(modelName)
                    problemPath = fileparts(yamlOrPath);
                else
                    problemPath = yamlOrPath;
                    yamlOrPath = fullfile(yamlOrPath, [modelName, '.yaml']);                    
                end                
                
                errorId = 'FROMYAML:FileNotFoundError';
                errorMsg = 'No such file or directory';
                assert(isfile(yamlOrPath), errorId, errorMsg);
                
                yamlConfig = ReadYaml(yamlOrPath);
            end
            
            petabProblem = yamlConfig.problems{1};            
            assertSingleConditionAndSbmlFile(petabProblem);
            
            sbmlFiles = petabProblem.sbml_files{1};
            conditionFiles = petabProblem.condition_files{1};
            measurementFiles = petabProblem.measurement_files{1};
            parameterFiles = yamlConfig.parameter_file;
            observableFiles = petabProblem.observable_files{1};
            
            petab = Petab.fromFiles(problemPath, ...
                                    fullfile(problemPath, sbmlFiles), ...
                                    fullfile(problemPath, conditionFiles), ...
                                    fullfile(problemPath, measurementFiles), ...
                                    fullfile(problemPath, parameterFiles), ...
                                    fullfile(problemPath, observableFiles));
        end
        
        function out = isPetab(input)
        %% isPetab - Check if input argument is a Petab object.
        %
        % Syntax: out = Petab.isPetab(input);
        %
        % Inputs
        %   input - Any type object.
        %
        % Outputs
        %   out - Logical. True if input argument is a Petab object, else false.            
            out = isa(input, 'Petab');
        end
        
        function cleanTempFiles
        %% cleanTempFiles - Removes PetabTemp folder and all its contents.
        %
        % Syntax: Petab.cleanTempFiles
        
            tempPath = fullfile(pwd, 'PetabTemp');
            
            if isfolder(tempPath)                
                rmpath(genpath(tempPath));
                
                check = logical(rmdir(tempPath, 's'));
                errorId = 'CLEANTEMPFILES:TemporaryFilesRemovalError';
                errorMsg = 'An error occurred when deleting temporary files';
                assert(check, errorId, errorMsg);      
            end            
        end
    end
        
    methods (Access = private)
% AUXILIAR METHODS
        function out = xFreeIndices(obj)
        %% xFreeIndices - Optimization parameter indices.
        %
        % Syntax: out = obj.xFreeIndices;
        %
        % Outputs
        %    out - String. Indices of free parameters.            
            out = find(obj.parameterDf.estimate);
        end
        
        function out = xFixedIndices(obj)
        %% xFixedIndices - Non-estimated parameter indices.
        %
        % Syntax: out = obj.xFixedIndices
        %
        % Outputs
        %    out - String. Indices of fixed parameters.            
            out = find(~obj.parameterDf.estimate);
        end       
        
        function out = applyMask(obj, array, varargin)
        %% applyMask - Apply mask of only free or only fixed values.
        %
        % Syntax: out = obj.applyMask(v, free, fixed);
        %
        % Inputs
        %	array - Numeric or cell. Array the mask is to be applied to.
        %   free - Optional. Logical. Whether to return free parameters.
        %          Defaults to true.
        %   fixed - Optional. Logical. Whether to return fixed parameters.
        %           Defaults to true.
        %
        % Outputs
        %   out - Numeric or cell. Array after apply mask.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addRequired(p, 'array', @(x) isnumeric(x) || isstring(x) || iscell(x));
            addOptional(p, 'free', true, @islogical);
            addOptional(p, 'fixed', true, @islogical);
            
            parse(p, obj, array, varargin{:});
            obj = p.Results.obj;
            array = p.Results.array;
            free = p.Results.free;
            fixed = p.Results.fixed;
            % ...input parsed.
            
            errorId = 'APPLYMASK:WrongInputCombinationError';
            errorMsg = "Free and fixed arguments can't be both false";
            assert(free || fixed, errorId, errorMsg);
            
            if free && ~fixed
                out = array(obj.xFreeIndices);
            elseif ~free && fixed
                out = array(obj.xFixedIndices);
            else
                out = array;
            end
        end
        
        function out = getXIds(obj, varargin)
        %% getXIds - Generic function to get parameter identifiers.
        %
        % Syntax: obj.getXIds(free, fixed)
        %
        % Inputs
        %	free - Optional. Logical. Whether to return free parameter 
        %          identifiers. Defaults to true.
        %   fixed - Optional. Logical. Whether to return fixed parameter 
        %           identifiers. Defaults to true.
        %
        % Outputs
        %    out - String. Parameter identifiers.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addOptional(p, 'free', true, @islogical);
            addOptional(p, 'fixed', true, @islogical);
            
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            free = p.Results.free;
            fixed = p.Results.fixed;
            % ...input parsed.        
            
            array = string(obj.parameterDf.parameterId);
            out = transpose(obj.applyMask(array, free, fixed));
        end
        
        function out = getXNominal(obj, varargin)
        %% getXNominal - Generic function to get parameter nominal values.
        %
        % Syntax: obj.getXNominal(free, fixed, scaled)
        %
        % Inputs
        %   free - Optional. Logical. Whether to return free parameter 
        %          nominal values. Defaults to true
        %   fixed - Optional. Logical. Whether to return fixed parameter 
        %           nominal values. Defaults to true.
        %   scaled - Optional. Logical. Whether to apply scale to parameter
        %            nominal values. Defaults to false
        %
        % Outputs
        %   out - String. Parameter nominal values.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addOptional(p, 'free', true, @islogical);
            addOptional(p, 'fixed', true, @islogical);
            addOptional(p, 'scaled', false, @islogical);
            
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            free = p.Results.free;
            fixed = p.Results.fixed;
            scaled = p.Results.scaled;
            % ...input parsed
            
            if scaled                
                array = map(@applyScale, obj.parameterDf.nominalValue, string(obj.parameterDf.parameterScale));
            else
                array = obj.parameterDf.nominalValue;
            end            
            out = transpose(obj.applyMask(array, free, fixed));
        end
        
        function out = getLb(obj, varargin)
        %% getLb - Generic function to get parameter lower bounds.
        %
        % Syntax: obj.getLb(free, fixed, scaled)
        %
        % Inputs
        %   free - Optional. Logical. Whether to return free parameter
        %          lower bounds. Defaults to true.
        %   fixed - Optional. Logical. Whether to return fixed parameter
        %           lower bounds. Defaults to true.
        %   scaled - Optional. Logical. Whether to apply scale to parameter
        %            lower bounds. Defaults to false.
        %
        % Outputs
        %   out - String. Parameter lower bounds.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addOptional(p, 'free', true, @islogical);
            addOptional(p, 'fixed', true, @islogical);
            addOptional(p, 'scaled', false, @islogical);
            
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            free = p.Results.free;
            fixed = p.Results.fixed;
            scaled = p.Results.scaled;
            % ...input parsed.
            
            if scaled
                array = map(@applyScale, obj.parameterDf.lowerBound, string(obj.parameterDf.parameterScale));
            else
                array = obj.parameterDf.lowerBound;
            end            
            out = transpose(obj.applyMask(array, free, fixed));
        end
        
        function out = getUb(obj, varargin)
        %% getUb - Generic function to get parameter upper bounds.
        %
        % Syntax: obj.getUb(free, fixed, scaled)
        %
        % Inputs
        %   free - Optional. Logical. Whether to return free parameter
        %          upper bounds. Defaults to true.
        %   fixed - Optional. Logical. Whether to return fixed parameter 
        %           upper bounds. Defaults to true.
        %   scaled - Optional. Logical. Whether to apply scale to parameter
        %            upper bounds. Defaults to false.
        %
        % Outputs
        %   out - String. Parameter upper bounds.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Petab.isPetab);
            addOptional(p, 'free', true, @islogical);
            addOptional(p, 'fixed', true, @islogical);
            addOptional(p, 'scaled', false, @islogical);
            
            parse(p, obj, varargin{:});
            obj = p.Results.obj;
            free = p.Results.free;
            fixed = p.Results.fixed;
            scaled = p.Results.scaled;
            % ...input parsed.
            
            if scaled
                array = map(@applyScale, obj.parameterDf.lowerBound, string(obj.parameterDf.parameterScale));
            else
                array = obj.parameterDf.lowerBound;
            end            
            out = transpose(obj.applyMask(array, free, fixed));
        end
    end
% ------------- END OF CODE --------------    
end