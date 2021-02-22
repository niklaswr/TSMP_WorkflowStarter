#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-02-09
#
# Description
# This script is the inverse of `aux_Scratch2Tape` and 
# does retrieves data stored on Tape and linked to simres back to simres.
# This works for multiple files, which can be apssed with wildcasts 
# (*,?, etc) -- see USAGE
# This script is aimed for the scope of my usual workflow structur, meaning
# it is based on the usage of the 'export_paths.ksh'. If this script should
# be used outsind this scope, you need to take care about paths set within 
# 'export_paths.ksh' by your self.
#
# USAGE:
# >> ./$0 CTRLDIR PATH/TO/SIMRES/DIR/TARpattern*
# >> ./aux_Tape2Scratch.sh $(pwd) /p/scratch/cjibg35/tsmpforecast/era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3/simres/era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3_1980*.tar
#

# take the first argument as initDate ...
CTRLDIR=$1
# .. and assumes every further argument as DATASET
shift 1
tarfiles=$@

echo "--- source environment"
source $CTRLDIR/export_paths.ksh

cd ${BASE_SIMRESDIR}
for tarfile in $tarfiles; do
  # skip if $tarfile is not a file (or link to file)
  if [[ ! -f $tarfile ]]; then continue; fi
  tarfile_name=${tarfile##*/}
  echo "working on: $tarfile_name"
  echo "-- un-taring"
  tar -xvf ${tarfile_name} --directory ./
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
