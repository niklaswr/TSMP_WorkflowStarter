#!/usr/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
#
# Description:
# In addition this works for multiple files, which can be apssed with 
# wildcasts (*,?, etc) -- see USAGE
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

  tarNameNoExtention=${tarName%.tar} 
  # the order of the -C flag is important!
  # ref: https://stackoverflow.com/questions/9249603/how-to-extract-a-single-file-from-tar-to-a-different-directory
  #tar --exclude=${tarNameNoExtention}/pressure.nc -xvf ./${tarName} -C /p/scratch/cslts/tsmpforecast/WADKlim/OBSrun/postpro ${tarNameNoExtention}/gwr.nc
  tar -xvf ./${tarName} -C ./
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- done"
done
