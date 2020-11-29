function out = flatten(input)
%% flatten - Flattens a cell or struct.
%
% Syntax: out = flatten(input);
%
% Inputs
%	input - Cell or struct. Object to be flattened.
%
% Outputs
%	out - Cell. Flattened input argument.
%
% Example
%	out = flatten({1 2 {'a' 'b'}}); -> {1 2 'a' 'b'}
%
% Other m-files required: auxiliar/flatten.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 17-May-2020
%% ------------- BEGIN CODE --------------
    check = @(x) iscell(x) || isstruct(x);
    errorId = 'WrongInputError';
    errorMsg = 'Input must be a cell or a structure';
    assert(check, errorId, errorMsg);
    
    if isstruct(input), input = struct2cell(input); end    
    
    out = cell.empty;
    for i = 1:numel(input)
        if iscell(input{i}) || isstruct(input{i})
            out = horzcat(out, flatten(input{i}));
        else
            out = horzcat(out, input{i});
        end
    end 
% ------------- END OF CODE --------------    
end
