#!/bin/ksh

# author: Niklas WAGNER
# email: n.wagner@fz-juelich.de
# version: 2022-01-11
# USAGE:
# >> source export_paths.ksh

# This file is used to bypass hard coded paths. Therefore all important paths 
# are defined in this file, which is sourced at the beginning of each script.
# The script will then only use the environment variables provided this way. 
# In principle, only the 'rootdir' has to be adjusted, all other paths result 
# from it.
expid="DETECT_EUR-11_ECMWF-ERA5_evaluation_r1i1p1_FZJ-COSMO5-01-CLM3-5-0-ParFlow3-12-0_vBaseline"
rootdir="/p/scratch/cesmtst/wagner6/${expid}"
export EXPID="${expid}"
# export needed paths
export BASE_ROOTDIR="${rootdir}"
export BASE_CTRLDIR="${rootdir}/ctrl"
export BASE_EXTDIR="${rootdir}/ctrl/externals"
export BASE_ENVSDIR="${rootdir}/ctrl/envs"
export BASE_NAMEDIR="${rootdir}/ctrl/namelists"
export BASE_LOGDIR="${rootdir}/ctrl/logs"
export BASE_FORCINGDIR="${rootdir}/forcing"
export BASE_RUNDIR="${rootdir}/rundir"
export BASE_SIMRESDIR="${rootdir}/simres"
export BASE_GEODIR="${rootdir}/geo"
export BASE_POSTPRODIR="${rootdir}/postpro"
export BASE_MONITORINGDIR="${rootdir}/monitoring"
export BASE_SRCDIR="${rootdir}/src"
