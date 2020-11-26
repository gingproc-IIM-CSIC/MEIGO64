function resultsTable = testSuiteCases(useRR)
%% testSuiteCases - Tests simulation capabilities, chi2 and log-likelihood 
% calculations of PEtabMEIGO for 16 test cases.
%
% Syntax: resultsTable = testSuiteCases
%
% Inputs:
%    useRR - Logical. Optional. If true, simulates sbml models using
%            roadrunner c library. Defaults to false.
%
%
% Outputs:
%    resultsTable - Table. The result string for each test consist in 
%                   three consecutive characters. First character stands 
%                   for simulation, second to chi2 and last one to 
%                   log-likelihood.
%
% Other m-files required: petab/Petab.m, auxiliar/isemptyExt.m, 
%    auxiliar/map.m, optimizationproblem/getSimulationTableForPetab,
%    calculations/calculateChi2FromSimulationTable,
%    calculations/calculateLlhFromSimulationTable
% Subfunctions: none
% MAT-files required: none

% Author: Tacio Camba Espí
% email: info@taciocamba.com
% Website: http://www.taciocamba.com
% April 2020; Last revision: 22-Aug-2020
%% ------------- BEGIN CODE --------------
    
    if nargin == 0
        useRR = false;
    end
    
    % Tests folders should be placed in this function's directory.
    path = fileparts(which('testSuiteCases.m'));   
    folderNames = string({dir(path).name});
    
    rex = '\d*';
    folderMask = map(@(x) ~isemptyExt(regexp(x, rex, 'once')), ...
                     folderNames);
    folderNames = folderNames(folderMask);
    
    % Bulding tests results table
    n = numel(folderNames);
    testNumber = transpose(1:n);
    MEIGO = cellstr(repmat("---", n, 1));
    testsResults = table(testNumber, MEIGO);   
     
    for i = 1:n
        fprintf(sprintf(' Testing case %d...\n', i));
        
        % Load petab problem from test's yaml file
        petabYaml = fullfile(path, folderNames(i), ...
                             folderNames(i) + ".yaml");
        petab = Petab.fromYaml(petabYaml);
        
        % Load simulation table for nominal free parameters values
        simulationTable = petab.getSimulationsTable(petab.xNominalFree, ...
                                                    useRR);
        
        simulation = simulationTable.simulation;
        chi2 = calculateProblemChi2(simulationTable);        
        llh = calculateProblemLlh(simulationTable);
        
        % Load test's solution from yaml file
        solutionYaml = fullfile(path, folderNames(i), ...
                                folderNames(i) + "_solution" + ".yaml");
        solution = ReadYaml(char(solutionYaml));
        chi2Sol = solution.chi2;
        llhSol = solution.llh;
        chi2Tol = solution.tol_chi2;
        llhTol = solution.tol_llh;        
        simTol = solution.tol_simulations;
        
        % Load solution's simulation table
        simFileName = solution.simulation_files;
        simFilePath = fullfile(path, folderNames(i), simFileName);
        solSimulation = readtable(simFilePath, 'FileType', 'text');
        solSimulation = solSimulation.simulation;
        
        % Compare test solutions with PEtabMeigo results
        if abs(simulation - solSimulation) <= simTol
            result = testsResults.MEIGO{i};
            result(1) = '+';            
            testsResults.MEIGO{i} = result;
        else
            result = testsResults.MEIGO{i};
            result(1) = '-';            
            testsResults.MEIGO{i} = result;
        end
        
        if abs(chi2 - chi2Sol) <= chi2Tol
            result = testsResults.MEIGO{i};
            result(2) = '+';            
            testsResults.MEIGO{i} = result;
        else
            result = testsResults.MEIGO{i};
            result(2) = '-';            
            testsResults.MEIGO{i} = result;
        end
        
        if abs(llh - llhSol) <= llhTol
            result = testsResults.MEIGO{i};
            result(3) = '+';
            testsResults.MEIGO{i} = result;
        else
            result = testsResults.MEIGO{i};
            result(3) = '-';
            testsResults.MEIGO{i} = result;
        end        
        
        fprintf(sprintf(' ...Case %d tested succesfully.\n', i));        
    end
    petab.removeTempFiles;
    
    resultsTable = testsResults;
    resultsTable.MEIGO = string(resultsTable.MEIGO);
    writetable(resultsTable, fullfile(path, 'testsResults.txt'), ...
               'Delimiter', '\t')
% ------------- END OF CODE --------------      
end