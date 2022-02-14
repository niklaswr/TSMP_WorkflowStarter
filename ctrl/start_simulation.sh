#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2022-01-11
# >> ./$0 CTRLDIR startDate
# >> ./starter_simulation.sh $BASE_CTRLDIR $startDate
# >> ./starter_simulation.sh $(pwd) 1979-01-01T00:00Z

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
echo "---            CTRLDIR:   ${BASE_CTRLDIR}"
echo "--- HOST:  $(hostname)"

echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source $BASE_CTRLDIR/start_helper.sh

###############################################################################
# Simulation
###############################################################################
# Something TSMP related
# --> aks Abouzar if still needed
export PSP_RENDEZVOUS_OPENIB=-1

#---------------insert here initial, start and final dates of TSMP simulations----------
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
echo "DEBUG NOW: formattedStartDate: $formattedStartDate"
formattedStartDate_m1=$(date -u -d "${startDate} - ${simLength}" ${dateString})
echo "DEBUG NOW: formattedStartDate_m1: $formattedStartDate_m1"
formattedStartDate_p1=$(date -u -d "${startDate} + ${simLength}" ${dateString})
echo "DEBUG NOW: formattedStartDate_p1: $formattedStartDate_p1"
m0=$(date -u -d "${startDate}" '+%m')
mp1=$(date -u -d "${startDate} + ${simLength}" '+%m')
yp1=$(date -u -d "${startDate} + ${simLength}" '+%Y')
rundir=${BASE_RUNDIR}/${formattedStartDate}
pfidb="cordex0.11_${formattedStartDate}"

# calculate the number of leap-days between initDate and startDate/currentDate
# Those are needed by COSMO to proper calculate start-hours
get_numLeapDays "$initDate" "$startDate"
numLeapDays=$?

#----------numbers of hours for each month--------
if [ "$m0" -eq 02 ]; then
  numHours=672;
elif [ "${m0}" -eq 1 ] || [ "${m0}" -eq 3 ] || [ "${m0}" -eq 5 ] || [ "${m0}" -eq 7 ] || [ "${m0}" -eq 8 ] || [ "${m0}" -eq 10 ] || [ "${m0}" -eq 12 ]; then
  numHours=744;
else  
  numHours=720;
fi
hstart=$(( ($(date -u '+%s' -d "${startDate}") - $(date -u '+%s' -d "${initDate}"))/3600 - numLeapDays*24))
hstop=$((hstart+numHours))

