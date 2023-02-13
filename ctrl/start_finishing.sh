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
echo "---             COMBINATION: ${COMBINATION}"
echo "--- HOST:  $(hostname)"

echo "--- source helper scripts"
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_CTRLDIR}/envs/env_finishing
cd ${BASE_CTRLDIR}

###############################################################################
# finishing
###############################################################################
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
SimresDir=${BASE_SIMRESDIR}/${formattedStartDate}

echo "--- gzip and sha512sum individual files in simresdir"
cd ${SimresDir}/cosmo
wrap_calc_sha512sum ${FIN_NTASKS} ./*
parallelGzip ${FIN_NTASKS} ${SimresDir}/cosmo/*
wait
cd ${SimresDir}/parflow
wrap_calc_sha512sum ${FIN_NTASKS} ./*
parallelGzip ${FIN_NTASKS} ${SimresDir}/parflow/*
wait
cd ${SimresDir}/clm
wrap_calc_sha512sum ${FIN_NTASKS} ./*
parallelGzip ${FIN_NTASKS} ${SimresDir}/clm/*
wait
cd ${SimresDir}/restarts
wrap_calc_sha512sum 1 ./*
parallelGzip ${FIN_NTASKS} ${SimresDir}/restarts/*
wait
cd ${SimresDir}/log
wrap_calc_sha512sum 1 ./*
wait

exit 0

