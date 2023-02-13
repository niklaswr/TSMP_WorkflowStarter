#!/bin/bash
# Using a 'strict' bash.
set -x
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 

addTimeInfoAndSplitVar() {
  # Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
  # This funciton does add time information (nc-units, nc-calendar), split for 
  # individual variables pressure, saturation, and evaptrans, and does store the 
  # in new output file
  #
  #echo "DEBUG: just entered addTimeInfoAndSplitVar()"
  tmp_StartDate=$1
  tmp_Calendar=$2
  tmp_OutDir=$3
  tmp_griddes=$4
  tmp_inFile=$5
  tmp_filePath="${inFile%/*}"
  tmp_fileName="${inFile##*/}"
  tmp_fileName="${tmp_fileName%.nc}"
  tmp_fileExt="${inFile##*.}"

  # NWa 20230206
  # The option to add proper grid-information is implemented and could be
  # added to below CDO comamnds with `-setgrid,${tmp_griddes}`. However, is
  # is taking some time and data gets CMORIzed anyway, so I did not activated
  # this yet.

  # Use NCO to add time units, as CDO is (whyever) not recognizing the 
  # original time variable and overwrite to time=0. For further steps CDO can 
  # be used, as this is bit more straight forward to use.
  timeUnit=$(date -u -d "${tmp_StartDate}" "+%Y-%-m-%-d %H:%M:%S") 
  # Do the actual work, add time info and split
  fileName_addTimeUnits="${tmp_fileName}_withTimeUnit.nc_tmp"
  ncatted -a units,time,o,c,"hours since ${timeUnit}" \
    "${tmp_inFile}" "${tmp_OutDir}/${fileName_addTimeUnits}"
  # ET is sort of ParFlow/CLM intern output, and is dumped first with
  # first time step (*.00001.*). So do not try to extract ET from ParFlow 
  # output for step zero (*.00000.*) (using regex oprator =~)
  if [[ "${tmp_fileName}" =~ .*"00000".* ]]; then
    cdo -L -f nc4c -z zip_1 \
      -setcalendar,${tmp_Calendar} -selvar,time,pressure \
      "${tmp_OutDir}/${fileName_addTimeUnits}" \
      "${tmp_OutDir}/${tmp_fileName}_pressure.nc"
    cdo -L -f nc4c -z zip_1 \
      -setcalendar,${tmp_Calendar} -selvar,time,saturation \
      "${tmp_OutDir}/${fileName_addTimeUnits}" \
      "${tmp_OutDir}/${tmp_fileName}_saturation.nc"
  else
    cdo -L -f nc4c -z zip_1 \
      -setcalendar,${tmp_Calendar} -selvar,time,pressure \
      "${tmp_OutDir}/${fileName_addTimeUnits}" \
      "${tmp_OutDir}/${tmp_fileName}_pressure.nc"
    cdo -L -f nc4c -z zip_1 \
      -setcalendar,${tmp_Calendar} -selvar,time,saturation \
      "${tmp_OutDir}/${fileName_addTimeUnits}" \
      "${tmp_OutDir}/${tmp_fileName}_saturation.nc"
    cdo -L -f nc4c -z zip_1 \
      -setcalendar,${tmp_Calendar} -selvar,time,evaptrans \
      "${tmp_OutDir}/${fileName_addTimeUnits}" \
      "${tmp_OutDir}/${tmp_fileName}_evaptrans.nc"
  fi
}

# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# This function is a wrapper to keep start_postpro.sh clean and easy to read.
# The aim of this function is to loop over all origin ParFlow output files, 
# add nc time information, and split for individual variables.
# To run this in 'parallel' this wrapper function is calling the actual 
# function and handles MAX_PARALLEL
tmpStartDate=$1
shift
tmpCalendar=$1
shift
tmpOutDir=$1
shift
MAX_PARALLEL=$1
shift
tmp_griddes=$1
shift
inFiles=$@

# set some helper-vars
tmp_parallel_counter=0
for inFile in $inFiles
do
  addTimeInfoAndSplitVar ${tmpStartDate} ${tmpCalendar} ${tmpOutDir} \
    ${tmp_griddes} ${inFile} &
  # Count how many tasks are already started, and wait if MAX_PARALLEL
  # (set to max number of available CPU) is reached.
  (( tmp_parallel_counter++ ))
  if [ $tmp_parallel_counter -ge $MAX_PARALLEL ]; then
    # If MAX_PARALLEL is reached wait for all tasks to finsh before continue
    wait
    tmp_parallel_counter=0
  fi
done
wait
