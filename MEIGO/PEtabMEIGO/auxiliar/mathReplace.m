function out = mathReplace(formula, expression, replace)
%% mathReplace - Substitutes expression in formula with the content of replace.
%
% Syntax: out = mathReplace(str, expression, replace);
%
% Inputs
%	formula - String type. A math formula.
%	expression - String type. Expression to be replaced.
%	replace - String type or numeric. Replacement of expression.
%
% Outputs
%    out - String. Input formula after expression replacement.
%
% Example:
%    out = mathReplace('2*a + b', 'b', 'z'); -> "2*a + z"
%    out = mathReplace("2*a + log(b)", 'b', 2.5); -> "2*a + log(2.5)"
%
% Other m-files required: auxiliar/isStringType.m
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 24-April-2020
%% ------------- BEGIN CODE --------------
    % Parse input...
    p = inputParser;
    
    addRequired(p, 'formula', @isStringType);
    addRequired(p, 'expression', @isStringType);
    addRequired(p, 'replace', @(x) isStringType(x) || isnumeric(x));
    
    parse(p, formula, expression, replace);
    formula = string(p.Results.formula);
    expression = string(p.Results.expression);
    replace = string(num2str(p.Results.replace));    
    % ...input parsed
    
    rex = sprintf('(?<=[\\W\\s])%s(?=[\\W\\s])', expression);
    % Put whitespaces around formula to match expressions in string array
    % boundaries...
    formula = " " + formula + " ";
    
    % ...and remove it before function return.
    out = strip(regexprep(formula, rex, replace));
% ------------- END OF CODE --------------        
end