# PEtabMEIGO

PEtab interface for MEIGO global optimization suite.

## Getting Started

PEtabMEIGO last version is included in MEIGO suite.

### Prerequisites

 * MATLAB interface for libSBML is the only dependency required and it's up to the user it's installation. Latest libSBML MATLAB interface can be downloaded from https://sourceforge.net/projects/sbml/files/libsbml/MATLAB%20Interface/.
 * YAMLMatlab, included with PEtabMEIGO. Latest versions can be found in https://code.google.com/archive/p/yamlmatlab/.

### Installing

As mentioned, PEtabMEIGO it's supplied with MEIGO suite.

## How it works?

Given the path pointing to problem's **.yaml** file, a Petab object is constructed, exposing throught several properties and methods all problem features.

### Example of use

With problem directory **problem_dir** and model name **model_name** do:

```
    petab = Petab.fromYaml(problem_dir, model_name);
```

or we can also use problem's **.yaml** file path, **yaml_path**:

```
    petab = Petab.fromYaml(yaml_path);
```

We can acces all data structures of PEtab problem definition throught recently created **petab** object, i.e., observables table:

```
    obsDf = petab.observablesDf;
```

SBML model is parsed and loaded into **petab** object's property **sbmlModel**:

```
    sbmlModel = petab.sbmlModel;
```

For problem's simulation, given a numeric array of free parameters, **freePars**, method **getSimulationsTable** can be used:

```
    simsDf = petab.getSimulationsTable(freePars);
```

and different error metrics, i.e., negative log-likelihood, are calculated for simulations table with function **calculateProblemLlh**:

```
    nllh = calculateProblemLlh(simsDf);
```

**objectiveFunction** method returns negative log-likelihood and measurement table residuals given a free parameter vector:

```
    [J, g, R] = petab.objectiveFunction(freePars);
```

Finally, for solving parameter estimation problem, as exposed in MEIGO's documentation:

```
    % Start of MEIGO's problem structure definition
    problem.f = 'problemObjectiveFunction';           

    problem.x_L = petab.lbFree;
    problem.x_U = petab.ubFree;
    
    problem.x_0 = petab.xNominalFree;
    % End of MEIGO's problem structure definition
    
    % Other problem specs...
    opts.maxeval=1e3; 
    opts.local.solver='nl2sol';
    opts.inter_save=1;
    
    Results = MEIGO(problem, opts, 'ESS', petab);
```
### Known Issues

* SBML events not supported yet.

## Version

* *PEtabMEIGO 20201125*

## Authors

* Tacio Camba Espí

## Acknowledgments

* TODO