classdef SbmlExt < matlab.mixin.Copyable
%% SbmlExt - Stores data as key-value pairs.
%
% Properties
%	CurrentSbmlModel - libSBML structure. Current SBML model.
%	sIds - Dict. SbmlExt namespace (element sId - element type) dictionary.
%   functionDefinition - Dict. Function definitions (function
%                        definition id - anonymous function) dictionary.
%   initialAssignment - Dict. Initial assignments (element sId - assignment 
%                       expression) dictionary.
%   assignmentRule - Dict. Assignment rules (element sId - assignment 
%                    expression) dictionary.
%   rateRule - Dict. Rate rules (element sId - assignment expression) 
%              dictionary.
%   compartment - Dict. Compartments (compartment sId - compartment structure)
%                 dictionary.
%   parameter - Dict. Parameters (parameter sId - parameter structure)
%               dictionary.
%   species - Dict. Species (species sId - species structure) dictionary.
%   dxdt - Dict. ODEs (species sId - ODE expression) dictionary.
%
% Object Methods
%	isElementBySId - Check if element with given sId is in current model.
%	getElementBySId - Get current model element by sId.
%   setInitialAssignment - Set current model element by sId.
%   getX0 - Returns model free species initial quantities.
%   getInitialAssignmentStruct - Get initial assignment libSBML structure from 
%                                current model by target element sId.
%   setInitialAssignment - Set current model initial assignment.
%   applyInitialAssignments - Apply initial assignments to current model.
%   getAssignmentRuleStruct - Get assignment rule libSBML structure from current 
%                             model by target element sId.
%   setAssignmentRule - Set current model assignment rule.
%   applyAssignmentRules - Apply assignment rules to current model.
%   updateCurrentSbmlModel - Updates current SBML model libSBML structure.
%   getDynamicsString - Returns dynamics parsed for current model as strings.
%
% Static Methods
%   isSbmlExt - Check if input argument is a SbmlExt object.
%
% Other m-files: auxiliar/isemptyExt.m, auxiliar/map.m, auxiliar/isStringType.m
%                auxiliar/mathReplace
% Subfunctions: none
% MAT-files required: none
%
% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 16-May-2020
%% ------------- BEGIN CODE --------------

% PROPERTIES
    properties (Access = private)
        reactant Dict = Dict.empty;
        product Dict = Dict.empty;
        reaction Dict = Dict.empty;
        SbmlModel struct = struct.empty;
    end

    properties (SetAccess = public)
        CurrentSbmlModel struct = struct.empty;
        
        sIds Dict = Dict;                
        
        functionDefinition Dict = Dict.empty;        
        initialAssignment Dict = Dict.empty;
        assignmentRule Dict = Dict.empty;
        rateRule Dict = Dict.empty;
        
        compartment Dict = Dict.empty;
        parameter Dict = Dict.empty;        
        species Dict = Dict.empty;
        
        dxdt Dict = Dict.empty;
    end
    
    methods
