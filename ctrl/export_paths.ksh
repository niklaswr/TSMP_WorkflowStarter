#!/bin/ksh

# author: Niklas WAGNER
# email: n.wagner@fz-juelich.de
# version: 2020-11-16
# USAGE:
# >> source export_paths.ksh

# This file is used to bypass hard coded paths. Therefore all important paths 
# are defined in this file, which is sourced at the beginning of each script.
# The script will then only use the environment variables provided this way. 
# In principle, only the 'rootdir' has to be adjusted, all other paths result 
# from it.
expid="ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3"
rootdir="/p/scratch/cjibg35/tsmpforecast/${expid}"
export EXPID="${expid}"
# export needed paths
export BASE_ROOTDIR="${rootdir}"
export BASE_CTRLDIR="${rootdir}/ctrl"
export BASE_EXTDIR="${rootdir}/ctrl/externals"
export BASE_NAMEDIR="${rootdir}/ctrl/namelists"
export BASE_TEMPLATEDIR="${rootdir}/ctrl/template_experiment"
export BASE_LOGDIR="${rootdir}/ctrl/logs"
export BASE_FORCINGDIR="${rootdir}/forcing"
export BASE_RUNDIR_TSMP="${rootdir}/run_TSMP"
export BASE_RUNDIR_INT2LM="${rootdir}/run_INT2LM"
export BASE_SIMRESDIR="${rootdir}/simres"
export BASE_GEODIR="${rootdir}/geo"
export BASE_POSTPRODIR="${rootdir}/postpro"
export BASE_MONITORINGDIR="${rootdir}/monitoring"
export BASE_SRCDIR="${rootdir}/src"
export BASE_BINDIR="${rootdir}/src/TSMP/bin/JUWELS_3.1.0MCT_clm-cos-pfl"
export PARFLOW_DIR="${BASE_BINDIR}"

# below does accutally not belong her, but I do have no better place.
export BASE_INITDATE="19790101"
export SIMSTATUS="test" # supported are "test" and "prod"
# PROC (processor) distribution of individual component models
export PROC_COSMO_X=16
export PROC_COSMO_Y=18
export PROC_PARFLOW_P=9
export PROC_PARFLOW_Q=8
export PROC_CLM=24
