#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-01
# USAGE: 
# >> ./$0 CTRLDIR startDate
# >> ./starter_postpro.sh $(pwd) 19790101
# >> ./starter_postpro.sh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/ctrl 19790101

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

h0=$(date '+%H' -d "$startDate")
d0=$(date '+%d' -d "$startDate")
m0=$(date '+%m' -d "$startDate")
y0=$(date '+%Y' -d "$startDate")

###############################################################################
# Post-Pro
###############################################################################
# Place post-processing steps here
# NOTE: scripts HAVE to run on compute-nodes.
# If the script runs in parralel or on single cpu is not important
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
SimresDir="${BASE_SIMRESDIR}/${y0}_${m0}"
ToPostProDir="${BASE_RUNDIR}/ToPostPro/${y0}_${m0}"
PostProStoreDir="${BASE_POSTPRODIR}/${y0}_${m0}"

# Create individual subdir in ToPostPro to copy model-output
# there. I want to seperate modeloutput first, to be 100%
# sure modelputput is not changed by post-pro scripts (cdo, nco)
mkdir -p ${ToPostProDir}/cosmo_out
mkdir -p ${ToPostProDir}/parflow_out
mkdir -p ${ToPostProDir}/clm_out

# copy model-output to ToPostPro subdir
cp ${SimresDir}/cosmo/* ${ToPostProDir}/cosmo_out/
cp ${SimresDir}/parflow/cordex0.11_${y0}_${m0}.out.*.pfb ${ToPostProDir}/parflow_out/
cp ${SimresDir}/clm/clmoas.clm2.h0.${y0}-${m0}*.nc ${ToPostProDir}/clm_out/

cd ${BASE_CTRLDIR}
postpro_initDate=$(date '+%Y%m%d%H' -d "${initDate}")
postpro_startDate=$(date '+%Y%m%d%H' -d "${startDate}")
postpro_YYYY_MM=$(date '+%Y_%m' -d "${startDate}")
echo "--- START subscript postproWraper.sh"
./postproWraper.sh $postpro_initDate $postpro_startDate $postpro_YYYY_MM
if [[ $? != 0 ]] ; then exit 1 ; fi
echo "--- END subscript postproWraper.sh"

echo "-- deleting ${ToPostProDir}"
rm -vr ${ToPostProDir}

echo "-- calculating checksum for postpro/${y0}_${m0}"
cd ${BASE_POSTPRODIR}/${y0}_${m0}
sha512sum ./* > "CheckSum.sha512"
if [[ $? != 0 ]] ; then exit 1 ; fi

echo "-- START monitoring"
# clean up -- just to be sure there are no conflicts
rm -rf ${BASE_MONITORINGDIR}/${y0}_${m0}
# create saveDir
mkdir -p ${BASE_MONITORINGDIR}/${y0}_${m0}
# run monitoring script
cd ${BASE_CTRLDIR}/monitoring/
python monitoring.py \
	--configFile ./CONFIG \
	--dataRootDir ${BASE_POSTPRODIR}/${y0}_${m0} \
	--saveDir ${BASE_MONITORINGDIR}/${y0}_${m0}
if [[ $? != 0 ]] ; then exit 1 ; fi
echo "--- END monitoring"

exit 0
