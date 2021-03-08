#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-03-17
#
# Description
# This script is intened to get data on $ARCHIVE back to spinning disk 
# (restage) once they are really on tape.
# The restaging process is initiated automatically if any action is performed 
# on the data itselfe. So do a inventory of a tar-ball, print the tail or head,
# or copy the data automatically startes the process, but this needs time!
# So best practice would be to start a invetory or other fast taskes in the 
# background and wait until all data are back on spinning disk...
#
# USAGE:
# >> ./$0 CTRLDIR PATH/TO/SIMRES/DIR/TARpattern*
# >> ./aux_restageTape.sh $(pwd) /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/simres/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3_1980*.tar
#

# take the first argument as ctrl ...
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
  echo "-- inentoring"
  tar -tvf ${tarfile_name}
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
