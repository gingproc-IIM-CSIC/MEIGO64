classdef RoadRunner < handle & matlab.mixin.Copyable
%% RoadRunner - MATLAB API for roadRunner simulation library.
%
% Other m-files none
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 03-10-2020
%% ------------- BEGIN CODE --------------

% PROPERTIES   
    properties (Access = private)
        rrcHandler = libpointer;
    end
    
    properties (SetAccess = private)
        isRRLibLoaded logical = false;
        isRRCHandler logical = false;
        isSBMLLoaded logical = false;        
    end    

    methods
% OBJECT METHODS        
        function obj = RoadRunner(varargin)
        %% Constructor.
        
            % Parse input...
            p = inputParser;
            
            addOptional(p, 'path', string.empty, @isStringType);
            addOptional(p, 'modelName', string.empty, @isStringType);
            
            parse(p, varargin{:});
            path = p.Results.path;
            modelName = p.Results.modelName;
            % ...input parsed.
            
            if isemptyExt(path), return; end
            
            if ~isemptyExt(modelName)
                path = fullfile(path, [modelName '.xml']);
            end
            
            errorId = 'ROADRUNNER:FileNotFoundError';
            errorMsg = 'No such file or directory';
            assert(isfile(path), errorId, errorMsg);
            
            obj.loadRoadRunnerSharedLibrary;
            obj.createRRInstance;
            obj.loadSBMLFromFile(path);       
        end
        
        function delete(obj)
        %% Destructor.        
            if obj.isSBMLLoaded
                check = calllib('roadrunner_c_api', 'clearModel', obj.rrcHandler);                           
                errorId = 'ROADRUNNER:ClearSBMLError';
                errorMsg = 'An error occurred while clearing SBML model';
                assert(check, errorId, errorMsg);
            end
            
            if obj.isRRCHandler
                check = calllib('roadrunner_c_api', 'freeRRInstance', obj.rrcHandler);                           
                errorId = 'ROADRUNNER:FreeRrcHandlerError';
                errorMsg = 'An error occurred while freeing the rrcHandler';                
                assert(check, errorId, errorMsg);                
            end
            
            if libisloaded('roadrunner_c_api'), unloadlibrary('roadrunner_c_api'); end            
        end
        
        function out = get.rrcHandler(obj)
        %% rrcHandler's get method.           
            callerName = dbstack(1);
            callerName = callerName.name;
            if ~strcmp(callerName, 'RoadRunner.createRRInstance')
                errorId = 'ROADRUNNER:RrcHandlerNotCreatedError';
                errorMsg = 'Roadrunner handler instance not created yet';                 
                assert(obj.isRRCHandler, errorId, errorMsg);
            end
            
            if ~ismember(callerName, ["RoadRunner.createRRInstance", "RoadRunner.loadSBMLFromFile"])                     
                errorId = 'ROADRUNNER:RrcSBMLNotLoadeddError';
                errorMsg = 'SBML model not loaded yet';
                assert(obj.isSBMLLoaded, errorId, errorMsg);
            end
               
            out = obj.rrcHandler;
        end
        
        function out = getNumberOfBoundarySpecies(obj)
        %% getNumberOfBoundarySpecies - Returns boundary species' count.
        %
        % Syntax: out = obj.getNumberOfBoundarySpecies;
        %
        % Outputs
        %   out - Numeric. Number of boundary species.
        
            out = calllib('roadrunner_c_api', 'getNumberOfBoundarySpecies', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfBoundarySpeciesError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getBoundarySpeciesIds(obj)
        %% getBoundarySpeciesIds - Returns boundary species' identifiers.
        %
        % Syntax: out = obj.getBoundarySpeciesIds;
        %
        % Outputs
        %   out - String. Boundary species identifiers.
        
            speciesIds = calllib('roadrunner_c_api', 'getBoundarySpeciesIds', obj.rrcHandler);                                  
            errorId = 'ROADRUNNER:getBoundarySpeciesIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(speciesIds), errorId, errorMsg);
            
            out = RoadRunner.stringArrayToString(speciesIds);
        end
        
        function out = getBoundarySpeciesByIndex(obj, index)
        %% getBoundarySpeciesByIndex - Returns boundary species' concentration by 
        % index.
        %
        % Syntax: out = obj.getBoundarySpeciesByIndex(index);
        %
        % Inputs
        %   index - Numeric.
        %
        % Outputs
        %   out - Numeric. Boundary species' concentration.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            speciesPtr = libpointer('doublePtr', NaN);            
            bool = calllib('roadrunner_c_api', 'getBoundarySpeciesByIndex', obj.rrcHandler, index - 1, speciesPtr);
            
            errorId = 'ROADRUNNER:getBoundarySpeciesByIndexError';
            errorMsg = 'An error occurred during method call';                       
            assert(bool, errorId, errorMsg);
            
            out = speciesPtr.Value;
        end
        
        function out = getBoundarySpeciesConcentrations(obj)
        %% getBoundarySpeciesConcentrations - Returns boundary species'
        % concentrations.
        %
        % Syntax: out = obj.getBoundarySpeciesConcentrations;
        %
        % Outputs
        %   out - Numeric. Boundary species concentrations.
        
            n = obj.getNumberOfBoundarySpecies;
            out = map(@obj.getBoundarySpeciesByIndex, 1:n);
        end
        
        function setBoundarySpeciesByIndex(obj, index, value)
        %% setBoundarySpeciesByIndex - Set boundary species' concentration by 
        % index.
        %
        % Syntax: obj.setBoundarySpeciesByIndex(index, value);
        %
        % Inputs
        %   index - Numeric.
        %   value - Numeric. Species' concentration.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'index', @isPositiveIntegerValuedNumeric);
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, index, value);
            obj = p.Results.obj;
            index = p.Results.index;
            value = p.Results.value;  
            % ...input parsed.
        
            check = calllib('roadrunner_c_api', 'setBoundarySpeciesByIndex', obj.rrcHandler, index - 1, value);                        
            errorId = 'ROADRUNNER:setBoundarySpeciesByIndexError';
            errorMsg = 'An error occurred while setting boundary species value';
            assert(check, errorId, errorMsg);
        end
        
        function setBoundarySpeciesConcentrations(obj, values)
        %% setBoundarySpeciesConcentrations - Set all bounday species'
        % concentration.
        %
        % Syntax: obj.setBoundarySpeciesConcentrations(values);
        %
        % Inputs
        %   values - Numeric. Boundary species concentrations.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'values', @isnumeric);

            parse(p, obj, values);
            obj = p.Results.obj;
            values = p.Results.values;
            % ...input parsed.
            
            n = obj.getNumberOfBoundarySpecies;
            map(@obj.setBoundarySpeciesByIndex, 1:n, values);      
        end
        
        function out = getNumberOfFloatingSpecies(obj)
        %% getNumberOfFloatingSpecies - Returns floating species' count.
        %
        % Syntax: out = obj.getNumberOfFloatingSpecies;
        %
        % Outputs
        %   out - Numeric. Number of floating species.
        
            out = calllib('roadrunner_c_api', 'getNumberOfFloatingSpecies', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfFloatingSpeciesError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getFloatingSpeciesIds(obj)
        %% getFloatingSpeciesIds - Obtain the list of floating species identifiers.
        %
        % Syntax: out = obj.getFloatingSpeciesIds;
        %
        % Outputs
        %   out - String. Floating species' identifiers.
        
            speciesIds = calllib('roadrunner_c_api', 'getFloatingSpeciesIds', obj.rrcHandler);                              
            errorId = 'ROADRUNNER:getFloatingSpeciesIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(speciesIds), errorId, errorMsg);
               
            out = RoadRunner.stringArrayToString(speciesIds);
        end
        
        function out = getFloatingSpeciesByIndex(obj, index)
        %% getFloatingSpeciesByIndex - Returns floating species' concentration by
        % index.
        %
        % Syntax: out = obj.getFloatingSpeciesByIndex(index);
        %
        % Inputs
        %   index - Numeric.
        %
        % Outputs
        %   out - Numeric. Floating species' concentration.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            speciesPtr = libpointer('doublePtr', NaN);            
            check = calllib('roadrunner_c_api', 'getFloatingSpeciesByIndex', obj.rrcHandler, index - 1, speciesPtr);                       
            errorId = 'ROADRUNNER:getFloatingSpeciesByIndexError';
            errorMsg = 'An error occurred during method call';            
            assert(check, errorId, errorMsg);
            
            out = speciesPtr.Value;
        end
        
        function out = getFloatingSpeciesConcentrations(obj)
        %% getFloatingSpeciesConcentrations - Retrieve the concentrations for 
        % all the floating species.
        %
        % Syntax: out = obj.getFloatingSpeciesConcentrations;
        %
        % Outputs
        %   out - Numeric. Floating species' concentrations.
        
            n = obj.getNumberOfFloatingSpecies;
            out = map(@obj.getFloatingSpeciesByIndex, 1:n);
        end
        
        function out = getFloatingSpeciesInitialConcentrationByIndex(obj, index)
        %% getFloatingSpeciesInitialConcentrationByIndex - Returns floating 
        % species initial concentration by index.
        %
        % Syntax
        %   out = obj.getFloatingSpeciesInitialConcentrationByIndex(index);
        %
        % Inputs:
        %   index - Numeric. Floating species index.
        %
        % Outputs
        %   out - Numeric. Floating species initial concentration.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input "index" must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            speciesPtr = libpointer('doublePtr', NaN);
            
            bool = calllib('roadrunner_c_api', ...
                'getFloatingSpeciesInitialConcentrationByIndex', ...
                obj.rrcHandler, index - 1, speciesPtr);                       
            errorId = ['ROADRUNNER:getFloatingSpeciesInitialError' ...
                      'ConcentrationByIndexError'];
            errorMsg = 'An error occurred during method call';
            assert(bool, errorId, errorMsg);
            
            out = speciesPtr.Value;
        end
        
        function out = getFloatingSpeciesInitialConcentrations(obj)
        %% getFloatingSpeciesInitialConcentrations - Returns floating species' 
        % initial concentrations.
        %
        % Syntax: out = obj.getFloatingSpeciesInitialConcentrations;
        %
        % Outputs
        %    out - Numeric. Floating species' initial concentrations.
        
            n = obj.getNumberOfFloatingSpecies;
            out = map(@obj.getFloatingSpeciesInitialConcentrationByIndex, 1:n);
        end
        
        function setFloatingSpeciesByIndex(obj, index, value)
        %% setFloatingSpeciesByIndex - Set floating species' concentration by 
        % index.
        %
        % Syntax: obj.setFloatingSpeciesByIndex(index, value);
        %
        % Inputs
        %   index - Numeric.
        %   value - Numeric. Floating species' concentration.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'index', @isPositiveIntegerValuedNumeric);
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, index, value);
            obj = p.Results.obj;
            index = p.Results.index;
            value = p.Results.value;  
            % ...input parsed.
        
            check = calllib('roadrunner_c_api', 'setFloatingSpeciesByIndex', obj.rrcHandler, index - 1, value);                        
            errorId = 'ROADRUNNER:setFloatingSpeciesByIndexError';
            errorMsg = "An error occurred while setting floating species' value";
            assert(check, errorId, errorMsg);
        end
        
        function setFloatingSpeciesConcentrations(obj, values)
        %% setFloatingSpeciesConcentrations - Set floating species'
        % concentrations.
        %
        % Syntax: obj.setFloatingSpeciesConcentrations(values);
        %
        % Inputs
        %   values - Numeric. Floating species' concentrations.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'values', @isnumeric);

            parse(p, obj, values);
            obj = p.Results.obj;
            values = p.Results.values;
            % ...input parsed.
            
            n = obj.getNumberOfFloatingSpecies;
            map(@obj.setFloatingSpeciesByIndex, 1:n, values);      
        end
        
        function setFloatingSpeciesInitialConcentrationByIndex(obj, index, value)
        %% setFloatingSpeciesInitialConcentrationByIndex - Set floating species' 
        % initial concentration.
        %
        % Syntax: obj.setFloatingSpeciesInitialConcentrationByIndex(index, value);
        %
        % Inputs
        %   index - Numeric.
        %   value - Numeric. Floating species' initial concentration.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'index', @isPositiveIntegerValuedNumeric);
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, index, value);
            obj = p.Results.obj;
            index = p.Results.index;
            value = p.Results.value;  
            % ...input parsed.
        
            check = calllib('roadrunner_c_api', 'setFloatingSpeciesInitialConcentrationByIndex', obj.rrcHandler, ...
                            index - 1, value);                        
            errorId = 'ROADRUNNER:setFloatingSpeciesInitialConcentrationByIndexError';                   
            errorMsg = 'An error occurred while setting floating species initial value';
            assert(check, errorId, errorMsg);  
        end
        
        function setFloatingSpeciesInitialConcentrations(obj, values)
        %% setFloatingSpeciesInitialConcentrations - Set floating species' 
        % initial concentrations.
        %
        % Syntax: obj.setFloatingSpeciesInitialConcentrations(values)
        %
        % Inputs
        %   values - Numeric. Floating species' initial concentrations.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'values', @isnumeric);

            parse(p, obj, values);
            obj = p.Results.obj;
            values = p.Results.values;
            % ...input parsed.
            
            n = obj.getNumberOfFloatingSpecies;
            map(@obj.setFloatingSpeciesInitialConcentrationByIndex, 1:n, values);      
        end
        
        function out = getNumberOfGlobalParameters(obj)
        %% getNumberOfGlobalParameters - Get global parameters' count.
        %
        % Syntax: out = obj.getNumberOfGlobalParameters;
        %
        % Outputs:
        %   out - Numeric. Number of global parameters.
        
            out = calllib('roadrunner_c_api', 'getNumberOfGlobalParameters', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfGlobalParametersError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getGlobalParameterIds(obj)
        %% getGlobalParameterIds - Returns global parameters' identifiers.
        %
        % Syntax: out = obj.getGlobalParameterIds;
        %
        % Outputs
        %   out - String. Global parameters' identifiers.
        
            stringArray = calllib('roadrunner_c_api', 'getGlobalParameterIds', obj.rrcHandler);                              
            errorId = 'ROADRUNNER:getGlobalParameterIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(stringArray), errorId, errorMsg);
               
            out = RoadRunner.stringArrayToString(stringArray);
        end
        
        function out = getGlobalParameterByIndex(obj, index)
        %% getGlobalParameterByIndex - Get global parameter's value by index.
        %
        % Syntax: out = obj.getGlobalParameterByIndex(index);
        %
        % Inputs:
        %   index - Numeric.
        %
        % Outputs
        %   out - Numeric. Global parameter's value.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';            
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            parameterPtr = libpointer('doublePtr', NaN);            
            check = calllib('roadrunner_c_api', 'getGlobalParameterByIndex', obj.rrcHandler, index - 1, parameterPtr);                       
            errorId = 'ROADRUNNER:getGlobalParameterByIndexError';
            errorMsg = 'An error occurred during method call';
            assert(check, errorId, errorMsg);
            
            out = parameterPtr.Value;
        end        
        
        function out = getGlobalParameterValues(obj)
        %% getGlobalParameterValues - Returns global parameters' values.
        %
        % Syntax: out = obj.getGlobalParameterValues;
        %
        % Outputs
        %   out - Numeric. Global parameters' values.
        
            n = obj.getNumberOfGlobalParameters;
            out = map(@obj.getGlobalParameterByIndex, 1:n);
        end
        
        function setGlobalParameterByIndex(obj, index, value)
        %% setGlobalParameterByIndex - Set global parameter's value by index.
        %
        % Syntax: obj.setGlobalParameterByIndex(index, value);
        %
        % Inputs
        %   index - Numeric.
        %   value - Numeric.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'index', @isPositiveIntegerValuedNumeric);
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, index, value);
            obj = p.Results.obj;
            index = p.Results.index;
            value = p.Results.value;  
            % ...input parsed.
        
            check = calllib('roadrunner_c_api', 'setGlobalParameterByIndex', obj.rrcHandler, index - 1, value);                        
            errorId = 'ROADRUNNER:setGlobalParameterByIndexError';                   
            errorMsg = "An error occurred while setting floating species' value";
            assert(check, errorId, errorMsg);       
        end
        
        function setGlobalParameterValues(obj, values)
        %% setGlobalParameterValues - Set global parameters' values.
        %
        % Syntax: obj.setGlobalParameterValues(values);
        %
        % Inputs
        %   values - Numeric.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'values', @isnumeric);

            parse(p, obj, values);
            obj = p.Results.obj;
            values = p.Results.values;
            % ...input parsed.
            
            n = obj.getNumberOfGlobalParameters;
            map(@obj.setGlobalParameterByIndex, 1:n, values);      
        end
        
        function out = getNumberOfCompartments(obj)
        %% getNumberOfCompartments -Returns compartments' count.
        %
        % Syntax: out = obj.getNumberOfCompartments;
        %
        % Outputs
        %   out - Numeric. Number of compartments.
        
            out = calllib('roadrunner_c_api', 'getNumberOfCompartments', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfCompartmentsError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getCompartmentIds(obj)
        %% getCompartmentIds - Get compartments' identifiers.
        %
        % Syntax: out = obj.getCompartmentIds;
        %
        % Outputs
        %    out - String. Compartments' identifiers.        
        
            compartmentIds = calllib('roadrunner_c_api', 'getCompartmentIds', obj.rrcHandler);                              
            errorId = 'ROADRUNNER:getCompartmentIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(compartmentIds), errorId, errorMsg);
            
            out = RoadRunner.stringArrayToString(compartmentIds);
        end
        
        function out = getCompartmentByIndex(obj, index)
        %% getCompartmentByIndex - Returns compartment's size by index.
        %
        % Syntax: out = obj.getCompartmentByIndex(index);
        %
        % Inputs
        %   index - Numeric.
        %
        % Outputs
        %   out - Numeric.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            compartmentPtr = libpointer('doublePtr', NaN);
            check = calllib('roadrunner_c_api', 'getCompartmentByIndex', obj.rrcHandler, index - 1, compartmentPtr);                       
            errorId = 'ROADRUNNER:getCompartmentByIndexError';
            errorMsg = 'An error occurred during method call';                      
            assert(check, errorId, errorMsg);
            
            out = compartmentPtr.Value;
        end
        
        function out = getCompartmentVolumes(obj)
        %% getCompartmentVolumes - Returns compartments' sizes.
        %
        % Syntax: out = obj.getCompartmentVolumes;
        %
        % Outputs
        %   out - Numeric. Compartment sizes.
        
            n = obj.getNumberOfCompartments;
            out = map(@obj.getCompartmentByIndex, 1:n);
        end
        
        function setCompartmentByIndex(obj, index, value)
        %% setCompartmentByIndex - Set compartment's size by index.
        %
        % Syntax: obj.setCompartmentByIndex(index, value);
        %
        % Inputs
        %    index - Numeric.
        %    value - Numeric.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'index', @isPositiveIntegerValuedNumeric);
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, index, value);
            obj = p.Results.obj;
            index = p.Results.index;
            value = p.Results.value;  
            % ...input parsed.
        
            check = calllib('roadrunner_c_api', 'setCompartmentByIndex', obj.rrcHandler, index - 1, value);                        
            errorId = 'ROADRUNNER:setCompartmentByIndexError';
            errorMsg = "An error occurred while setting floating species' value";            
            assert(check, errorId, errorMsg);     
        end
        
        function setCompartmentVolumes(obj, values)
        %% setCompartmentVolumes - Set compartments' sizes.
        %
        % Syntax: obj.setCompartmentVolumes(values);
        %
        % Inputs
        %   values - Numeric.
            
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'values', @isnumeric);

            parse(p, obj, values);
            obj = p.Results.obj;
            values = p.Results.values;
            % ...input parsed.
            
            n = obj.getNumberOfCompartments;
            map(@obj.setCompartmentByIndex, 1:n, values);      
        end        
        
        function out = getNumberOfReactions(obj)
        %% getNumberOfReactions - Get reactions' count.
        %
        % Syntax: out = obj.getNumberOfReactions;
        %
        % Outputs
        %    out - Numeric. Number of reactions.
        
            out = calllib('roadrunner_c_api', 'getNumberOfReactions', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfReactionsError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getReactionIds(obj)
        %% getReactionIds - Returns reactions' identifiers.
        %
        % Syntax: out = obj.getReactionIds;
        %
        % Outputs
        %   out - String. Reactions' identifiers.
        
            reactionIds = calllib('roadrunner_c_api', 'getReactionIds', obj.rrcHandler);                              
            errorId = 'ROADRUNNER:getReactionIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(reactionIds), errorId, errorMsg);
               
            out = RoadRunner.stringArrayToString(reactionIds);
        end
        
        function out = getReactionRateByIndex(obj, index)
        %% getReactionRateByIndex - Returns reaction's rate by index.
        %
        % Syntax: out = obj.getReactionRateByIndex(index);
        %
        % Inputs
        %    index - Numeric.
        %
        % Outputs:
        %   out - Numeric. Reaction rate.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            reactionPtr = libpointer('doublePtr', NaN);            
            check = calllib('roadrunner_c_api', 'getReactionRate', obj.rrcHandler, index - 1, reactionPtr);                       
            errorId = 'ROADRUNNER:getReactionRateError';
            errorMsg = 'An error occurred during method call';
            assert(check, errorId, errorMsg);
            
            out = reactionPtr.Value;
        end
        
        function out = getReactionRates(obj)
        %% getReactionRates - Get reactions' rates.
        %
        % Syntax: out = obj.getReactionRates;
        %
        % Outputs
        %   out - Numeric. Reaction rates.
        
            n = obj.getNumberOfReactions;
            out = map(@obj.getReactionRateByIndex, 1:n);
        end
        
        function out = getRatesOfChangeIds(obj)
        %% getRatesOfChangeIds - Returns rates of change's identifiers.
        %
        % Syntax: out = obj.getRatesOfChangeIds;
        %
        % Outputs
        %    out - String. Rates of change's identifiers.
        
            ratesOfChangeIds = calllib('roadrunner_c_api', 'getRatesOfChangeIds', obj.rrcHandler);                              
            errorId = 'ROADRUNNER:getRatesOfChangeIdsError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(ratesOfChangeIds), errorId, errorMsg);
               
            out = RoadRunner.stringArrayToString(ratesOfChangeIds);        
        end
        
        function out = getRateOfChangeByIndex(obj, index)
        %% getRateOfChangeByIndex - Returns rate of change by index.
        %
        % Syntax: out = obj.getRateOfChange(index);
        %
        % Inputs
        %   index - Numeric. Rate of change's index.
        %
        % Outputs
        %   out - Numeric. Rate of change.            
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Index must be a positive integer';
            assert(isPositiveIntegerValuedNumeric(index), errorId, errorMsg);
            
            rateOfChangePtr = libpointer('doublePtr', NaN);            
            check = calllib('roadrunner_c_api', 'getRateOfChange', obj.rrcHandler, index - 1, rateOfChangePtr);                       
            errorId = 'ROADRUNNER:getRateOfChangeByIndexError';
            errorMsg = 'An error occurred during method call';
            assert(check, errorId, errorMsg);
            
            out = rateOfChangePtr.Value;
        end
        
        function out = getRatesOfChange(obj)
        %% getRatesOfChange - Get rates of change.
        %
        % Syntax: out = obj.getRatesOfChange;
        %
        % Outputs
        %   out - Numeric. Rates of change.
        
            n = obj.getNumberOfFloatingSpecies;
            out = map(@obj.getRateOfChange, 1:n);
        end
        
        function evalModel(obj)
        %% evalModel - Evaluate the current model, updating all assignments 
        % and rates of change. Do not carry out integration step.
        %
        % Syntax: obj.evalModel
        
            check = calllib('roadrunner_c_api', 'evalModel', obj.rrcHandler);            
            errorId = 'ROADRUNNER:evalModelError';
            errorMsg = 'An error occurred while evaluating the model';
            assert(check, errorId, errorMsg);
        end
        
        function out = getTimeStart(obj)
        %% getTimeStart - Get starting time.
        %
        % Syntax: obj.getTimeStart;
        %
        % Outputs
        %   out - Numeric. Simulation's time start.
        
           out = libpointer('doublePtr', NaN);
           check =  calllib('roadrunner_c_api', 'getTimeStart', obj.rrcHandler, out);           
           errorId = 'ROADRUNNER:getTimeStartError';
           errorMsg = 'An error occurred during method call';
           assert(check, errorId, errorMsg);
           
           out = out.Value;
        end
        
        function setTimeStart(obj, timeStart)
        %% setTimeStart - Time course simulation's time start.
        %
        % Syntax: obj.setTimeStart(timeStart);
        %
        % Inputs
        %   timeStart - Numeric.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'timeStart must be a nonnegative number';
            assert(isnumeric(timeStart) && timeStart >= 0, errorId, errorMsg);
               
            check = calllib('roadrunner_c_api', 'setTimeStart', obj.rrcHandler, timeStart);                       
            errorId = 'ROADRUNNER:setTimeStart';
            errorMsg = "An error occurred while setting simulation's time start";
            assert(check, errorId, errorMsg);                
        end    
        
        function out = getTimeEnd(obj)
        %% getTimeEnd - Simulation's end timepoint.
        %
        % Syntax: obj.getTimeEnd;
        %
        % Outputs
        %   out - Numeric. Simulation's end time.
        
           out = libpointer('doublePtr', NaN);
           check =  calllib('roadrunner_c_api', 'getTimeEnd', obj.rrcHandler, out);           
           errorId = 'ROADRUNNER:getTimeEndError';
           errorMsg = 'An error occurred during method call';
           assert(check, errorId, errorMsg);
           
           out = out.value;
        end
        
        function setTimeEnd(obj, timeEnd)
        %% setTimeEnd - Set time course simulation's time end.
        %
        % Syntax: obj.setTimeEnd(timeStart);
        %
        % Inputs
        %    timeEnd - Numeric.            
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'timeEnd must be a nonnegative number';
            assert(isnumeric(timeEnd) && timeEnd >= 0, errorId, errorMsg);
               
            check = calllib('roadrunner_c_api', 'setTimeEnd', obj.rrcHandler, timeEnd);                       
            errorId = 'ROADRUNNER:setTimeEnd';
            errorMsg = "An error occurred while setting simulation's time end";
            assert(check, errorId, errorMsg);                            
        end        
        
        function out = getStepNumber(obj)
        %% getStepNumber - Returns number of simulstion's steps.
        %
        % Syntax: obj.getStepNumber;
        %
        % Outputs
        %    out - Numeric. Number of simulation's steps.
        
           out = libpointer('int32Ptr', 0);
           check =  calllib('roadrunner_c_api', 'getNumPoints', obj.rrcHandler, out);           
           errorId = 'ROADRUNNER:getStepNumberError';
           errorMsg = 'An error occurred during method call';
           assert(check, errorId, errorMsg);
           
           out = out.Value;
        end
        
        function setStepNumber(obj, stepNumber)
        %% setStepNumber - Set time course simulation's step number.
        %
        % Syntax: obj.setStepNumber(timeStart);
        %
        % Inputs
        %   stepNumber - Numeric. Number of simulation's time steps.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'stepNumber must be a nonnegative number';
            assert(isPositiveIntegerValuedNumeric(stepNumber), errorId, errorMsg);
               
            check = calllib('roadrunner_c_api', 'setNumPoints', obj.rrcHandler, stepNumber);                       
            errorId = 'ROADRUNNER:setStepNumberError';
            errorMsg = "An error occurred while setting simulation's step number";
            assert(check, errorId, errorMsg);                           
        end            
        
        function configTimeCourseSimulation(obj, timeStart, timeEnd, varargin)
        %% configTimeCourseSimulation - Configure time course simulation.
        %
        % Syntax: obj.configTimeCourseSimulation(timeStart, timeEnd, stepNumber);
        %
        % Inputs
        %   timeStart - Numeric.
        %   timeEnd - Numeric.
        %   variableStepSize - Optional. Logical. Defaults to true.
        %   stepNumber - Optional. Numeric. Defaults to 50.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'timeStart', @isnumeric);
            addRequired(p, 'timeEnd', @isnumeric);
            addOptional(p, 'variableStepSize', true, @islogical);            
            addOptional(p, 'stepNumber', 50, @isPositiveIntegerValuedNumeric);
            
            parse(p, obj, timeStart, timeEnd, varargin{:});
            obj = p.Results.obj;
            timeStart = p.Results.timeStart;
            timeEnd = p.Results.timeEnd;
            variableStepSize = p.Results.variableStepSize;            
            stepNumber = p.Results.stepNumber;   
            % ...input parsed.
            
            tmpNames = obj.getListOfIntegratorParameterNames;
            if ismember('variable_step_size', tmpNames)
                 obj.setIntegratorParameterByName('variable_step_size', variableStepSize);
            end
            
            if variableStepSize, stepNumber = 1; end
            
            obj.setTimeStart(timeStart);
            obj.setTimeEnd(timeEnd);
            obj.setStepNumber(stepNumber);         
        end
        
        function [t, x] = simulate(obj)
        %% simulate - Carry out a time-course simulation. Simulation settings 
        % must be set before with configTimeCourseSimulation method.
        %
        % Syntax: obj.simulate;
        %
        % Outputs
        %   t - Numeric. Simulation times.
        %   x - Numeric. Species' concentrations for each simulation time. 
        
            tmpData = calllib('roadrunner_c_api', 'simulate', obj.rrcHandler);            
            errorId = 'ROADRUNNER:simulateError';
            errorMsg = 'An error occurred while simulating the model';     
            assert(~isNull(tmpData), errorId, errorMsg);
            
            tmpData = RoadRunner.dataPtrToDouble(tmpData);            
            t = tmpData(:, 1);
            x = tmpData(:, 2:end);
        end
        
        function [t, x] = getSimulationResult(obj)
        %% getSimulationResult - Returns the result of the last simulation.
        %
        % Syntax: [t, x] = obj.getSimulationResult;
        %
        % Outputs
        %   t - Numeric. Simulation's times.
        %   x - Numeric. Species concentrations' for each simulation time.
        
            tmpData = calllib('roadrunner_c_api', 'getSimulationResult', obj.rrcHandler);
                          
            errorId = 'ROADRUNNER:getSimulationResultError';
            errorMsg = "An error occurred while getting last simulation's results";
            assert(~isNull(tmpData), errorId, errorMsg);
                          
            tmpData = RoadRunner.dataPtrToDouble(tmpData);            
            t = tmpData(:, 1);
            x = tmpData(:, 2:end);                          
        end
        
        function reset(obj)
        %% reset - Resets all variables of the model to their initial 
        % values. Does not change the parameters.
        %
        % Syntax: obj.reset;
        
            check = calllib('roadrunner_c_api', 'reset', obj.rrcHandler);            
            errorId = 'ROADRUNNER:resetError';
            errorMsg = 'An error occurred while reseting the model';
            assert(check, errorId, errorMsg);
        end
        
        function resetAll(obj)
        %% resetAll - Resets all variables and parameters to their original values.
        %
        % Syntax: obj.resetAll
        
            check = calllib('roadrunner_c_api', 'resetAll', obj.rrcHandler);            
            errorId = 'ROADRUNNER:resetAllError';
            errorMsg = 'An error occurred while reseting the model';
            assert(check, errorId, errorMsg);            
        end
        
        function resetToOrigin(obj)
        %% resetToOrigin - Resets the model to the state in which it was first 
        % loaded, including initial conditions, variables, and parameters.
        %
        % Syntax: obj.resetToOrigin;       
        
            check = calllib('roadrunner_c_api', 'resetToOrigin', obj.rrcHandler);            
            errorId = 'ROADRUNNER:resetToOriginError';
            errorMsg = 'An error occurred while reseting the model';
            assert(check, errorId, errorMsg);              
        end
        
        function out = getIntegratorName(obj)
        %% getIntegratorName - Returns current integrator's name.
        %
        % Syntax: obj.getIntegratorName;        
        
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorName', obj.rrcHandler);            
            errorId = 'ROADRUNNER:getIntegratorNameError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
            
            out = string(out);
        end
        
        function out = getIntegratorParameterDescription(obj, parameterName)
        %% getIntegratorParameterDescription - Get the description for a 
        % specific integrator's setting.
        %
        % Syntax: obj.getIntegratorParameterDescription(parameterName);
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs
        %   out - String. Integrator's parameter description.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);           
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterDescription', obj.rrcHandler, ...
                          parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterDescriptionError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
        end        
        
        function out = getIntegratorParameterHint(obj, parameterName)
        %% getIntegratorParameterHint - Get the hint for a specific integrator's
        % setting.
        %
        % Syntax: obj.getIntegratorParameterHint(parameterName)
        %
        % Inputs
        %   parameterName - String type. Integrator's parameter name.
        %
        % Outputs
        %   out - String. Integrator's parameter hint.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);        

            parameterName = char(parameterName);               
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterHint', obj.rrcHandler, parameterName);
            errorId = 'ROADRUNNER:getIntegratorParameterHintError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
            
            out = string(out);
        end
        
        function out = getIntegratorParameterByName(obj, parameterName)
        %% getIntegratorParameterByName - Returns integrator's parameter value by 
        % name.
        %
        % Syntax: out = obj.getIntegratorParameterByName(parameterName);
        %
        % Inputs
        %   parameterName - String type. Integrator's parameter name.
        %
        % Outputs
        %   out - Parameter value.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);
               
            nParameterName = obj.getListOfIntegratorParameterNames;            
            errorId = 'ROADRUNNER:getIntegratorParameterByNameError';
            errorMsg = 'Wrong parameter name';
            assert(ismember(parameterName, nParameterName), errorId, errorMsg);
            
            parameterType = obj.getIntegratorParameterType(parameterName);
            if parameterType == 0
                out = obj.getIntegratorParameterString(parameterName);
            elseif parameterType == 1
                out = obj.getIntegratorParameterBoolean(parameterName);
            elseif parameterType == 2
                out = obj.getIntegratorParameterInt(parameterName);
            elseif parameterType == 3
                out = obj.getIntegratorParameterUint(parameterName);                    
            elseif parameterType == 4
                out = obj.getIntegratorParameterUint(parameterName);                     
            elseif parameterType == 5
                out = obj.getIntegratorParameterUint(parameterName);                    
            elseif parameterType == 6
                out = obj.getIntegratorParameterDouble(parameterName);                    
            elseif parameterType == 7
                out = obj.getIntegratorParameterDouble(parameterName);                     
            elseif parameterType == 8
                out = obj.getIntegratorParameterString(parameterName);                    
            elseif parameterType == 9
                out = obj.getIntegratorParameterString(parameterName);                    
            elseif parameterType == 10
                out = [];
            else
                errorId = 'ROADRUNNER:getIntegratorParameterByNameError';
                errorMsg = 'Wrong parameter type';
                error(errorId, errorMsg);
            end
        end
        
        function out = setIntegratorParameterByName(obj, parameterName, value)
        %% setIntegratorParameterByName - Set integrator's parameter value by 
        % name.
        %
        % Syntax: obj.setIntegratorParameterByName(parameterName, value);
        %
        % Inputs
        %   parameterName - String type. Integrator's parameter name.
        %   value - Parameter value.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);
               
            nParameterName = obj.getListOfIntegratorParameterNames;            
            errorId = 'ROADRUNNER:setIntegratorParameterByNameError';
            errorMsg = 'Wrong parameter name';
            assert(ismember(parameterName, nParameterName), errorId, errorMsg);
            
            parameterType = obj.getIntegratorParameterType(parameterName);
            if parameterType == 0
                obj.setIntegratorParameterString(parameterName, value);
            elseif parameterType == 1
                obj.setIntegratorParameterBoolean(parameterName, value);
            elseif parameterType == 2
                obj.setIntegratorParameterInt(parameterName, value);
            elseif parameterType == 3
                obj.setIntegratorParameterUint(parameterName, value);                    
            elseif parameterType == 4
                obj.setIntegratorParameterUint(parameterName, value);                     
            elseif parameterType == 5
                obj.setIntegratorParameterUint(parameterName, value);                    
            elseif parameterType == 6
                obj.setIntegratorParameterDouble(parameterName, value);                    
            elseif parameterType == 7
                obj.setIntegratorParameterDouble(parameterName, value);                     
            elseif parameterType == 8
                obj.setIntegratorParameterString(parameterName, value);                    
            elseif parameterType == 9
                obj.setIntegratorParameterString(parameterName, value);                    
            elseif parameterType == 10
                out = [];
            else
                errorId = 'ROADRUNNER:setIntegratorParameterByNameError';
                errorMsg = 'Wrong parameter type';
                error(errorId, errorMsg);
            end
        end
        
        function resetIntegratorParameters(obj)
        %% resetIntegratorParameters - Reset integrator's parameters to their 
        % default values.
        %
        % Syntax: obj.resetIntegratorParameters;
        
            out = calllib('roadrunner_c_api', 'resetCurrentIntegratorParameters', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:resetIntegratorParametersError';
            errorMsg = 'An error occurred while reseting integrator parameters';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function displayIntegratorInfo(obj)
        %% displayIntegratorInfo - Display information about current integrator
        % and its adjustable parameters.
        %
        % Syntax: obj.displayIntegratorInfo;
        
            tmpString = " <Roadrunner Integrator>\n";        
            tmpString = tmpString + " name: " + obj.getIntegratorName + "\n";
            tmpString = tmpString + " settings:";
            
            nParameterName = obj.getListOfIntegratorParameterNames;            
            for i = 1:numel(nParameterName)
                iName = nParameterName(i);
                iValue = string(obj.getIntegratorParameterByName(iName));
                
                stringFormat = '\n\t%s: %s';
                tmpString = tmpString + sprintf(stringFormat, iName, iValue);                
            end
            
            fprintf(tmpString + "\n");
        end        
    end
    
    methods (Access = private)
        function loadRoadRunnerSharedLibrary(obj)
        %% loadRoadRunnerSharedLibrary - Load Roadrunner C API as a MATLAB
        % shared library and set isRRLibLoaded flag to true if no error
        % occurs.
        %
        % Syntax: obj.loadRoadRunnerSharedLibrary;        
        
            if ~libisloaded('roadrunner_c_api')
                warning('off', 'all')                
                loadlibrary('roadrunner_c_api', 'rrc_api', 'addheader', 'rrc_types', 'addheader', 'rrc_utilities');                
                warning('on', 'all')
            end
            
            obj.isRRLibLoaded = true;
        end
        
        function createRRInstance(obj)
        %% createRRInstance - Create an instance of roadrunner and set 
        % isRRCHandler flag to true if no error occurs.
        %
        % Syntax: obj.createRRInstance;            
        
            errorId = 'ROADRUNNER:RrcLibNotLoadedError';
            errorMsg = 'Roadrunner library must be loaded before method call';
            assert(obj.isRRLibLoaded, errorId, errorMsg);
            
            obj.rrcHandler = calllib('roadrunner_c_api', 'createRRInstance');            
            errorId = 'ROADRUNNER:NullPointerError';
            errorMsg = 'An error occurred while creating an rrcHandler instance';
            assert(~isNull(obj.rrcHandler), errorId, errorMsg);
            
            obj.isRRCHandler = true;                      
        end
        
        function loadSBMLFromFile(obj, sbmlPath)
        %% loadSBMLFromFile - Load a model from a SBML file.
        %
        % Syntax: obj.loadSBMLFromFile;            
        
            errorId = 'ROADRUNNER:RrcLibNotLoadedError';
            errorMsg = 'Roadrunner library must be loaded before method call';
            assert(obj.isRRLibLoaded, errorId, errorMsg);        
            
            check = calllib('roadrunner_c_api', 'loadSBMLFromFile', obj.rrcHandler, sbmlPath);                       
            errorId = 'ROADRUNNER:SbmlLoadError';
            errorMsg = 'An error occurred while loading the SBML model';
            assert(check, errorId, errorMsg);
            
            obj.isSBMLLoaded = true;                 
        end
        
        function out = getIntegratorDescription(obj)
        %% getIntegratorDescription - Obtain a description of the current 
        % integrator.
        %
        % Syntax: out = obj.getIntegratorDescription;
        %
        % Outputs
        %   out - String. Integrator description.
        
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorDescription', obj.rrcHandler);            
            errorId = 'ROADRUNNER:getIntegratorDescriptionError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
            
            out = string(out);
        end
        
        function out = getIntegratorHint(obj)
        %% getIntegratorHint - Obtain a hint of the current integrator.
        %
        % Syntax: out = obj.getIntegratorHint;
        %
        % Outputs
        %   out - String. Integrator hint.
        
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorHint', obj.rrcHandler);            
            errorId = 'ROADRUNNER:getIntegratorHintError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
            
            out = string(out);
        end        
        
        function out = getNumberOfIntegratorParameters(obj)
        %% getNumberOfIntegratorParameters - Get the number of adjustable 
        % parameters for the current integrator.
        %
        % Syntax: obj.getNumberOfCurrentIntegratorParameters
        %
        % Outputs
        %   out - Numeric. Number of current integrator's adjustable settings.        
        
            out = calllib('roadrunner_c_api', 'getNumberOfCurrentIntegratorParameters', obj.rrcHandler);                      
            errorId = 'ROADRUNNER:getNumberOfIntegratorParametersError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function out = getListOfIntegratorParameterNames(obj)
        %% getListOfIntegratorParameterNames - Get the names of adjustable 
        % parameters for the current integrator.
        %
        % Syntax: obj.getListOfIntegratorParameterNames;
        %
        % Outputs
        %   out - String. Integrator parameters names.
        
            intParPtr = calllib('roadrunner_c_api', 'getListOfCurrentIntegratorParameterNames', obj.rrcHandler);            
            errorId = 'ROADRUNNER:getListOfIntegratorParameterNamesError';
            errorMsg = 'An error occurred during method call';
            assert(~isNull(intParPtr), errorId, errorMsg);              
               
            out = obj.stringArrayToString(intParPtr);
        end
        
        function out = getIntegratorParameterType(obj, parameterName)
        %% getIntegratorParameterType - Get the type for a specific integrator 
        % parameter.
        %
        % Syntax: obj.getIntegratorParameterType(parameterName)
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs
        %   out - String. Integrator parameter type.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);        
            
            parameterName = char(parameterName);
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterType', obj.rrcHandler, parameterName);                      
            errorId = 'ROADRUNNER:getIntegratorParameterTypeError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);    
        end
        
        function out = getIntegratorParameterInt(obj, parameterName)
        %% getIntegratorParameterInt - Get integer value for a specific 
        % integrator parameter.
        %
        % Syntax: out = obj.getIntegratorParameterInt(parameterName);
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs
        %    out - Numeric. Integer value for specified integrator's parameter.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);                   
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterInt', obj.rrcHandler, parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterIntError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function setIntegratorParameterInt(obj, parameterName, value)
        %% setIntegratorParameterInt - Set integrator's parameter integer value.
        %
        % Syntax: obj.setIntegratorParameterInt(parameterName, value);
        %
        % Inputs
        %   parameterName - String type.
        %   value - Numeric. Integer value of integrator's parameter.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'parameterName', @(x) ischar(x) || isstring(x));
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, parameterName, value);
            obj = p.Results.obj;
            parameterName = char(p.Results.parameterName);
            value = int32(p.Results.value);  
            % ...input parsed
            
            out = calllib('roadrunner_c_api', 'setCurrentIntegratorParameterInt', obj.rrcHandler, parameterName, value);            
            errorId = 'ROADRUNNER:setIntegratorParameterIntError';
            errorMsg = 'An error occurred during method call';
            assert(out == 1, errorId, errorMsg);            
        end
        
        function out = getIntegratorParameterUint(obj, parameterName)
        %% getIntegratorParameterUint - Get unsigned integer value for a 
        % integrator setting.
        %
        % Syntax: out = obj.getIntegratorParameterUint(parameterName);
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs:
        %    out - Numeric. Unsigned integer value for specified integrator's 
        %          setting.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);                   
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterUint', obj.rrcHandler, parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterUintError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function setIntegratorParameterUint(obj, parameterName, value)
        %% setIntegratorParameterUint - Set unsigned integer value for a 
        % integrator's parameter.
        %
        % Syntax: obj.setIntegratorParameterUint(parameterName, value);
        %
        % Inputs
        %   parameterName - String type.
        %   value - Numeric. Unsigned integer value of integrator's parameter.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'parameterName', @(x) ischar(x) || isstring(x));
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, parameterName, value);
            obj = p.Results.obj;
            parameterName = char(p.Results.parameterName);
            value = uint32(p.Results.value);  
            % ...input parsed
            
            out = calllib('roadrunner_c_api', 'setCurrentIntegratorParameterUint', obj.rrcHandler, parameterName, ...
                          value);            
            errorId = 'ROADRUNNER:setIntegratorParameterUintError';
            errorMsg = 'An error occurred during method call';
            assert(out == 1, errorId, errorMsg);            
        end
        
        function out = getIntegratorParameterDouble(obj, parameterName)
        %% getIntegratorParameterDouble - Get double value for a integrator's 
        % parameter.
        %
        % Syntax: out = obj.getIntegratorParameterDouble(parameterName);
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs
        %   out - Numeric. Double value for integrator parameter.
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);                   
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterDouble', obj.rrcHandler, parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterDoubleError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
        end
        
        function setIntegratorParameterDouble(obj, parameterName, value)
        %% setIntegratorParameterDouble - Set double value for a integrator's 
        % parameter.
        %
        % Syntax: obj.setIntegratorParameterDouble(parameterName, value);
        %
        % Inputs
        %   parameterName - String type.
        %   value - Numeric. Double value of integrator parameter.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'parameterName', @(x) ischar(x) || isstring(x));
            addRequired(p, 'value', @isnumeric);

            parse(p, obj, parameterName, value);
            obj = p.Results.obj;
            parameterName = char(p.Results.parameterName);
            value = double(p.Results.value);  
            % ...input parsed
            
            out = calllib('roadrunner_c_api', 'setCurrentIntegratorParameterDouble', obj.rrcHandler, parameterName, ...
                          value);            
            errorId = 'ROADRUNNER:setIntegratorParameterDoubleError';
            errorMsg = 'An error occurred during method call';
            assert(out == 1, errorId, errorMsg);            
        end
        
        function out = getIntegratorParameterString(obj, parameterName)
        %% getIntegratorParameterString - Get string value for a integrator's
        % parameter.
        %
        % Syntax: out = obj.getIntegratorParameterString(parameterName);
        %
        % Inputs
        %   parameterName - String type.
        %
        % Outputs:
        %    out - String. String value for specified integrator's parameter.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);                   
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterString', obj.rrcHandler, parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterStringError';
            errorMsg = 'An error occurred during method call';
            assert(~isemptyExt(out), errorId, errorMsg);
            
            out = string(out);
        end
        
        function setIntegratorParameterString(obj, parameterName, value)
        %% setIntegratorParameterString - Set string value for a integrator's 
        % parameter.
        %
        % Syntax: obj.setIntegratorParameterString(parameterName, value);
        %
        % Inputs
        %   parameterName - String type.
        %   value - String.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'parameterName', @(x) ischar(x) || isstring(x));
            addRequired(p, 'value', @(x) ischar(x) || isstring(x));

            parse(p, obj, parameterName, value);
            obj = p.Results.obj;
            parameterName = char(p.Results.parameterName);
            value = char(p.Results.value);  
            % ...input parsed
            
            out = calllib('roadrunner_c_api', 'setCurrentIntegratorParameterDouble', obj.rrcHandler, parameterName, ...
                          value);
            
            errorId = 'ROADRUNNER:setIntegratorParameterStringError';
            errorMsg = 'An error occurred during method call';
            assert(out == 1, errorId, errorMsg);            
        end
        
        function out = getIntegratorParameterBoolean(obj, parameterName)
        %% getIntegratorParameterBoolean - Get boolean value for a integrator's
        % parameter.
        %
        % Syntax: out = obj.getIntegratorParameterBoolean(parameterName);
        %
        % Inputs:
        %   parameterName - String type.
        %
        % Outputs
        %   out - Logical. Boolean value for integrator's parameter.        
        
            errorId = 'ROADRUNNER:WrongInputTypeError';
            errorMsg = 'Input must be "string" or "char"';
            assert(isStringType(parameterName), errorId, errorMsg);

            parameterName = char(parameterName);                   
            out = calllib('roadrunner_c_api', 'getCurrentIntegratorParameterBoolean', obj.rrcHandler, parameterName);            
            errorId = 'ROADRUNNER:getIntegratorParameterBooleanError';
            errorMsg = 'An error occurred during method call';
            assert(out >= 0, errorId, errorMsg);
            
            out = logical(out);
        end
        
        function setIntegratorParameterBoolean(obj, parameterName, value)
        %% setIntegratorParameterBoolean - Set boolean value for a integrator's 
        % parameter.
        %
        % Syntax: obj.setIntegratorParameterBoolean(parameterName, value);
        %
        % Inputs
        %   parameterName - String type.
        %   value - Logical.
        
            % Parse input...
            p = inputParser;

            addRequired(p, 'obj', @RoadRunner.isRoadRunner);
            addRequired(p, 'parameterName', @(x) ischar(x) || isstring(x));
            addRequired(p, 'value', @(x) isnumeric(x) || islogical(x));

            parse(p, obj, parameterName, value);
            obj = p.Results.obj;
            parameterName = char(p.Results.parameterName);
            value = logical(p.Results.value);  
            % ...input parsed
            
            out = calllib('roadrunner_c_api', 'setCurrentIntegratorParameterBoolean', obj.rrcHandler, parameterName, ...
                          value);            
            errorId = 'ROADRUNNER:setIntegratorParameterBooleanError';
            errorMsg = 'An error occurred during method call';
            assert(out == 1, errorId, errorMsg);            
        end            
    end   
 
    methods (Static)
