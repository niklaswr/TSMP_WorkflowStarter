#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> ./$0 $startDate
# >> ./starter_postpro.sh $startDate

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
source ${BASE_CTRLDIR}/envs/env_postpro

h0=$(date -u -d "$startDate" '+%H')
d0=$(date -u -d "$startDate" '+%d')
m0=$(date -u -d "$startDate" '+%m')
y0=$(date -u -d "$startDate" '+%Y')

###############################################################################
# Post-Pro
###############################################################################
# Place post-processing steps here
# NOTE: scripts HAVE to run on compute-nodes.
# If the script runs in parralel or on single cpu is not important
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
pfidb="cordex0.11_${formattedStartDate}"
SimresDir="${BASE_SIMRESDIR}/${formattedStartDate}"
ToPostProDir="${BASE_RUNDIR}/ToPostPro/${y0}_${m0}"
PostProStoreDir="${BASE_POSTPRODIR}/${formattedStartDate}"
mkdir -vp ${PostProStoreDir} 

# Create individual subdir in ToPostPro to copy model-output
# there. I want to seperate modeloutput first, to be 100%
# sure modelputput is not changed by post-pro scripts (cdo, nco)
echo "DEBUG: Create subdirs within ToPostPro"
mkdir -vp ${ToPostProDir}/cosmo_out
mkdir -vp ${ToPostProDir}/parflow_out
mkdir -vp ${ToPostProDir}/clm_out

# copy model-output to ToPostPro subdir
echo "DEBUG: copy modeloutput to subdirs within ToPostPro"
cp -v ${SimresDir}/cosmo/* ${ToPostProDir}/cosmo_out/
cp -v ${SimresDir}/parflow/${pfidb}.out.*.pfb ${ToPostProDir}/parflow_out/
cp -v ${SimresDir}/clm/clmoas.clm2.h0.${y0}-${m0}*.nc ${ToPostProDir}/clm_out/

cd ${BASE_CTRLDIR}
postpro_initDate=$(date -u '+%Y%m%d%H' -d "${initDate}")
postpro_startDate=$(date -u '+%Y%m%d%H' -d "${startDate}")
postpro_YYYY_MM=$(date -u '+%Y_%m' -d "${startDate}")
echo "DEBUG: START subscript postproWraper.sh"
./postproWraper.sh $postpro_initDate $postpro_startDate $postpro_YYYY_MM
if [[ $? != 0 ]] ; then exit 1 ; fi
echo "--- END subscript postproWraper.sh"

# Bewlo is a workaround, to not touch `postproWrapper.sh` as this is kind of 
# messy and I dont want to interfere.
# So `postrpoWrapper.sh` is storing the output to `${BASE_POSTPRODIR}/YYYY_MM`
# But I want to store under `${BASE_POSTPRODIR}/${formattedStartDate}` aka
# `PostProStoreDir`
cp -r ${BASE_POSTPRODIR}/${postpro_YYYY_MM}/* ${PostProStoreDir}/
check4error $? "--- ERROR ctrl/start_postpro.sh while workaround. Search this line within the code for explanation"
rm -r ${BASE_POSTPRODIR}/${postpro_YYYY_MM}/
echo "DEBUG: deleting ${ToPostProDir}"
rm -vr ${ToPostProDir}

echo "DEBUG: calculating checksum for postpro/${formattedStartDate}"
cd ${PostProStoreDir} 
sha512sum ./* > "CheckSum.sha512"
if [[ $? != 0 ]] ; then exit 1 ; fi

echo "-- START monitoring"
# clean up -- just to be sure there are no conflicts
rm -rf ${BASE_MONITORINGDIR}/${formattedStartDate}
# create saveDir
mkdir -p ${BASE_MONITORINGDIR}/${formattedStartDate}
# run monitoring script
cd ${BASE_CTRLDIR}/monitoring/
python monitoring.py \
	--configFile ./CONFIG \
	--dataRootDir ${BASE_POSTPRODIR}/${formattedStartDate} \
	--saveDir ${BASE_MONITORINGDIR}/${formattedStartDate}
if [[ $? != 0 ]] ; then exit 1 ; fi
echo "--- END monitoring"

exit 0