% OBJECT METHODS        
        function obj = SbmlExt(sbmlOrPath, varargin)
        %% Constructor for SbmlExt.

            % Parse input...
            p = inputParser;

            addRequired(p, 'sbmlOrPath', @(x) isStringType(x) || isstruct(x));
            addOptional(p, 'modelName', string.empty ,@isStringType);

            parse(p, sbmlOrPath, varargin{:});
            sbmlOrPath = p.Results.sbmlOrPath;
            modelName = char(p.Results.modelName);
            % ...input parsed
            
            % Load SBML model from file.
            if isstruct(sbmlOrPath)
                obj.SbmlModel = sbmlOrPath;
            else
                if ~isemptyExt(modelName)
                    sbmlOrPath = fullfile(char(sbmlOrPath), [modelName '.xml']);
                end
                
                check = isfile(sbmlOrPath);
                errorId = 'SBMLEXT:FileNotFoundError';
                errorMsg = 'No such file or directory';
                assert(check, errorId, errorMsg);

                obj.SbmlModel = TranslateSBML(sbmlOrPath);
            end
            
            % Init current SBML model.
            obj.CurrentSbmlModel = obj.SbmlModel;            
            % Load sIds namespace.
            obj.sIds = Dict;            
            % Load functions definitions.
            obj.getFunctionsDefinition;            
            % Load initial assignments.
            obj.getInitialAssignments;            
            % Load assignment rules.
            obj.getAssignmentRules;
            % Load rate rules.
            obj.getRateRules;     
            % Load compartments.
            obj.getCompartments;   
            % Load parameters.
            obj.getParameters;  
            % Load species.
            obj.getSpecies;    
            % Load reactions.
            obj.getReactions; 
            % Load ODEs
            obj.getODEs;
        end
        
        function saveCurrentModel(obj, path)
            errorId = 'SAVECURRENTMODEL:WrongInputError';
            errorMsg = 'Input must be a char or a string';
            assert(isStringType(path), errorId, errorMsg);
            
            OutputSBML(obj.CurrentSbmlModel, path)
        end
        
        function out = isElementBySId(obj, elementSId)
        %% isElementBySId - Check if element with given sId is in current model.
        %
        % Syntax: out = isElementBySId(obj, elementSId);
        %
        % Inputs
        %	elementSId - String type. Element sId.
        %
        % Outputs
        %	out - Logical. True if element is in model, else false.            
            errorId = 'ISELEMENTBYSID:WrongInputError';
            errorMsg = 'Input must be a char or a string';
            assert(isStringType(elementSId), errorId, errorMsg);
            
            if ismember(elementSId, obj.sIds.keys)
            	out = true; 
            else
            	out = false;
            end
        end
        
        function out = getElementBySId(obj, sId)
        %% getElementBySId - Get current model element by sId.
        %
        % Syntax: out = obj.getCurrentElementBySId(sId);
        %
        % Inputs
        %	sId - String type. Model element identifier.
        %
        % Outputs
        %	out - Any type. Model element.        
            errorId = 'GETELEMENTBYSID:WrongInputError';
            errorMsg = 'Input must be a char or a string';
            assert(isStringType(sId), errorId, errorMsg);
            
            errorId = 'GETELEMENTBYSID:ElementNotFoundError';
            errorMsg = 'Element "%s" is not in current model';
            assert(ismember(sId, obj.sIds.keys), errorId, errorMsg, sId);
            
            propertyField = obj.sIds(sId);
            property = obj.(propertyField);
            
            if ismember(propertyField, ["reactant" "product"])
                for i = property.keys
                   reactOrProdDict = property(i);
                   if ismember(sId, reactOrProdDict.keys)
                       out = reactOrProdDict(sId);
                       return;
                   end
                end
            else             
                out = property(sId);
            end
        end
        
        function setElementBySId(obj, sId, value)
        %% setElementBySId - Set current model element by sId.
        %
        % Syntax: out = obj.setCurrentElementBySId(sId);
        %
        % Inputs
        %	sId - String type. Model element identifier.
        %	value - Any type. Model element value.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'sId', @isStringType);
            addRequired(p, 'value', @(x) isStringType(x) || isnumeric(x));
            
            parse(p, obj, sId, value);
            obj = p.Results.obj;
            sId = p.Results.sId;
            value = p.Results.value;
            % ...input parsed
            
            errorId = 'SETELEMENTBYSID:ElementNotFoundError';
            errorMsg = 'Element "%s" is not in current model';
            assert(ismember(sId, obj.sIds.keys), errorId, errorMsg, sId);            
            
            propertyField = obj.sIds(sId);
            
            if ismember(propertyField, ["reaction", "functionDefinition"])
                return;
            end
            
            property = obj.(propertyField);
            
            if ismember(propertyField, ["reactant" "product"])
                for i = property.keys
                   reactOrProdDict = property(i);
                   if ismember(sId, reactOrProdDict.keys)
                       element = reactOrProdDict(sId);
                       element.value = value;
                       reactOrProdDict(sId) = element;
                       return;
                   end
                end                
            else          
                element = property(sId);
                element.value = value;
                property(sId) = element;
            end
        end
        
        function out = getX0(obj)
        %% getX0 - Returns model free species initial quantities.
        %
        % Syntax: obj.getX0;
        %
        % Outputs
        %   out - Numeric. Free species initial quantities.
            out = [];
            for i = obj.species.keys
                speciesStruct = obj.species(i);
                check = speciesStruct.isConstant || speciesStruct.isBoundary;
                if ~check, out = vertcat(out, speciesStruct.value); end
            end            
        end
        
        function out = getInitialAssignmentStruct(obj, symbol)
        %% getInitialAssignmentStruct - Get initial assignment libSBML structure 
        % from current model by target element sId.
        %
        % Syntax: obj.getInitialAssignmentStruct(symbol);
        %
        % Inputs
        %	symbol - String type. sId of current model element targeted by an 
        %            initial assignment.
        %
        % Outputs
        %	out - Structure. Initial assignment targeting symbol argument.
            check = ismember(symbol, obj.initialAssignment.keys);
            errorId = 'GETINITIALASSIGNMENTSTRUCT:ElementNotFoundError';
            errorMsg = "Element '%s' is not a target of any initial " + ...
                       "assignment in current model";
            assert(check, errorId, errorMsg, symbol);
            
            symbolMask = strcmp(symbol, obj.initialAssignment.keys);
            out = obj.CurrentSbmlModel.initialAssignment(symbolMask);
        end
        
        function setInitialAssignment(obj, symbol, expression)
        %% setInitialAssignment - Set current model initial assignment.
        %
        % Syntax: obj.setInitialAssignment(symbol, expression);
        %
        % Inputs
        %	symbol - String type. Model element identifier.
        %	expression - String type or numeric. Assignment.
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'symbol', @isStringType);
            addRequired(p, 'expression', @(x) isStringType(x) || isnumeric(x));
                    
            parse(p, obj, symbol, expression);
            obj = p.Results.obj;
            symbol = p.Results.symbol;
            expression = num2str(p.Results.expression);            
            % ...input parsed
            
            check = ismember(symbol, obj.sIds.keys);
            errorId = 'SETINITIALASSIGNMENT:ElementNotFoundError';
            errorMsg = 'Element "%s" is not in current model';
            assert(check, errorId, errorMsg, symbol);
            
            obj.initialAssignment(symbol) = expression;
        end
        
        function applyInitialAssignments(obj)
        %% applyInitialAssignment - Apply initial assignments to current model.
        %
        % Syntax: obj.applyInitialAssignments;      
            if isempty(obj.initialAssignment), return; end
            
            for i = obj.initialAssignment.keys
                check = ismember(i, obj.sIds.keys);
                errorId = 'APPLYINITIALASSIGNMENTS:WrongSymbolError';
                errorMsg = 'Target symbol not in current model';
                assert(check, errorId, errorMsg);
                
                formula = obj.parseConstantElements(obj.initialAssignment(i));
                formula = obj.parseVariableElements(formula, true);
                formula = obj.evalFormula(formula);
                
                obj.setElementBySId(i, formula);                
            end
        end
        
        function out = getAssignmentRuleStruct(obj, variable)
        %% getAssignmentRuleStruct - Get assignment rule libSBML structure from 
        % current model by target element sId.
        %
        % Syntax: obj.getAssignmentRuleStruct(symbol);
        %
        % Inputs
        %	variable - String type. sId of current model element targeted by an 
        %              assignment rule.
        %
        % Outputs
        %	out - Structure. Assignment rule targeting variable argument.
            check = ismember(variable, obj.assignmentRule.keys);
            errorId = 'GETASSIGNMENTRULESTRUCT:ElementNotFoundError';
            errorMsg = "Element '%s' is not a target of any assignment " + ...
                       "rule in current model";
            assert(check, errorId, errorMsg, variable);
            
            variableMask = strcmp(variable, obj.assignmentRule.keys);      
            out = obj.CurrentSbmlModel.rule(variableMask);
        end        
        
        function setAssignmentRule(obj, variable, expression)
        %% setAssignmentRule - Set current model assignment rule.
        %
        % Syntax: obj.setAssignmentRule(variable, expression);
        %
        % Inputs
        %	variable - String type. SBML model element identifier.
        %	expression - String type or numeric. Assignment.
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'variable', @isStringType);
            addRequired(p, 'expression', @(x) isStringType(x) || isnumeric(x));
                    
            parse(p, obj, variable, expression);
            obj = p.Results.obj;
            variable = p.Results.variable;
            expression = num2str(p.Results.expression);            
            % ...input parsed
            
            test = ismember(variable, obj.sIds.keys);
            errorId = 'SETASSIGNMENTRULE:ElementNotFoundError';
            errorMsg = 'Element "%s" is not in current SBML model';
            assert(test, errorId, errorMsg, variable);
            
            obj.assignmentRule(variable) = expression;
        end
        
        function applyAssignmentRules(obj)
        %% applyAssignmentRules - Apply assignment rules to current model.
        %
        % Syntax: obj.applyAssignmentRules;      
            if isempty(obj.assignmentRule), return; end
            
            for i = obj.assignmentRule.keys
                check = ismember(i, obj.sIds.keys);
                errorId = 'APPLYASSIGNMENTRULES:WrongSymbolError';
                errorMsg = 'Target symbol not in current model';
                assert(check, errorId, errorMsg);
                
                formula = obj.parseConstantElements(obj.assignmentRule(i));
                formula = obj.parseVariableElements(formula, true);
                formula = obj.evalFormula(formula);
                
                obj.setElementBySId(i, formula);                
            end
        end        
        
        function updateCurrentSbmlModel(obj)
        %% updateCurrentSbmlModel - Updates current SBML model libSBML 
        % structure.
        %
        % Syntax: obj.updateCurrentSbmlModel
            
            SbmlModelCopy = obj.CurrentSbmlModel;
            
            % Initial assignment default struct.            
            if isemptyExt(SbmlModelCopy.initialAssignment)
                defaultInitAssign = struct;
                defaultInitAssign.typecode = 'SBML_INITIAL_ASSIGNMENT';
                defaultInitAssign.metaid = char.empty;
                defaultInitAssign.notes = char.empty;
                defaultInitAssign.annotation = char.empty;
                defaultInitAssign.cvterms = [];
                defaultInitAssign.sboTerm = char.empty;
                defaultInitAssign.symbol = char.empty;
                defaultInitAssign.math = char.empty;                
            else
                defaultInitAssign = SbmlModelCopy.initialAssignment(1);
            end
            % Mark struct as created by SbmlExt to allow future identification.
            defaultInitAssign.notes = 'SbmlExt';
            
            % Add initial assignment rules to model structure
            if ~isemptyExt(obj.initialAssignment)               
                for i = 1:numel(obj.initialAssignment.keys)
                    symbol = obj.initialAssignment.keys(i);
                    math = obj.initialAssignment(symbol);
                    
                    check = ismember(symbol, ...
                                     {SbmlModelCopy.initialAssignment.symbol});
                    if check
                        SbmlModelCopy.initialAssignment(i).math = math;
                    else
                        defaultInitAssign.symbol = char(symbol);
                        defaultInitAssign.math = char(math);
                        
                        SbmlModelCopy.initialAssignment = ...
                            horzcat(SbmlModelCopy.initialAssignment, ...
                                    defaultInitAssign);
                    end
                end
            end
            
            % Assignment rule default struct.
            if isemptyExt(SbmlModelCopy.rule)                
                assignmentRuleMask = logical.empty;
                sbmlAssignmentRules = struct.empty;
                
                defaultAssignmentRule = struct;
                defaultAssignmentRule.typecode = 'SBML_ASSIGNMENT_RULE';
                defaultAssignmentRule.metaid = char.empty;
                defaultAssignmentRule.notes = char.empty;
                defaultAssignmentRule.annotation = char.empty;
                defaultAssignmentRule.cvterms = [];
                defaultAssignmentRule.sboTerm = char.empty;
                defaultAssignmentRule.formula = char.empty;
                defaultAssignmentRule.variable = char.empty;
                defaultAssignmentRule.species = char.empty; 
                defaultAssignmentRule.compartment = char.empty;
                defaultAssignmentRule.name = char.empty; 
                defaultAssignmentRule.units = char.empty;             
            else
                assignmentRuleMask = strcmp('SBML_ASSIGNMENT_RULE', ...
                    SbmlModelCopy.rule.typecode);
                sbmlAssignmentRules = SbmlModelCopy.rule(assignmentRuleMask);
                
                defaultAssignmentRule = sbmlAssignmentRules(1);
            end
            defaultAssignmentRule.notes = 'SbmlExt';            
            
            % Add assignment rules to model structure.
            if ~isemptyExt(obj.assignmentRule)
                sbmlVariables = {sbmlAssignmentRules.variable};
                newRules = struct.empty;                
                for i = 1:numel(obj.assignmentRule.keys)
                    variable = char(obj.assignmentRule.keys(i));
                    formula = char(obj.assignmentRule(variable));
                    if ismember(variable, sbmlVariables)
                        sbmlAssignmentRules(i).formula = formula;
                    else
                        defaultAssignmentRule.variable = variable;
                        defaultAssignmentRule.formula = formula;
                        newRules = horzcat(newRules, defaultAssignmentRule);
                    end
                end
                SbmlModelCopy.rule(assignmentRuleMask) = sbmlAssignmentRules;
                SbmlModelCopy.rule = horzcat(SbmlModelCopy.rule, newRules);
            end            
            
            % Add compartments to model structure.
            if ~isemptyExt(obj.compartment)
                for i = 1:numel(obj.compartment.keys)
                    SbmlModelCopy.compartment(i).size = ...
                        obj.compartment.values{i}.value;
                end
            end
            
            % Add species to model structure.
            if ~isemptyExt(obj.species)
                for i = 1:numel(obj.species.keys)
                    if logical(SbmlModelCopy.species(i).hasOnlySubstanceUnits)
                        SbmlModelCopy.species(i).initialAmount = ...
                            obj.species.values{i}.value;
                    else
                        SbmlModelCopy.species(i).initialConcentration = ...
                            obj.species.values{i}.value;                        
                    end
                end
            end
            
            % Add parameters to model structure.
            if ~isemptyExt(obj.parameter)
                for i = 1:numel(obj.parameter.keys)
                    SbmlModelCopy.parameter(i).value = ...
                        obj.parameter.values{i}.value;
                end
            end
            
            % Add reactants and products stoichiometry to model structure.
            if ~isemptyExt(obj.reaction)
                for i = 1:numel(obj.reaction.keys)
                    products = obj.reaction.values{i}.product;
                    reactants = obj.reaction.values{i}.reactant;                    
                    % Adding products...
                    if ~isemptyExt(products)                    
                        for j = 1:numel(products.keys)
                            SbmlModelCopy.reaction(i).product(j).( ...
                                'stoichiometry') = products.values{j}.value;
                        end
                    end                    
                    % Adding reactants...
                    if ~isemptyExt(reactants)                    
                        for j = 1:numel(reactants.keys)
                            SbmlModelCopy.reaction(i).reactant(j).( ...
                                'stoichiometry') = reactants.values{j}.value;
                        end
                    end
                end
            end            
            obj.CurrentSbmlModel = SbmlModelCopy;         
        end
        
        function out = getDynamicsString(obj)
        %% getDynamicsString - Returns dynamics parsed for current model as 
        % strings.
        %
        % Syntax: obj.getDynamicsString;
        %
        % Outputs
        %   out - String. Parsed model dynamics.
        
            % Map time symbol.
            if isemptyExt(obj.SbmlModel.time_symbol)
                timeSymbol = "t";
            else
                timeSymbol = string(obj.SbmlModel.time_symbol);
            end
            
            % Species mapping.
            freeSpecies = string.empty;
            for i = obj.species.keys
                speciesStruct = obj.species(i);
                check = speciesStruct.isConstant || speciesStruct.isBoundary;
                if ~check, freeSpecies = horzcat(freeSpecies, i); end
            end
        
            out = string(obj.dxdt.values);
            for i = 1:numel(obj.dxdt.keys)
                formula = mathReplace(obj.dxdt.values{i}, timeSymbol, "t");
                for j = 1:numel(freeSpecies)
                    formula = mathReplace(formula, freeSpecies(j), ...
                                          "x(" + j + ")");
                end
                formula = obj.parseConstantElements(formula);
                formula = obj.parseVariableElements(formula);
                formula = obj.evalFormula(formula);
                
                out(i) = formula;
            end
        end
    end
    
    methods(Access = protected)