% STATIC METHODS
        function out = stringArrayToString(input)
        %% stringArrayToString - Returns a string list in string form.
        %
        % Syntax: out = obj.stringArrayToString(input);
        %
        % Inputs
        %   input - RRStringArrayPtr. Roadrunner's string list.
        %
        % Outputs
        %   out - String. Input converted to MATLAB string type.
        
            errorId = 'ROADRUNNER:RrcLibNotLoadedError';
            errorMsg = 'Roadrunner library must be loaded before method call';
            assert(libisloaded('roadrunner_c_api'), errorId, errorMsg);

            n = input.Value.Count;
            out = strings(1, n);
            for i = 1:n
                out(i) = calllib('roadrunner_c_api', 'getStringElement', input, i - 1);
            end

            errorId = 'ROADRUNNER:GetStringElementError';
            errorMsg = 'An error occurred while accessing a string array element';
            assert(~any(strcmp("", out)), errorId, errorMsg);

            check = calllib('roadrunner_c_api', 'freeStringArray', input);
            errorId = 'ROADRUNNER:stringArrayToStringError';
            errorMsg = 'An error occurred while freeing a string list';
            assert(check == 1, errorId, errorMsg);
        end

        function out = dataPtrToDouble(input)
        %% dataPtrToDouble - Convert a RRCDataPtr struct to a MATLAB 
        % double array.
        %
        % Syntax: out = dataPtrToDouble(input);
        %
        % Inputs
        %   input - RRCDataPtr. Roadrunner RRCDataPtr struct.
        %
        % Outputs
        %   out - Numeric. Input converted to MATLAB double type.
        
            errorId = 'ROADRUNNER:RrcLibNotLoadedError';
            errorMsg = 'Roadrunner library must be loaded before method call';
            assert(libisloaded('roadrunner_c_api'), errorId, errorMsg);

            nRows = calllib('roadrunner_c_api', 'getRRDataNumRows', input);
            nColumns = calllib('roadrunner_c_api', 'getRRDataNumCols', input);                             

            out = input.Value.Data;
            setdatatype(out, 'doublePtr', nColumns, nRows);
            out = transpose(out.Value);

            check = calllib('roadrunner_c_api', 'freeRRCData', input);
            errorId = 'ROADRUNNER:dataPtrToDouble';
            errorMsg = 'An error occurred while freeing a data struct';
            assert(check == 1, errorId, errorMsg);   
        end

        function out = isRoadRunner(input)
        %% isRoadRunner - True if input argument is a RoadRunner object.
        %
        % Syntax: RoadRunner.isRoadRunner(input)
        %
        % Inputs
        %   input - Any object.
        %
        % Outputs
        %   out - Logical. True if input argument is an instance of RoadRunner
        %         class, else false.
            out = isa(input, 'RoadRunner');
        end
    end    
% ------------- END OF CODE --------------
end