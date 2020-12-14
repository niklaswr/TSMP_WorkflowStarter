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
expid="era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3"
rootdir="/p/scratch/cjibg35/tsmpforecast/${expid}"
export EXPID="${expid}"
# export needed paths
export BASE_ROOTDIR="${rootdir}"
export BASE_CTRLDIR="${rootdir}/ctrl"
export BASE_EXTDIR="${rootdir}/ctrl/externals"
export BASE_TEMPLATEDIR="${rootdir}/ctrl/template_experiment"
export BASE_LOGDIR="${rootdir}/ctrl/logs"
export BASE_FORCINGDIR="${rootdir}/forcing"
export BASE_RUNDIR_TSMP="${rootdir}/run_TSMP"
export BASE_RUNDIR_INT2LM="${rootdir}/run_INT2LM"
export BASE_SIMRESDIR="${rootdir}/simres"
export BASE_POSTPRODIR="${rootdir}/postpro"
export BASE_SRCDIR="${rootdir}/src"
export BASE_ARCROOTDIR="${ARCHIVE_jibg33}/tsmpforecast/${expid}"
export PARFLOW_DIR="${rootdir}/src/TSMP/bin/JUWELS_3.1.0MCT_clm-cos-pfl"
