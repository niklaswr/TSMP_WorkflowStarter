#!/usr/bin/bash
#
#SBATCH --job-name="AUX_gzip"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --time=00:30:00
#SBATCH --partition=devel
#SBATCH --account=jibg35
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-03-24
#
# Description
# This script do compress files within given dir(s), tars this dir to largdata, 
# remove the original directory(s), and links the created tar-ball form largdata 
# to the location of the original directory.
#
# USAGE:
# >> ./$0 TARGET/DIR SOURCE/DIR/pattern*
# >> ./$0
#

TARGET=$1
# .. and assumes every further argument as SOURCES (there is a plural s!)
shift 1
SOURCES=$@

for SOURCE in $SOURCES; do
  # ski if targetdir is not a directory
  if [[ ! -d $SOURCE ]]; then continue; fi
  source_name=${SOURCE##*/}
  echo "working on: $source_name"
  echo "-- taring"
  cd ${SOURCE%/*}
  tar -cvf ${TARGET}/${source_name}.tar ${source_name}
  if [[ $? != 0 ]] ; then echo "ERROR" && exit 1 ; fi
  echo "-- remove source"
  #mv ${source_name} REMOVE_${source_name} 
  rm -r ${source_name}
  echo "-- linking"
  ln -sf ${TARGET}/${source_name}.tar ./
  echo "-- done"
done
