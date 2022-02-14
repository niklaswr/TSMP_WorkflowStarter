#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-01
# USAGE: 
# >> ./$0 CTRLDIR startDate
# >> ./starter_prepo.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/ctrl 19790101

echo "--- source environment"
CTRLDIR=$1
startDate=$2
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh

###############################################################################
# Prepare
###############################################################################
# echo for logfile
tmp_filename=$0
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation init-date: ${startDate}"
echo "--- HOST:  $(hostname)"

###############################################################################
# Pre-Pro
###############################################################################
# clear $? before continue
echo $?

# EDIT YOUR POSTPRO STEPS HERE
echo "DEBUG: "
echo "--- THIS STEP IS CURRENTLY EMPTY"

