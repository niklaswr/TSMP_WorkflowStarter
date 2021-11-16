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

h0=$(TZ=UTC date '+%H' -d "$startDate")
start_finishing.shd0=$(TZ=UTC date '+%d' -d "$startDate")
m0=$(TZ=UTC date '+%m' -d "$startDate")
y0=$(TZ=UTC date '+%Y' -d "$startDate")
dp1=$(TZ=UTC date '+%d' -d "$startDate +1 month")
mp1=$(TZ=UTC date '+%m' -d "$startDate +1 month")
yp1=$(TZ=UTC date '+%Y' -d "$startDate +1 month")

###############################################################################
# finishing
###############################################################################
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
WORK_DIR="${BASE_RUNDIR_TSMP}"
expID="TSMP_3.1.0MCT_cordex11_${y0}_${m0}"
rundir=${WORK_DIR}/${expID}

#echo "--- create SIMRES dir (and sub-dirs) to store simulation results"
new_simres_name="${expid}_$(date '+%Y%m%d' -d "$startDate")"
new_simres=${BASE_SIMRESDIR}/${new_simres_name}

echo "--- gzip and sha512sum individual files in simresdir"
cd ${new_simres}/cosmo
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/cosmo
wait
cd ${new_simres}/parflow
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/parflow
wait
cd ${new_simres}/clm
sha512sum ./* > ./CheckSum.sha512
parallelGzip 48 $new_simres/clm
wait
cd ${new_simres}/restarts
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/restarts
wait

# NWR 20201215
# ARCHIVE is not accessable from computenode, wherefore I need to rethink
# the archiving routine
# write an extra script for tar -cf (direkt to archive) and ln -sf
#echo "-- tar simres/${y0}_${m0}"
#cd ${BASE_SIMRESDIR}
#tar cf ${new_simres_name}.tar -C ${BASE_SIMRESDIR} ${new_simres_name}
#if [[ $? != 0 ]] ; then exit 1 ; fi
#rm -rf ${new_simres}
#
#echo "--- clean/remove rundir"
#rm -r ${rundir}

exit 0

