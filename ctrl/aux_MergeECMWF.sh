#!/usr/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-01-06
#
# Description
#
# USAGE:
# >> ./$0 CTRLDIR YEAR WORKINGDIR
# >> ./aux_MergeECMWF.sh $(pwd) 1992 /p/largedata/slts/shared_data/gamod_ERA5_ECMWF/p.data.regridded_to_030D_covering_EU11/3_hourly_data_output/
#

# take the first argument as initDate ...
CTRLDIR=$1
year=$2
workingdir=$3
initDate=${year}0101

echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source ${BASE_CTRLDIR}/postpro/loadenvs

# NWR 20210106
# length of month is here (true-length - 1) to get last day of month 
# after adding first of month with lenMonth
lenMonth=(30 27 30 29 30 29 30 30 29 30 29 30)

cd $workingdir
for month in {0..11..1}; do
  startDate=$(date '+%Y%m%d' -d "${initDate} + $month month")
  #echo "startDate: ${startDate}"
  endDate=$(date '+%Y%m%d' -d "${startDate} + ${lenMonth[$month]} days")
  #echo "endDate: $endDate"
  echo "-- merge for period $startDate - $endDate"
  grib_copy ERA5_EU11_${startDate}-${endDate}.00-23-03.030D.boundary_*.grib ERA5_EU11_${startDate}-${endDate}.00-23-03.030D.boundary.grib
done
