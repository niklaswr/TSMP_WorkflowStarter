# Getting Started 

## Set up the TSMP_WorkflowStarter

**First**, clone this repository into your project-directory with its 
dependencies marked with Git submodules, 

``` bash
cd $PROJECT_DIR
git clone --recurse-submodules https://github.com/niklaswr/TSMP_WorkflowStarter.git
```

and export the following path to an environment variable for later use.

``` bash
cd $PROJECT_DIR/TSMP_WorkflowStarter
export BASE_ROOT=$(pwd)
```

**Second**, get TSMP ready by cloning all component models (COSMO, ParFlow, 
CLM, and Oasis) into `src/TSMP/`, 

``` bash
cd ${TSMP_DIR}
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/cosmo5.01_fresh.git  cosmo5_1
git clone -b v3.12.0 https://github.com/parflow/parflow.git                             parflow
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/clm3.5_fresh.git     clm3_5
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/oasis3-mct.git       oasis3-mct
```
----
I guess not needed sinde ParFlow write .nc 
----
Patch `ParFlow` to enable writing out `et.pfb` where usually compilation with CLM is needed, but not possible with TSMP:
``` bash
patch ${TSMP_DIR}/parflow3_2/pfsimulator/parflow_lib/solver_richards.c ${BASE_ROOT}/ctrl/externals/ParFlowPatches/patch2writeSourceAndSinksWithoutCLM/patch_solver_richards.c
```
----
I guess not needed sinde ParFlow write .nc 
----
and build the binaries.

``` bash
cd $TSMP_DIR/bldsva
git apply ${BASE_ROOT}/ctrl/externals/TSMP_Patch/ClmSendZero.patch
./build_tsmp.ksh --readclm=true -v 3.1.0MCT -c clm-cos-pfl -m JURECA -O Intel
```

**Finally**, adapt `ctrl/export_paths.sh` to correctly determine the root 
directory of this workflow:

``` bash
cd $BASE_ROOT/ctrl
vi export_paths.sh
```

Within this file change the line   
`rootdir="/p/scratch/cesmtst/wagner6/${expid}"`   
according to you `$PROJECT_DIR` from above. To verify `rootdir` is set properly 
do   
`source $BASE_ROOT/ctrl/export_paths.sh && echo "$rootdir" && ls -l $rootdir`.    
You should see the following content:

```
PATH/TO/YOUR/PROJECT
ctrl/
doc/
forcing/
geo/
LICENSE
monitoring/
postpro/
README.md
rundir/
simres/
src/
```

The setup is now complete, and can be run after providing proper restart and 
forcing files. 

## Provide restart files

To continue a simulation, restart-files are needed to define the initial 
state of the simulation. Since large simulations (simulation period of years / 
several decades), such as we are aiming for, are usually calculated as a 
sequence of shorter simulations (simulation period of days / months), each 
simulation represents a restart of the previous simulation. Therefore, restart 
files must be provided for each component and simulation.

Within this workflow, the component models expect the individual restart files 
to be located at:

```bash
$BASE_ROOT/rundir/MainRun/restarts/COMPONENT_MODEL
``` 

During the normal course of this workflow, the restart files are automatically 
placed there. Only for the very first simulation the user has to provide 
restart files manually to initialise the simulation. Therefore it is important 
to know that COSMO is able to run without restart files, than running a 
cold-start, while CLM and ParFlow always expect restart-files. So the user 
only needs to provide restart-files for ParFlow and CLM only.

In this example, we do run a simulation over the EUR-11 domain for the year 
1970, for which restart files could be taken from:

```
/PATH/TO/SOME/RESTART/FILES
``` 

Do request access to the data project jjibg33 via [JuDoor](https://judoor.fz-juelich.de/login).

To make the restart files available, go to the restart directory, copy the 
restart files there, and rename the ParFlow restart file according to the 
needs of this workflow:

``` bash
cd $BASE_ROOT/rundir/MainRun/restarts
# copy CLM restart file
cp XXXX ./clm/
# copy ParFlow restart file
cp XXXX ./parflow/
mv XXXX YYYY
```
**NOTE**: 
ParFlow needs the previous model-outpt as a restart-file 
(`XXXX`), whereas CLM needs a special restart-file from the 
current time-step (`YYYY`)

## Provide forcing (boundary) files

COSMO is a local model, simulating only a subdomain of the globe, and therefore 
needs to be informed about incoming meteorological conditions passing the 
boundary (as e.g. low pressure systems). This is done using local boundary 
files (lbf for short). At the same time, the status quo of the atmosphere is 
needed for the first time step (not to be confused with restart files!). In 
the meteorological domain this status quo is called ‘analysis’, wherefore this 
information is passed to COSMO with so called ‘local analysis files’  (laf for 
short).

These two types of boundary files must to be provided for each simulation and 
are expected by the workflow to be stored under:

``` bash 
$BASE_ROOT/forcing/laf_lbfd/all
```

In this example, we do run a simulation over the EUR-11 domain for the year 
1970, for which restart files could be taken from:

```
/PATH/TO/SOME/FORCING
``` 

Do request access to the data project jjibg33 via [JuDoor](https://judoor.fz-juelich.de/login).

To properly provide these files, do extract related `.tar` archive, uncompress 
all files inside, and link those files to `$BASE_ROOT/forcing/laf_lbfd/all`
``` bash
# extract boundary fiels to desrired location
cd $BASE_ROOT/forcing/laf_lbfd/
tar -xvf XXX.tar --directory ./
# uncompress boundary-files
cd $BASE_ROOT/ctrl
sbatch ./aux_gunzip.sh $BASE_ROOT/forcing/laf_lbfd/1970/*gz
# link boundary files to all/
cd $BASE_ROOT/forcing/laf_lbfd/all
ln -sf ../1971/l* ./
```

`aux_gunzip.sh` is a wrapper for running uncompromising (gunzip) in parallel 
on compute node. This simply speeds up the progress of uncompromising, as each 
year requires many boundary files, which takes a very long time on a single CPU.

## Start a simulation

To start a simulation simply execute `starter.sh` from `ctrl` directory:

``` bash
cd $BASE_ROOT/ctrl
# adjust according to you need between 
# 'Adjust according to your need BELOW'
# and
# 'Adjust according to your need ABOVE'
vi ./starter.sh 
# start the simulation
./starter.sh 
```

## Exercice
To become a little bit famillar with this workflow, work on the following tasks:

1) Do simulate the compleat year of 2020.
2) Plot a time serie of the spatial averaged 2m temperature for 2020.
3) Write down which information / data / files you might think are needed to 
   repoduce the simulation.
4) Think about how you could check the simulation is running fine during 
   runtime.

