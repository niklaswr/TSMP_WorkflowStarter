#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> ./$0 CTRLDIR startDate
# >> ./start_finishing.sh $startDate

###############################################################################
# Prepare
###############################################################################
startDate=$1
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-data: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "--- HOST:  $(hostname)"

echo "--- source helper scripts"
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

