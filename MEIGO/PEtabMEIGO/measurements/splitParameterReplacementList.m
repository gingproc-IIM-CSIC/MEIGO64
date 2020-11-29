function out = splitParameterReplacementList(list, varargin)
%% splitParameterReplacementList - Splits a list of elements separated by a 
% delimiter character.
%
% Syntax: out = splitParameterReplacementList(array, delimiter);
%
% Inputs
%	array - String type. List of values separated by a delimiter.
%	delimiter - Optional. String type. Delimiter. Defaults to ';'.
%
% Outputs
%	out - Cell. Splitted list. Elements representing a number converted to 
%         numeric.
%
% Example
%	out = splitParameterReplacementList('a,2.5,c', ','); -> {{'a} {[2.5]} {'c'}}
%   out = splitParameterReplacementList("a;2.5"); -> {{'a'} {[2.5]}} 
%
% Other m-files required: auxiliar/toNumericIfNumeric.m, auxiliar/map.m, 
%                         auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: taciocambaespi@gmail.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 19-May-2020
%% ------------- BEGIN CODE --------------  

    % Parse input...
    p = inputParser;
    
    addRequired(p, 'list', @(x) isStringType(x) || isnumeric(x));
    addOptional(p, 'delimiter', ';', @isStringType);
    
    parse(p, list, varargin{:});
    list = num2str(p.Results.list);
    delimiter = p.Results.delimiter;
    % ...input parsed.
    
    out = split(list, delimiter, 2);    
    out = map(@toNumericIfNumeric, out, 'UniformOutput', false);
% ------------- END OF CODE --------------
end