#----------create new rundir---------------------------------------------------
echo "--- try to remove ${rundir} in case already exists"
rm -vr ${rundir}
echo "--- create and fill ${rundir}"
mkdir ${rundir}
#----------copy geodir to new rundir ------------------------------------------
echo "--- -- copying ParFlow geo/ files"
cp ${BASE_GEODIR}/parflow/* ${rundir}/
echo "--- -- copying Oasis geo/ files"
cp ${BASE_GEODIR}/oasis3/* ${rundir}/
#----------copy namedir to new rundir------------------------------------------
echo "--- -- copying namelists form ${BASE_NAMEDIR}"
cp ${BASE_NAMEDIR}/* ${rundir}/
#----------copy binaries to new rundir-----------------------------------------
echo "--- -- copying binaries from ${BASE_BINDIR_TSMP}"
cp ${BASE_BINDIR_TSMP}/clm ${rundir}/
cp ${BASE_BINDIR_TSMP}/lmparbin_pur ${rundir}/
cp ${BASE_BINDIR_TSMP}/parflow ${rundir}/

cd ${rundir}
mkdir ${rundir}/cosmo_out

source ${rundir}/loadenvs

##############################################################
# Modifying COSMO namelists
##############################################################
sed -i "s,__hstart__,${hstart},g" INPUT_IO
sed -i "s,__hstop__,${hstop},g" INPUT_IO
sed -i "s,__cosmo_ydir_restart_in__,${BASE_FORCINGDIR}/restarts/cosmo,g" INPUT_IO
sed -i "s,__cosmo_ydir_restart_out__,${BASE_FORCINGDIR}/restarts/cosmo,g" INPUT_IO
sed -i "s,__cosmo_ydirini__,${BASE_FORCINGDIR}/laf_lbfd/all,g" INPUT_IO
sed -i "s,__cosmo_ydirbd__,${BASE_FORCINGDIR}/laf_lbfd/all,g" INPUT_IO
sed -i "s,__cosmo_ydir__,${rundir}/cosmo_out,g" INPUT_IO

cosmo_ydate_ini=$(date -u -d "${initDate}" '+%Y%m%d%H')
sed -i "s,__hstart__,$hstart,g" INPUT_ORG
sed -i "s,__hstop__,$hstop,g" INPUT_ORG
sed -i "s,__cosmo_ydate_ini__,${cosmo_ydate_ini},g" INPUT_ORG
sed -i "s,__nprocx_cos_bldsva__,${PROC_COSMO_X},g" INPUT_ORG
sed -i "s,__nprocy_cos_bldsva__,${PROC_COSMO_Y},g" INPUT_ORG

##############################################################
# Modifying CLM namelists
##############################################################
nelapse=$((numHours*3600/900+1))
sed -i "s,__nelapse__,${nelapse},g" lnd.stdin
start_ymd=$(date -u -d "${startDate}" '+%Y%m%d')
sed -i "s,__start_ymd__,${start_ymd},g" lnd.stdin
clm_restart=$(date -u -d "${startDate}" '+%Y-%m-%d')
sed -i "s,__clm_restart__,clmoas.clm2.r.${clm_restart}-00000.nc,g" lnd.stdin
sed -i "s,__BASE_FORCINGDIR__,${BASE_FORCINGDIR},g" lnd.stdin
sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" lnd.stdin
sed -i "s,__sim_rundir__,${rundir},g" lnd.stdin

##############################################################
# Modifying ParFlow TCL flags
##############################################################
sed -i "s,__numHours__,${numHours},g" coup_oas.tcl
cp ${BASE_FORCINGDIR}/restarts/parflow/cordex0.11_${formattedStartDate_m1}.out.press.*.pfb .
ic_pressure=`ls -1rt cordex0.11_${formattedStartDate_m1}.out.press.*.pfb | tail -1`
sed -i "s,__ICPressure__,${ic_pressure},g" coup_oas.tcl
sed -i "s,__startDate__,${formattedStartDate},g" coup_oas.tcl
sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" coup_oas.tcl
sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" coup_oas.tcl
sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" coup_oas.tcl
tclsh coup_oas.tcl

echo "--- execute ParFlow distributeing tcl-scripts "
sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_slopes.tcl
sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_slopes.tcl
tclsh ascii2pfb_slopes.tcl
sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_SoilInd.tcl
sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_SoilInd.tcl
tclsh ascii2pfb_SoilInd.tcl

##############################################################
# Modifying OASIS3-MCT namelist
##############################################################
runTime=$((numHours*3600+900))
sed -i "s,__runTime__,${runTime},g" namcouple
sed -i "s,__NPROC_COSMO__,$((PROC_COSMO_X*PROC_COSMO_Y)),g" namcouple
sed -i "s,__NPROC_PARFLOW__,$((PROC_PARFLOW_P*PROC_PARFLOW_Q)),g" namcouple
sed -i "s,__NPROC_CLM__,${PROC_CLM},g" namcouple

##############################################################
# Create 'slm_multiprog_mapping.conf'
##############################################################
get_mappingConf ${PROC_COSMO_X} ${PROC_COSMO_Y} \
    ${PROC_PARFLOW_P} ${PROC_PARFLOW_Q} \
    ${PROC_CLM} \
    ./slm_multiprog_mapping.conf
sed -i "s,__pfidb__,${pfidb},g" slm_multiprog_mapping.conf

##############################################################
# Running the simulation
##############################################################
echo "started" > started.txt
rm -rf YU*
echo "DEBUG: start simulation"
srun --multi-prog slm_multiprog_mapping.conf
if [[ $? != 0 ]] ; then exit 1 ; fi
date
wait

# Needed for git etc
source ${BASE_CTRLDIR}/postpro/loadenvs
##############################################################
# Copy CLM and ParFlow restarts to central directory
# COSMO writes restarts to central directory
##############################################################
echo "DEBUG: start copying restar files"
clm_restart=`ls -1rt clmoas.clm2.r.*00000.nc | tail -1`
cp ${clm_restart} ${BASE_FORCINGDIR}/restarts/clm/
pfl_restart=`ls -1rt ${pfidb}.out.press*.pfb | tail -1`
cp ${pfl_restart} ${BASE_FORCINGDIR}/restarts/parflow/
wait

###############################################################################
# Moving model-output to simres
###############################################################################
echo "--- create SIMRES dir (and sub-dirs) to store simulation results"
new_simres=${BASE_SIMRESDIR}/${formattedStartDate}
echo "--- new_simres: $new_simres"
mkdir -p "$new_simres/cosmo"
mkdir -p "$new_simres/parflow"
mkdir -p "$new_simres/clm"
mkdir -p "$new_simres/int2lm"
mkdir -p "$new_simres/restarts"
check4error $? "--- ERROR while creating simres-dir"

echo "--- move modeloutput to individual simresdir"
cp ${rundir}/cosmo_out/* $new_simres/cosmo
cp ${rundir}/${pfidb}.out.*.pfb $new_simres/parflow
cp ${rundir}/clmoas.clm2.h?.*.nc $new_simres/clm
cp ${BASE_FORCINGDIR}/restarts/cosmo/lrfd${yp1}${mp1}0100o $new_simres/restarts
cp ${BASE_FORCINGDIR}/restarts/parflow/${pfidb}.out.press.?????.pfb $new_simres/restarts
cp ${BASE_FORCINGDIR}/restarts/clm/clmoas.clm2.r.${yp1}-${mp1}-01-00000.nc $new_simres/restarts
check4error $? "--- ERROR while moving model output to simres-dir"
wait

echo "--- clean/remove rundir"
rm -r ${rundir}

###############################################################################
# Creating HISTORY.txt (reusability etc.)
###############################################################################
histfile=$new_simres/HISTORY.txt

cd ${BASE_CTRLDIR}
TAG_WORKFLOW=$(git describe --tags)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)

cd ${BASE_SRCDIR}/TSMP
TAG_MODEL=$(git describe --tags)
COMMIT_MODEL=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_MODEL=$(git log --pretty=format:'author: %an' -n 1)
DATE_MODEL=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_MODEL=$(git log --pretty=format:'subject: %s' -n 1)
URL_MODEL=$(git config --get remote.origin.url)

cd ${BASE_GEODIR}
TAG_GEO=$(git describe --tags)
COMMIT_GEO=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_GEO=$(git log --pretty=format:'author: %an' -n 1)
DATE_GEO=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_GEO=$(git log --pretty=format:'subject: %s' -n 1)
URL_GEO=$(git config --get remote.origin.url)

/bin/cat <<EOM >$histfile
###############################################################################
author: ${AUTHOR_NAME}
e-mail: ${AUTHOR_MAIL}
version: $(date)

This simulation was run under
simStatus=${SIMSTATUS} # "test": test run; "prod": production run
# The simStatus flag does only control a seperat check right before the 
# simulation is submitted, checking if the working tree is clean and if the
# current commit has a tag.
# This way we make sure below information are correct!
###############################################################################
The following setup was used: 
###############################################################################
WORKFLOW 
-- REPO:
${URL_WORKFLOW}
-- LOG: 
tag: ${TAG_WORKFLOW}
${COMMIT_WORKFLOW}
${AUTHOR_WORKFLOW}
${DATE_WORKFLOW}
${SUBJECT_WORKFLOW}
###############################################################################
MODEL
-- REPO:
${URL_MODEL}
-- LOG:
tag: ${TAG_MODEL}
${COMMIT_MODEL}
${AUTHOR_MODEL}
${DATE_MODEL}
${SUBJECT_MODEL}
###############################################################################
GEO
-- REPO:
${URL_GEO}
-- LOG:
tag: ${TAG_GEO}
${COMMIT_GEO}
${AUTHOR_GEO}
${DATE_GEO}
${SUBJECT_GEO}
###############################################################################
EOM
check4error $? "--- ERROR while creating HISTORY.txt"

echo "ready: TSMP simulation for ${formattedStartDate} is complete!" > ready.txt

exit 0
