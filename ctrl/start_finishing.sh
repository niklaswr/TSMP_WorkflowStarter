#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-01
# USAGE: 
# >> ./$0 CTRLDIR startDate
# >> ./start_finishing.sh $(pwd) 19790101
# >> ./start_finishing.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/ctrl 19790101

###############################################################################
# Prepare
###############################################################################
CTRLDIR=$1
startDate=$2
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- pwd: $(pwd)"
echo "--- Simulation start-date: ${startDate}"
echo "--- HOST:  $(hostname)"

echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_CTRLDIR}/postpro/loadenvs
cd ${BASE_CTRLDIR}

###############################################################################
# finishing
###############################################################################
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
SimresDir=${BASE_SIMRESDIR}/${formattedStartDate}

echo "--- gzip and sha512sum individual files in simresdir"
cd ${SimresDir}/cosmo
sha512sum ./* > CheckSum.sha512
parallelGzip 48 ${SimresDir}/cosmo
wait
cd ${SimresDir}/parflow
sha512sum ./* > CheckSum.sha512
parallelGzip 48 ${SimresDir}/parflow
wait
cd ${SimresDir}/clm
sha512sum ./* > ./CheckSum.sha512
parallelGzip 48 ${SimresDir}/clm
wait
cd ${SimresDir}/restarts
sha512sum ./* > CheckSum.sha512
parallelGzip 48 ${SimresDir}/restarts
wait

exit 0

