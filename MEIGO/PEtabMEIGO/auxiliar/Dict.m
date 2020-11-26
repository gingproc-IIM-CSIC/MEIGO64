classdef Dict < matlab.mixin.Copyable
%% Dict - Stores data as key-value pairs.
%
% Properties
%	keys - String. Keys.
%	values - Cell. Values.
%
% Object Methods
%	sort - Sort dictionary by keys alphabetic order.
%	addPairs - Add key-value pairs to dictionary.
%
% Static Methods
%	sortDict - Returns a copy of given dictionary sorted by keys alphabetic 
%              order.
%	isDict - Check if input is an instance of Dict class.
%
% Other m-files: auxiliar/isemptyExt.m, auxiliar/map.m, auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none
%
% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 16-May-2020
%% ------------- BEGIN CODE --------------

% PROPERTIES
    properties (SetAccess = private)
        keys string = string.empty;
        values cell = cell.empty;
    end
    
    methods        
% CONSTRUCTORS
        function obj = Dict(keys, values)
        % Dict constructor.        
            if nargin == 0, return; end
            
            % Transpose keys and values if they're not row arrays (convention 
            % and displaying)
            if ~isrow(keys), keys = transpose(keys); end            
            if ~isrow(values), values = transpose(values); end
            
            obj.addPairs(keys, values);
        end
        
% OVERLOADED METHODS        
        function varargout = subsref(obj,ref)
        % Overloaded subsref function.
        %
        % See also: subsref (built-in)        
            switch ref(1).type
                case '.'
                    [varargout{1:nargout}] = builtin('subsref', obj, ref);
                case '()'
                    if numel(ref) == 1
                        if numel(ref(1).subs) == 1                            
                            subs = string(ref(1).subs{1});
                        else
                            subs = string(ref(1).subs);                            
                        end
                        
                        % Allows indexing of Dict arrays.
                        if isnumeric(subs)
                            [varargout{1:nargout}] = ...
                                builtin('subsref', obj, ref);                            
                            return;
                        end                        
                        
                        if numel(subs) > 1
                            varargout{1} = obj.valueSearch(subs);
                        else
                            [varargout{1:nargout}] = obj.valueSearch(subs);
                        end                    
                    else
                        % Use built-in subsref for any other reference.                    
                        [varargout{1:nargout}] = builtin('subsref', obj, ref);
                    end
                case '{}'
                    [varargout{1:nargout}] = builtin('subsref', obj, ref);
                otherwise
                    errorId = 'SUBSREF:WrongIndexExpressionError';
                    errorMsg = 'Not a valid indexing expression';
                    error(errorId, errorMsg);
            end
        end
        
        function obj = subsasgn(obj, ref, varargin)
        % Overloaded subsasgn function.
        %
        % See also: subsasgn (built-in)        
            if isemptyExt(obj), obj = Dict; end
            
            switch ref(1).type
                case '.'
                    obj = builtin('subsasgn', obj, ref, varargin{:});
                case '()'
                    if numel(ref) == 1                        
                        subs = ref(1).subs;
                        if ~isstring(subs{1}), subs{1} = string(subs{1}); end
                        
                        % Multiple assignment not allowed.
                        errorId = 'SUBSASGN:AssignmentError';
                        errorMsg = "Multiple assignment not allowed. " + ...
                                   "Use addPairs method instead";
                        assert(numel(subs{1}) == 1, errorId, errorMsg);
                        
                        subs = string(subs{1});
                        obj.keys = subs;
                        keyIdx = obj.keyIndex(subs);
                        
                        obj.values{keyIdx} = varargin{:};
                    else
                        % Use built-in subasasgn for any other reference.                        
                        obj = builtin('subsasgn', obj, ref, varargin{:});
                    end
                case '{}'
                    obj = builtin('subsasgn', obj, ref, varargin{:});
                otherwise
                    errorId = 'SUBSASGN:WrongIndexExpressionError';
                    errorMsg = 'Not a valid indexing expression';
                    error(errorId, errorMsg);
            end
        end
        
% SETTERS AND GETTERS
        function set.keys(obj, keys)
        % Keys setter method.        
            obj.keys = horzcat(obj.keys, keys);
            obj.keys = unique(obj.keys, 'stable');
        end
        
