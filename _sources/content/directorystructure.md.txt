# Directory Structure

As trivial and minor as a proper directory structure may sound, it  is very 
important.   
As the name suggests, a directory structure structures the workflow. Directory 
names do dictate where to find certain files, where to store simulation results, 
forcing data, etc. This helps the maintainer to develop the source code, and 
also helps the user to get started and become familiar with the workflow. 

The directory structure of this workflow consists of a single layer only 
and contains the following directories:

```
TSMP_WorkflowStarter/
|    
|---- ctrl
|    |---- namelist
|    |---- env
|---- forcing
|---- geo
|---- monitoring
|---- postpro
|---- rundir
|---- simres
|---- src
```

There may be other subdirectories, but those are not part of the mentioned 
directory structure and may vary from setup to setup.

All of the directories are named very strictly according to what they are aimed 
for. With some experience of the workflow, these names will become very 
intuitive. Each directory is described in detail below.

## ctrl/
`ctrl/` (**c**on**tr**o**l**) contains all the scripts needed to control the 
workflow, as well as scripts written specifically for this workflow, such as 
post-processing scripts. 

### ctrl/namelist/
`ctrl/namelist/`, clearly contains **namlist**s for the individual component 
models used within the workflow. As these namelists do control the model 
behaviour and are specific to the workflow, this is a subdirectory of `ctrl/`.

### ctrl/env/
`ctrl/env/` contains the **env**iroment files used. Since each simulation 
depends on a specific set of programs (e.g. python) and libraries (e.g. netCDF) 
in a specific version, we need to provide this information to the user of the 
workflow. Environment files does list these dependencies and ensure that the 
required environment is set up correctly.

## forcing/
`forcing/` is a directory containing any **forcing** files needed. This could 
be an atm. forcing dataset driving the land surface model CLM or lateral 
boundary conditions needed by the atm. Model COSMO.

## geo/
`geo/` contains files required by the component models that define the model 
domain. This could be topographic data, land cover data, soil properties, grids 
defining the spatial extent of the domain and many more. Often this data is 
referred to as `static files`, but as some of the required data sets, such as 
the land cover, may change over time, `static` could be misleading, hence the 
name `geo/`.

## monitoring/
`monitoring/` contains the output of some **monitoring** functions. Monitoring 
of simulations is mandatory, as there are many situations that can affect the 
model results, ranging from just stopping / crashing the simulation to silently 
corrupting the simulation results. 
Manually checking the simulation results from time to time is very 
time-consuming, as simulation results are usually very big and the simulations 
might run for months. So there are small functions in this workflow that provide 
some summary plots. These are generated automatically on a regular basis and are 
stored with the `monitoring/` directory, so that you can either browse through 
these plots to monitor your simulation, or the plots can be uploaded to some 
web-server, making it even easier to monitor the simulation.

## postpro/
`postpro/` simply contains the **post-pro**cessed simulation results. The 
post-processing step is thereby very individual for each simulation and can vary 
from simple aggregation of simulation results to e.g. monthly files, to the 
calculation of further diagnostics derived from the original simulation results.

## rundir/
`rundir/` is the directory in which the actual simulation **run**s. In order to 
run a simulation, you need a directory where everything is put together, i.e. 
static files, executables for individual component models, namelist, etc. for 
that particular simulation. Most of the time the actual run directory is even a 
subdirectory of `rundir/`, automatically created by the workflow, allowing you 
to run multiple simulations in parallel.

## simres/
`simres` simply contains the raw (not post processed) **sim**ulation 
**res**ults. In addition, some log files are stored with each simulation 
results, containing information about which workflow was used to generate those 
simulation results. If the workflow is used correctly, this log file will 
contain all the information  needed to reproduce the simulation result.

## src/
`src/` contains **s**ou**rc**e code used within the workflow. The most 
prominent of these is the cloned and build [TSMP](https://github.com/HPSCTerrSys/TSMP), 
but other external code is also placed here.

## export_paths.sh
Not directly part of the directory structure, but an important aspect of why 
this structure is used, is the `export_path.sh` script located in `ctrl/`. This 
script is one of the core pieces of code in this workflow, and allows you to run 
the workflow from any location, and even change the location during runtime. 
`export_paths.sh` is loaded at the beginning of each simulation and exports the 
absolute paths to the main directories (the ones above) in environment 
variables. Each script within this workflow in turn uses these environment 
variables to refer to other directories and scripts. This avoids the problem of 
using hard-coded paths, and gives the user full flexibility in where the 
simulation is run.
