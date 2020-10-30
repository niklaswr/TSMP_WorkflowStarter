#!/bin/ksh

# author: Niklas WAGNER
# email: n.wagner@fz-juelich.de
# version: 2020-10-12
# USAGE:
# >> source export_paths.ksh

# This file is used to bypass hard coded paths. Therefore all important paths 
# are defined in this file, which is sourced at the beginning of each script.
# The script will then only use the environment variables provided this way. 
# In principle, only the 'rootdir' has to be adjusted, all other paths result 
# from it.
expid="ERA5Climat_EUR-11_ECMWF-ERA5_analysis_FZJ-IBG3-_TSMPv1.2.1_v001JuwelsCpuProdT19802020"
rootdir="/p/scratch/cslts/tsmpforecast/operational/${expid}"
export EXPID="${expid}"
# export needed paths
export BASE_ROOTDIR="${rootdir}"
export BASE_CTRLDIR="${rootdir}/ctrl"
export BASE_EXTDIR="${rootdir}/ctrl/externals"
export BASE_TEMPLATEDIR="${rootdir}/ctrl/template_experiment"
export BASE_FORCINGDIR="${rootdir}/forcing"
export BASE_RUNDIR_TSMP="${rootdir}/run_TSMP"
export BASE_RUNDIR_INT2LM="${rootdir}/run_INT2LM"
export BASE_SIMRESDIR="${rootdir}/simres"
export BASE_POSTPRODDIR="${rootdir}/postprod"
export BASE_SRCDIR="${rootdir}/src"
