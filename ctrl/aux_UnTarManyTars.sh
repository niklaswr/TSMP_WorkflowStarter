#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-20
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
# >> ./$0 PATH/TO/TAR/BALS/patterns*
# >> ./aux_UnTarManyTars.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/postpro/1980*
#

tarballs=$@

for tarball in $tarballs; do
  tarRootDir=${tarball%/*}
  echo "tarRootDir: $tarRootDir"
  cd $tarRootDir
  # skip if $tarball does not contain tarball...
  if [[ ${tarball##*.} != 'tar' ]]; then continue; fi
  tarName=${tarball##*/}
  echo "working on: $tarName"
  echo "-- untaring"
  tar -xvf ./${tarName} --directory ./
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
