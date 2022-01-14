# Welcome to `FZJ-IBG3_Climatrun-Template` 

# Getting started
First clone this repository (**Setup**) to you project-directory:
``` bash
cd $PROJECT_DIR
git clone --recurse-submodules https://icg4geo.icg.kfa-juelich.de/ModelSystems/tsmp_scripts_tools_engines/FZJ-IBG3_Climatrun-Template.git
```
and export the new path to an environment variable for later use:
``` bash
cd $PROJECT_DIR/FZJ-IBG3_Climatrun-Template
export BASE_ROOT=$(pwd)
```

Than get the **ModelSystem** (TSMP), place under `src` directory, and checkout desired version/tag:
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

Get needed **Static-files** and stoer under geo/ (not final yet...)
``` bash
cd ${BASE_ROOT}/geo
git clone [...]
```

Finally you need to adjust `export_paths.ksh` in the `ctrl` directory:
``` bash
cd $BASE_ROOT/ctrl
vi export_paths.ksh
```
Within this file change the line `rootdir="/p/scratch/cjibg35/tsmpforecast/development/${expid}"` 
according to you `$PROJECT_DIR` from above. To verify `rootdir` is set properly 
do `source $BASE_ROOT/ctrl/export_paths.ksh && echo "$rootdir" && ls -l $rootdir`. You should see the following content:
``` console
PATH/TO/YOUR/PROJECT
CHANGELOG
ctrl
forcing
geo
postpro
README.md
run_INT2LM
run_TSMP
simres
src
```

Now the setup is complete, and can be run after providing proper forcing and restart files. 
Take a look at the [Wiki](https://icg4geo.icg.kfa-juelich.de/ModelSystems/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/wikis/home) to see how to provide those files.

To start a simulation simply execute `starter.sh` from `ctrl`-directory:
``` bash
cd $BASE_ROOT/ctrl
# adjust according to you need between l10 and l31
vi ./starter.sh 
# start the simulation
./starter.sh 
```
