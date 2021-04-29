#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-01-06
#
# Description
# This script copies target .tar to largdata, remove the original directory, 
# and links the copied tar-ball form largdata to the location of the original 
# directory.
# In addition this works for multiple files, which can be passed with 
# wildcasts (*,?, etc) -- see USAGE
# This script is aimed for the scope of my usual workflow structur, meaning
# it is based on the usage of the 'export_paths.ksh'. If this script should
# be used outsind this scope, you need to take care about paths set within 
# 'export_paths.ksh' by yourself.
#
# USAGE:
# >> ./$0 CTRLDIR PATH/TO/SIMRES/DIR/pattern*
# >> ./aux_Move2Large.sh $(pwd) /p/scratch/cjibg35/tsmpforecast/era5climat_eur-11_ecmwf-era5_analysis_fzj-ibg3/postpro/1980_*
#

# take the first argument as initDate ...
CTRLDIR=$1
# .. and assumes every further argument as DATASET
shift 1
tarballs=$@

echo "--- source environment"
source $CTRLDIR/export_paths.ksh

for tarball in $tarballs; do
  tarRootDir=${tarball%/*}
  echo "tarRootDir: $tarRootDir"
  cd $tarRootDir
  # skip if $tarball does not contain tarball...
  if [[ ${tarball##*.} != 'tar' ]]; then continue; fi
  tarball_name=${tarball##*/}
  echo "working on: $tarball_name"
  echo "-- copying"
  cp -v ${tarball_name} ${BASE_LARGEROOTDIR}/postpro/
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- remove simresdir"
  #mv ${tarball_name} REMOVE_${tarball_name} 
  rm -r ${tarball_name}
  echo "-- linking"
  ln -sf ${BASE_LARGEROOTDIR}/postpro/${tarball_name} ./
  echo "-- done"
done
