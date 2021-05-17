#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-26
#
# Description:
# This script does tar given sourc-dir(s) to given target-dir, 
# removes the original directory(s), and links the created tar-ball form 
# target-dir to the location of the original directory.
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
