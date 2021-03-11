#!/bin/bash

#SBATCH --job-name="ERA5_prepro"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
##SBATCH --output=Prepro_DE05-out.%j
##SBATCH --error=Prepro_DE05-err.%j
#SBATCH --time=00:10:00
#SBATCH --partition=devel
#SBATCH --mail-type=NONE
#SBATCH --account=jibg35

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-08-04
# USAGE: 
# sbatch --export=ALL,startDate=$startDate,CTRLDIR=$(pwd) -o "./logs/%x-out.%j" -e "./logs/%x-err.%j" start_postpro.sh

# IMPORTANT
# CTRLDIR and initDate HAVE TO be set via sbatch --export command 
# dates in linux follow ISO8601
# https://de.wikipedia.org/wiki/ISO_8601
echo "--- source environment"
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh

###############################################################################
# Prepare
###############################################################################
h0=$(TZ=UTC date '+%H' -d "$initDate")
d0=$(TZ=UTC date '+%d' -d "$initDate")
m0=$(TZ=UTC date '+%m' -d "$initDate")
y0=$(TZ=UTC date '+%Y' -d "$initDate")

# echo for logfile
tmp_filename=$0
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation init-date: ${initDate}"
echo "--- HOST:  $(hostname)"

###############################################################################
# Pre-Pro
###############################################################################
# clear $? before continue
echo $?

# EDIT YOUR POSTPRO STEPS HERE
echo "DEBUG: "
echo "--- THIS STEP IS CURRENTLY EMPTY"