% OBJECT METHODS
        function obj = sort(obj)
        %% sort - Sort dictionary by keys alphabetic order.
        %
        % Syntax: obj.sort;
        %
        % See also: Dict.sortDict     
            obj = Dict.sortDict(obj);
        end
        
        function addPairs(obj, keys, values)
        %% addPairs - Add key-value pairs to dictionary.
        %
        % Syntax: obj.addPairs(keys, values);
        %
        % Inputs
        %	keys - String type. Keys to be added to dictionary.
        %   values - Any. Values.
        %
        % Example
        %   obj.addPairs(["k1" "k2" "k3"], [1 2 3]);
        %   obj.addPairs(["k1" "k2" "k3"], {1 'b' 3});
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Dict.isDict);
            addRequired(p, 'keys', @(x) isStringType(x) || iscellstr(x));
            addRequired(p, 'values');

            parse(p, obj, keys, values);
            obj = p.Results.obj;
            keys = string(p.Results.keys);
            values = p.Results.values;
            % ...input parsed.
            
            % Convert char to string to avoid type inconsistencies.
            if ischar(values), values = string(values); end
            
            if numel(keys) == 1
                obj.keys = keys;
                keyIdx = obj.keyIndex(keys);
                
                if iscell(values) && numel(values) == 1
                    obj.values{keyIdx} = values{1}; 
                else
                    obj.values{keyIdx} = values;   
                end
            else            
                check = numel(keys) == numel(values);
                errorId = 'ADDPAIRS:WrongInputSizeError';
                errorMsg = 'Keys and values must be of same size';
                assert(check, errorId, errorMsg);
                
                if ~iscell(values)
                    values = num2cell(values);
                end
                
                for i = 1:numel(keys)
                    obj.keys = keys(i);
                    keyIdx = obj.keyIndex(keys(i));
                    obj.values{keyIdx} = values{i};
                end
            end
        end
    end
    
    methods (Access = private)        
% AUXILIAR METHODS
        function out = keyIndex(obj, keys)
        %% keyIndex - Returns index of keys.
        %
        % Syntax: obj.keyIndex(keys);
        %
        % Inputs
        %   keys - String type. Key.
        %
        % Outputs
        %   out - Numeric. Key's index.
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Dict.isDict);
            addRequired(p, 'keys', @(x) isStringType(x) || iscellstr(x));

            parse(p, obj, keys);
            obj = p.Results.obj;
            keys = p.Results.keys;
            % ...input parsed.
            
            keyMask = false(1, numel(obj.keys));
            for i = 1:numel(keys)
                check = ismember(keys(i), obj.keys);
                errorId = 'KEYINDEX:KeyNotFoundError';
                errorMsg = 'Key not in dictionary';
                assert(check, errorId, errorMsg);
                
                keyMask = keyMask | strcmp(keys(i), obj.keys);
            end
            
            out = find(keyMask);
        end
        
        function out = valueSearch(obj, keys)
        %% valueSearch - Retrieves values corresponding to keys argument.
        %
        % Syntax: obj.valueSearch(keys);
        %
        % Inputs
        %    keys - String. Keys.
        %
        % Outputs
        %    out - Any type. Values.
        
            % Parse input...
            p = inputParser;
            
            addRequired(p, 'obj', @Dict.isDict);
            addRequired(p, 'keys', @(x) isStringType(x) || iscellstr(x));

            parse(p, obj, keys);
            obj = p.Results.obj;
            keys = p.Results.keys;
            % ...input parsed.        
            
            keyIdx = obj.keyIndex(keys);
            out = obj.values(keyIdx);
            if numel(out) == 1
                out = out{1};
            end
        end
    end
    
    methods (Static)
% CLASS METHODS
        function out = sortDict(input)
        %% sortDict - Returns a copy of given dictionary sorted by keys 
        % alphabetic order.
        %
        % Syntax: out = Dict.sortDict(dict);
        %
        % Inputs
        %    input - Dict. Dictionary to be sorted.
        %
        % Outputs
        %    out - Dict. Sorted dictionary.

            % Parse input...
            p = inputParser;
            
            addRequired(p, 'dict', @Dict.isDict);

            parse(p, input);
            input = p.Results.dict;
            % ...input parsed.         
            
            % Sort keys and get their new indexes...
            [sortedKeys, kIdx] = sort(input.keys);
            % ...and use it to sort values accordingly.
            sortedValues = input.values(kIdx);
            
            out = Dict(sortedKeys, sortedValues);
        end
        
        function out = isDict(input)
        %% isDict - Check if input argument is a Dict object.
        %
        % Syntax: out = Dict.isDict(input);
        %
        % Inputs
        %    input - Any type object.
        %
        % Outputs
        %    out - Logical. True if input argument is a Dict object, else false.            
            out = isa(input, 'Dict');
        end
    end
% ------------- END OF CODE --------------
end