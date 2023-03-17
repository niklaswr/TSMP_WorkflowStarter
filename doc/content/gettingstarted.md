# Getting Started 

## Set up the Workflow
First clone this repository (**Workflow / Setup**) to you project-directory:
``` bash
cd $PROJECT_DIR
git clone --recurse-submodules https://icg4geo.icg.kfa-juelich.de/nwagner/FZJ-IBG3_WorkflowStarter.git
```
and export the new path to an environment variable for later use:
``` bash
cd $PROJECT_DIR/FZJ-IBG3_WorkflowStarter
export BASE_ROOT=$(pwd)
```

Than get the **ModelSystem** (TSMP), place under `src` directory, checkout 
desired version/tag, and export TSMP path for later use as well:
``` bash
cd $BASE_ROOT/src
git clone https://github.com/HPSCTerrSys/TSMP.git
cd TSMP
git checkout v1.2.3
export TSMP_DIR=$(pwd)
```
Get TSMP component models (COSMO, ParFlow, CLM, Oasis)
``` bash
cd ${TSMP_DIR}
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/cosmo5.01_fresh.git
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/parflow3.2_fresh.git
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/clm3.5_fresh.git
git clone https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_src/oasis3-mct.git
mv cosmo5.01_fresh cosmo5_1
mv parflow3.2_fresh parflow3_2
mv clm3.5_fresh clm3_5
```
Patch `ParFlow` to enable writing out `et.pfb` where usually compilation with CLM is needed, but not possible with TSMP:
``` bash
patch ${TSMP_DIR}/parflow3_2/pfsimulator/parflow_lib/solver_richards.c ${BASE_ROOT}/ctrl/externals/ParFlowPatches/patch2writeSourceAndSinksWithoutCLM/patch_solver_richards.c
```
Compile TSMP
``` bash
cd $TSMP_DIR/bldsva
./build_tsmp.ksh -v 3.1.0MCT -c clm-cos-pfl -m JUWELS -O Intel
```

Get needed **Static-files**, stoer under `geo/`, and check out desired 
version/tag:
``` bash
cd ${BASE_ROOT}/geo
git clone https://icg4geo.icg.kfa-juelich.de/Configurations/TSMP_statfiles_IBG3/TSMP_EU11.git
cd TSMP_EU11
git checkout v2.0.0
```

Finally you need to adjust `export_paths.ksh` in the `ctrl/` directory:
``` bash
cd $BASE_ROOT/ctrl
vi export_paths.ksh
```
Within this file change the line `rootdir="/p/scratch/cjibg35/tsmpforecast/development/${expid}"` 
according to you `$PROJECT_DIR` from above. To verify `rootdir` is set properly 
do `source $BASE_ROOT/ctrl/export_paths.ksh && echo "$rootdir" && ls -l $rootdir`. You should see the following content:
``` console
PATH/TO/YOUR/PROJECT
ctrl
forcing
geo
monitoring
postpro
README.md
rundir
simres
src
Template_CHANGELOG
```

Now the setup is complete, and can be run after providing proper restart and forcing files. 

## Provide restart files
To continue a simulation restart-files are needed defining the initial state of the simulation. 
Since big simulations as we do aim for (simulation period of years to several decades) are usually calculated as a sequence of smaller simulations (simulation period of days to months) each simulation represents a restart from the last state of the simulation before. Therefore one have to provide restart files for each component and simulation.
 
Within this workflow the component models expect the individual restart files at: 
```bash
$BASE_ROOT/forcing/restarts/COMPONENT_MODEL
``` 
During the usual progress of this workflow the restart-files are placed there automatically. Only for the very first simulation the user have to provide restart-files manually to initialize the simulation. Therefore it has to be known that COSMO is able to run without restart-files, than running a cold-start, while CLM and ParFlow always expect restart-files. Thus the user have to provide restart-files for ParFlow and CLM only.   

In this example we do run a simulation over EUR11 domain for the year 2020, for which restart files could be taken from:
```
/p/largedata/jibg33/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run/restarts
``` 
Do contact `n.wagner@fz-juelich` for permission.

To provide the restart file do move to the restart directory, copy the restart 
files there, and rename ParFlow restart file according to the need of this workflow:
``` bash
cd $BASE_ROOT/forcing/restarts
# copy CLM restart file
cp /p/largedata/jibg33/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run/restarts/clm/clmoas.clm2.r.2020-01-01-00000.nc ./clm/
# copy ParFlow restart file
cp /p/largedata/jibg33/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run/restarts/parflow/cordex0.11_2019_12.out.press.00248.pfb ./parflow/
mv ./parflow/cordex0.11_2019_12.out.press.00248.pfb ./parflow/cordex0.11_2019120100.out.press.00248.pfb
```
**NOTE**: ParFlow needs the previous model-outpt as restart-file (`2019_12.*.00248.pfb`) where CLM needs a special restart-file from the current time-step (`2020-01-01-00000.nc`)

## Provide forcing (boundary) files
COSMO is a local model, simulating only a subdomain of the globe and therefore needs to be informed about incoming meteorological conditions passing the boundary (as e.g. low pressure systems). This is done via so called *local boundary files* (short `lbf`). At the same time the status quo of the Atmosphere for the first time-step is needed (not equal to restart-files!). In the meteorological realm this status quo is call 'analysis', wherefore this information is passed to COSMO with so called 'local analysis files' (short `laf`).

This two kind of boundary files need to be provided for each simulation and are expected by the workflow to be stored under:
``` bash 
$BASE_ROOT/forcing/laf_lbfd/all
```

In this example we do run a simulation over EUR11 domain for the year 2020, for which forcing files could be taken from:
```
/p/largedata/jibg33/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run/laf_lbfd/
``` 
Do contact `n.wagner@fz-juelich` for permission.

To proper provide those files, do extract related `.tar` archive, uncompress all files inside, and link those files to `$BASE_ROOT/forcing/laf_lbfd/all`
``` bash
# extract boundary fiels to desrired location
cd $BASE_ROOT/forcing/laf_lbfd/
tar -xvf /p/largedata/jibg33/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run/laf_lbfd/2020.tar --directory ./
# uncompress boundary-files
cd $BASE_ROOT/ctrl
sbatch ./aux_gunzip.ksh 48 $BASE_ROOT/forcing/laf_lbfd/2020/*
# link boundary files to all/
cd $BASE_ROOT/forcing/laf_lbfd/all
ln -sf ../2020/l* ./
```
`aux_gunzip.ksh` is a wrapper to run the uncompromising (`gunzip`) on compute-node in parallel. This simply speeds up the uncompromising progress as each year contains lots of boundary files, which will take a very long time on a single CPU.

## Start a simulation
To start a simulation simply execute `starter.sh` from `ctrl`-directory:
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
3) Write down which information / data / files you might think are needed to repoduce the simulation.
4) Think about how you could check the simulation is running fine while runtime.