% OVERLOADED METHODS        
        function out = copyElement(obj)
        % Overload copyElement method.            
             out = copyElement@matlab.mixin.Copyable(obj);
             % Make a deep copy of all properties
             propertyList = transpose(string(properties(out)));
             for i = propertyList
                 propertyValue = out.(i);             
                 if Dict.isDict(propertyValue)
                    out.(i) =  propertyValue.copy;
                 end
             end
        end
    end
    
    methods (Access = private)
% AUXILIAR METHODS        
        function out = parseConstantElements(obj, formula)
        %% parseConstantElements - Parses a math formula in the context of 
        % current model constant elements.
        %
        % Syntax: out = obj.parseElements(formula);
        %
        % Inputs
        %	formula - String type. Formula.
        %
        % Outputs:
        %	out - String. Parsed formula.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'formula', @(x) isStringType(x) || isnumeric(x));
            
            parse(p, obj, formula);
            obj = p.Results.obj;
            formula = num2str(p.Results.formula);
            % ...input parsed
            
            elementTypes = ["compartment" "species" "parameter"];
            for i = obj.sIds.keys
                if ismember(obj.sIds(i), elementTypes)               
                    element = obj.getElementBySId(i);
                    
                    check = element.isConstant || ...
                        (isfield(element, 'isBoundary') && element.isBoundary);
                    if check
                        formula = mathReplace(formula, i, element.value);
                    end
                end
                
                if ismember(obj.sIds(i), ["reactant" "product"])
                    element = obj.getElementBySId(i);                    
                    formula = mathReplace(formula, i, element.value);                    
                end
            end            
            out = string(formula);
        end
        
        function out = parseVariableElements(obj, formula, varargin)
        %% parseVariableElements - Parses a math formula in the context of 
        % current model variable elements.
        %
        % Syntax: out = obj.parseVariableElements(formula);
        %
        % Inputs
        %	formula - String type. Formula.
        %	replaceSpecies - Optional. Logical. If true, variable species are 
        %                    parsed using its initial quantity. Defaults to
        %                    false.
        %
        % Outputs
        %	out - String. Parsed formula.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'formula', @(x) isStringType(x) || isnumeric(x));
            addOptional(p, 'replaceSpecies', false, @islogical);
            
            parse(p, obj, formula, varargin{:});
            obj = p.Results.obj;
            formula = num2str(p.Results.formula);
            replaceSpecies = p.Results.replaceSpecies;
            % ...input parsed
            
            if replaceSpecies
                elementsType = ["compartment" "species" "parameter"];
            else
                elementsType = ["compartment" "parameter"];
            end
            
            for i = obj.sIds.keys
                if ismember(obj.sIds(i), elementsType)               
                    element = obj.getElementBySId(i);
                    
                    check = element.isConstant || ...
                        (isfield(element, 'isBoundary') && element.isBoundary);
                    if ~check
                        formula = mathReplace(formula, i, element.value);
                    end
                end
            end            
            out = string(formula);            
        end
        
        function out = evalFormula(obj, formula)
        %% parseFunctionDefinitions - Evaluates a math formula in the context of
        % current model.
        %
        % Syntax: out = obj.evalFormula(formula);
        %
        % Inputs
        %	formula - String or char. Formula.
        %
        % Outputs
        %	out - Numeric. Value of formula after evaluation.
            
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @SbmlExt.isSbmlExt);
            addRequired(p, 'formula', @(x) isStringType(x) || isnumeric(x));
            
            parse(p, obj, formula);
            obj = p.Results.obj;
            formula = num2str(p.Results.formula);
            % ...input parsed    
            
            funcMask = strcmp('functionDefinition', string(obj.sIds.values));
            funcSIds = obj.sIds.keys(funcMask);
            if ~isemptyExt(funcSIds)
                for i = funcSIds
                    lambdaFunction = str2sym(obj.getElementBySId(i));
                    assignin('caller', i, lambdaFunction);
                end
            end
            
            formula = string(str2sym(formula));            
            out = str2double(formula);
            if isnan(out)
                out = formula;
            end
        end
        
        function getFunctionsDefinition(obj)
        %% getFunctionsDefinition - Retrieves function definitions from SBML 
        % model as a (function sId - anonymous function expression) dictionary.
        %
        % Syntax: obj.getFunctionsDefinitions;
            obj.functionDefinition = Dict.empty;
    
            functionDefinitions = obj.SbmlModel.functionDefinition;
            if isemptyExt(functionDefinitions)
                return;
            else
                funcDefSIds = string({functionDefinitions.id});
            end      

            % Convert MathML lambda expressions to MATLAB anonymous functions.
            rex = '(?<=lambda\()[^)]*(?=\))';
            n = numel(functionDefinitions);
            anonFunc = strings(1, n);
            for i = 1:n
                iFunctionMath = functionDefinitions(i).math;

                % Get arguments of MathML lambda expression ...
                lambdaArgs = regexp(iFunctionMath, rex, 'match', 'once');
                lambdaArgs = string(split(lambdaArgs, ','));
                lambdaArgs = map(@strip, lambdaArgs);

                % ...and build a MATLAB anonymous function.
                anonArgs = strjoin(lambdaArgs(1:end - 1), ", ");
                anonMath = lambdaArgs(end);
                anonFunc{i} = sprintf('@(%s) %s', anonArgs, anonMath);
            end
            
            obj.sIds.addPairs(funcDefSIds, repmat("functionDefinition", 1, n));
            obj.functionDefinition = Dict(funcDefSIds, anonFunc);
        end

        function getInitialAssignments(obj)
        %% getInitialAssignments - Retrieves initial assignments from SBML model
        % as a (symbol - math) dictionary.
        %
        % Syntax: obj.getInitialAssignments;
            obj.initialAssignment = Dict.empty;
            
            initialAssignments = obj.SbmlModel.initialAssignment;
            if isemptyExt(initialAssignments)
                return;
            else
                symbols = string({initialAssignments.symbol});
            end            
            maths = {initialAssignments.math};
            
            obj.initialAssignment = Dict(symbols, maths);
        end

        function getAssignmentRules(obj)
        %% getAssignmentRules - Retrieves assignment rules from SBML model as a 
        % (variable - formula) dictionary.
        %
        % Syntax: obj.getAssignmentRules;
            obj.assignmentRule = Dict.empty;
            
            nRule = obj.SbmlModel.rule;
            if isemptyExt(nRule)
                return; 
            else
                obj.assignmentRule = Dict;
                for i = 1:numel(nRule)
                    iRule = nRule(i);
                    if strcmp('SBML_ASSIGNMENT_RULE', iRule.typecode)
                        obj.assignmentRule(iRule.variable) = iRule.formula;
                    end
                end
            end
        end

        function getRateRules(obj)
        %% getRateRules - Retrieves rate rules from SBML as a (variable - 
        % formula) dictionary.
        %
        % Syntax: obj.getRateRules(SbmlModel);
            obj.rateRule = Dict.empty;
            
            nRule = obj.SbmlModel.rule;
            if isemptyExt(nRule)
                return; 
            else
                obj.rateRule = Dict;
                for i = 1:numel(nRule)
                    iRule = nRule(i);
                    if strcmp('SBML_RATE_RULE', iRule.typecode)
                        obj.assignmentRule(iRule.variable) = iRule.formula;
                    end
                end
            end
        end

        function getCompartments(obj)
        %% getCompartments - Retrieves compartments from SBML model as a
        % (compartment sId - compartment structure) dictionary.
        %
        % Compartments structures contains the following fields:   
        %	*isConstant - Logical. True if compartment size is constant, else 
        %                 false.
        %	*value - Numeric. Compartment size.
        %
        % Syntax: obj.getCompartments;
            obj.compartment = Dict.empty;

            compartments = obj.SbmlModel.compartment;
            if isemptyExt(compartments)
                return;
            else
                isConstant = logical([compartments.constant]);                
                sizes = [compartments.size];
                
                n = numel(compartments);
                OutStructs = cell(1, n);
                for i = 1:n
                    OutStructs{i} = struct('isConstant', isConstant(i), ...
                                           'value', sizes(i));
                end
                
                compartmentSIds = string({compartments.id});
                obj.sIds.addPairs(compartmentSIds, repmat("compartment", 1, n));                
                obj.compartment = Dict(compartmentSIds, OutStructs);                
            end
        end

        function getParameters(obj)
        %% getParameters - Retrieves parameters as a (parameter sId - 
        % parameter structure) dictionary.
        %
        % Parameters structures contains the following fields:   
        %	*isConstant - Logical. True if parameter value is constant,
        %                 else false.
        %	*value - Numeric. Parameter value.
        %
        % Syntax: obj.getParameters
            obj.parameter = Dict.empty;

            parameters = obj.SbmlModel.parameter;
            if isemptyExt(parameters)
                return;
            else
                isConstant = logical([parameters.constant]);                
                values = [parameters.value];
                
                n = numel(parameters);
                OutStructs = cell(1, n);
                for i = 1:n
                    OutStructs{i} = struct('isConstant', isConstant(i), ...
                                           'value', values(i));
                end
                
                parameterSIds = string({parameters.id});
                obj.sIds.addPairs(parameterSIds, repmat("parameter", 1, n));                
                obj.parameter = Dict(parameterSIds, OutStructs);                
            end           
        end

        function getSpecies(obj)
        %% getSpecies - Retrieve species from SBML model as a (species sId - 
        % species structure) dictionary.
        %
        % Species structure contains the following fields:
        %	*isConstant - Logical. True if is a constant species, else false.
        %	*isBoundary - Logical. True if is a boundary species, else false.
        %	*compartment - String. Species compartment sId.
        %	*value - Numeric. Species quantity.
        %	*conversionFactor - Numeric. Empty if not present.
        %
        % Syntax: out = obj.getSpecies;
            obj.species = Dict.empty;
                
            sbmlSpecies = obj.SbmlModel.species;
            if isemptyExt(sbmlSpecies)
                return;
            else
                isConstant = logical([sbmlSpecies.constant]);
                isBoundary = logical([sbmlSpecies.boundaryCondition]);
                compartments = string({sbmlSpecies.compartment});
                isAmount = logical([sbmlSpecies.hasOnlySubstanceUnits]);
                
                n = numel(sbmlSpecies);                
                if isfield(sbmlSpecies, 'conversionFactor')
                    convFactor = [sbmlSpecies.conversionFactor];
                else
                    convFactor = cell(1, n);
                end
                
                OutStructs = cell(1, n);
                for i = 1:n
                    if isAmount(i)
                        quantity = sbmlSpecies(i).initialAmount;
                    else
                        quantity = sbmlSpecies(i).initialConcentration;
                    end
                    
                    OutStructs{i} = struct('isConstant', isConstant(i), ...
                                           'isBoundary', isBoundary(i), ...
                                           'compartment', compartments(i), ...
                                           'value', quantity, ...
                                           'conversionFactor', convFactor(i));
                end
            end
            
            speciesSIds = string({sbmlSpecies.id});
            obj.sIds.addPairs(speciesSIds, repmat("species", 1, n));             
            obj.species = Dict(speciesSIds, OutStructs);             
        end

        function getReactions(obj)
        %% getReactions - Retrieves reactions from SBML as a (reaction sId - 
        % reaction structure) dictionary.
        %
        % Reaction structures contains the following fields:
        %	*reactant - Dict. Reaction reactants.
        %	*product - Dict. Reactino products.
        %	*kineticLaw - Struct. Reaction kinetic law.        
        %
        % Syntax: out = getReactions(SbmlModel);            
            obj.reaction = Dict.empty;
            
            reactions = obj.SbmlModel.reaction;
            if isemptyExt(reactions)
                return;
            else                
                n = numel(reactions);
                OutStructs = cell(1, n);
                for i = 1:n
                    reactionId = reactions(i).id;
                    obj.getReactantsAndProducts(reactions(i));                    
                    
                    checkReactants = ~isemptyExt(obj.reactant) && ...
                                     ismember(reactionId, obj.reactant.keys);
                    if checkReactants
                        reactants = obj.reactant(reactionId);
                    else
                        reactants = Dict.empty;
                    end
                    
                    checkProducts = ~isemptyExt(obj.product) && ...
                                     ismember(reactionId, obj.product.keys);                   
                    if checkProducts
                        products = obj.product(reactionId);
                    else
                        products = Dict.empty;                        
                    end
                    kineticLaw = obj.getKineticLaw(reactions(i));
                    
                    OutStructs{i} = struct('reactant', reactants, ...
                                           'product', products, ...
                                           'kineticLaw', kineticLaw);
                end
            end            

            reactionSIds = string({reactions.id});
            obj.sIds.addPairs(reactionSIds, repmat("reaction", 1, n));             
            obj.reaction = Dict(reactionSIds, OutStructs);             
        end
        
        function getReactantsAndProducts(obj, reaction)
        %% getReactantsAndProducts - Retrieves reactants and products from SBML
        % model as a (reactant/product sId - reactant/product structure) 
        % dictionary.
        %
        % Reactant/product structure contains the following fields:
        %   *species - String. Reactant/product species sId.
        %   *value - Numeric. Reactant/Product stoichiometry value.
        %
        % Syntax: [reactants, products] = obj.getReactantsAndProducts(reaction);
        %
        % Inputs
        %	reaction - Struct. Reaction structure.
        %
        % Outputs
        %	reactants - Dict. Reaction reactants dictionary.
        %	products - Dict. Reaction products dictionary.
            
            % Parse reactants...
            reactants = reaction.reactant;            
            if ~isemptyExt(reactants)                
                reactantSIds = string({reactants.id});
                reactantSpecies = string({reactants.species});
                reactantStoichiometries = [reactants.stoichiometry];
                
                n = numel(reactants);                
                for i = 1:n
                    if isemptyExt(reactantSIds(i))
                        reactantSIds(i) = "stoich_" + reaction.id + "_" + ...
                                          reactantSpecies(i);
                    end
                end                

                OutStruct = cell(1, n);
                for i = 1:n
                    OutStruct{i} = struct('species', reactantSpecies{i}, ...
                                          'value', reactantStoichiometries(i));
                end
                
                if isemptyExt(obj.reactant), obj.reactant = Dict; end                
                obj.sIds.addPairs(reactantSIds, ...
                                  repmat("reactant", 1, numel(reactantSIds)));                
                obj.reactant.addPairs(reaction.id, Dict(reactantSIds, OutStruct));
            end
            % ...reactants parsed
            
            % Parse products...
            products = reaction.product;            
            if ~isemptyExt(products)                
                productSIds = string({products.id});
                productSpecies = string({products.species});
                productStoichiometries = [products.stoichiometry];
                
                n = numel(products);                
                for i = 1:n
                    if isemptyExt(productSIds(i))
                        productSIds(i) = "stoich_" + reaction.id + "_" + ...
                                         productSpecies(i);
                    end
                end                

                OutStruct = cell(1, n);
                for i = 1:n
                    OutStruct{i} = struct('species', productSpecies{i}, ...
                                          'value', productStoichiometries(i));
                end
                
                if isemptyExt(obj.product), obj.product = Dict; end                
                obj.sIds.addPairs(productSIds, ...
                                  repmat("product", 1, numel(productSIds)));                
                obj.product.addPairs(reaction.id, Dict(productSIds, OutStruct));
            end
            % ...products parsed
        end
        
        function kineticLaw = getKineticLaw(~, reaction)
        %% getKineticLaw - Retrieves kinetic law from reaction structure as a 
        % structure.
        %
        % Kinetic law structure contains the following fields:       
        %       *formula - String. Kinetic law formula.
        %       *parameter - Struct. Parameter structure containing local 
        %                    parameter data.
        %
        % Syntax: kineticLaw = obj.getKineticLaw(reaction);
        %
        % Inputs
        %    reaction - Struct. Reaction structure.
        %
        % Outputs
        %    kineticLaw - Struct. Reaction's kinetic law.
            
            errorId = 'GETKINETICLAW:WrongInputError';
            errorMsg = 'Input must be a structure';
            assert(isstruct(reaction), errorId, errorMsg);
            
            if isemptyExt(reaction.kineticLaw)
                kineticLaw = struct.empty;
            else                
                kineticLaw = reaction.kineticLaw;
                
                localParameters = kineticLaw.parameter;
                if isemptyExt(localParameters)
                    localParameters = Dict.empty;
                else                    
                    parameterIds = string({localParameters.id});
                    isConstant = logical([localParameters.constant]);
                    values = [localParameters.value];
                    
                    n = numel(localParameters);
                    OutStructs = cell(1, n);
                    for i = 1:n
                        OutStructs{i} = struct('isConstant', isConstant(i), ...
                                               'value', values(i));
                    end
                    parameters = Dict(parameterIds, OutStructs);                    
                end
                
                kineticLaw = struct('formula', kineticLaw.formula, ...
                                    'parameter', localParameters);
            end
        end
        
        function getODEs(obj)
        %% getODEs - Get ODEs from current model as a (species sId - 
        % ODEs expression) dictionary.
        %
        % Syntax: obj.getODEs;
        
            for i = obj.species.keys
                iSpecies = obj.species(i);
                productsExpression = string.empty;
                reactantsExpression = string.empty;
                
                % Get conversion factor (model > species > 1).
                if isfield(obj.SbmlModel, 'conversionFactor')
                    modelConvFact = obj.SbmlModel.conversionFactor;
                else
                    modelConvFact = 1;
                end
                
                if isemptyExt(iSpecies.conversionFactor)
                    conversionFactor = modelConvFact;
                else
                    conversionFactor = speciesConvFact;
                end                
                
                for j = obj.reaction.keys
                    jReaction = obj.reaction(j);
                    
                    kineticLaw = jReaction.kineticLaw;
                    formula = kineticLaw.formula;
                    localParameters = kineticLaw.parameter;
                    products = jReaction.product;                   
                    reactants = jReaction.reactant;                    
                    
                    % Parse formula for local parameters.
                    if ~isemptyExt(localParameters)
                        for k = localParameters.keys
                            parValue = localParameters(k).value;
                            formula = mathReplace(formula, k, parValue);
                        end
                    end                    
                    
                    % If species is current reaction product, add kinetic law to
                    % products expression.
                    if ~isemptyExt(products)
                        for k = products.keys
                            kProduct = products(k);
                            
                            productSpecies = kProduct.species;
                            if strcmp(i, productSpecies)                                
                                productsExpression = ...
                                    horzcat(productsExpression, ...
                                            k + "*" + formula);
                            end
                        end
                    end

                    % If species is current reaction reactant, add kinetic law 
                    % to reactants expression.                    
                    if ~isemptyExt(reactants)
                        for k = reactants.keys
                            kReactant = reactants(k);
                            
                            reactantSpecies = kReactant.species;
                            if strcmp(i, reactantSpecies)                                
                                reactantsExpression = ...
                                    horzcat(reactantsExpression, ...
                                            k + "*" + formula);
                            end
                        end
                    end                  
                end                
                
                if ~isemptyExt(productsExpression)                
                    productsExpression = ...
                        "(" + strjoin(productsExpression, ' + ') + ")";
                else
                    productsExpression = "";
                end
                
                if ~isemptyExt(reactantsExpression)
                    reactantsExpression = ...
                        " - (" + strjoin(reactantsExpression, ' + ') + ")";
                else
                    reactantsExpression = "";
                end
                
                obj.dxdt(i) = productsExpression +  reactantsExpression;
                
                % Apply conversion factor.
                if conversionFactor ~= 1
                    obj.dxdt(i) = conversionFactor + "*" + "(" + ...
                                  obj.dxdt(i) + ")";
                end
            end
        end
    end
    
    methods (Static)
% CLASS METHODS        
        function out = isSbmlExt(input)
        %% isSbmlExt - Check if input argument is a SbmlExt object.
        %
        % Syntax: out = SbmlExt.isSbmlExt(input);
        %
        % Inputs
        %    input - Any type object.
        %
        % Outputs
        %    out - Logical. True if input argument is a SbmlExt object, else
        %          false.        
            out = isa(input, 'SbmlExt');
        end
    end
% ------------- END OF CODE --------------    
 end