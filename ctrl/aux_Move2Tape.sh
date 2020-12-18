#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-12-15
#
# Description
# This script tars a given directory to tape, remove the original directory, 
# and links the created tar-ball form tape to the location of the original 
# directory.
# In addition this works for multiple files, which can be apssed with 
# wildcasts (*,?, etc) -- see USAGE
# This script is aimed for the scope of my usual workflow structur, meaning
# it is based on the usage of the 'export_paths.ksh'. If this script should
# be used outsind this scope, you need to take care about paths set within 
# 'export_paths.ksh' by your self.
#
# USAGE:
# >> ./$0 CTRLDIR PATH/TO/SIMRES/DIR/pattern*
# >> ./aux_Move2Tape.sh $(pwd) /p/scratch/cjibg35/tsmpforecast/era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3/simres/era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3_1980*
#

# take the first argument as initDate ...
CTRLDIR=$1
# .. and assumes every further argument as DATASET
shift 1
simdirs=$@

echo "--- source environment"
source $CTRLDIR/export_paths.ksh

cd ${BASE_SIMRESDIR}
for simdir in $simdirs; do
  if [[ ! -d $simdir ]]; then continue; fi
  simres_name=${simdir##*/}
  echo "working on: $simres_name"
  echo "-- taring"
  tar -cvf ${BASE_ARCROOTDIR}/simres/${simres_name}.tar ${simres_name}
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- remove simresdir"
  #mv ${simres_name} REMOVE_${simres_name} 
  rm -r ${simres_name}
  echo "-- linking"
  ln -sf ${BASE_ARCROOTDIR}/simres/${simres_name}.tar ./
  echo "-- done"
done
