#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE:
# >> ./$0 startDate
# >> ./starter_simulation.sh $startDate

################################################################################
# Prepare
################################################################################
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
echo "---              sim_NTASKS: ${sim_NTASKS}"
echo "---               sim_NODES: ${sim_NODES}"
echo "--- HOST:  $(hostname)"

echo "--- save script start time to calculate total runtime"
scriptStartTime=$(date -u "+%s")

echo "--- source helper scripts"
source $BASE_CTRLDIR/start_helper.sh

################################################################################
# Simulation
################################################################################
# Something TSMP related
# --> aks Abouzar if still needed
export PSP_RENDEZVOUS_OPENIB=-1

formattedStartDate=$(date -u -d "${startDate}" ${dateString})
echo "DEBUG NOW: formattedStartDate: $formattedStartDate"
# NWR 20221201
# Write out everything in ISO-8601. Otherwise this may screwe up with different
# timezones and switch between CET and MESZ
startDate_m1=$(date -u -d -I "+${startDate} - ${simLength}")
formattedStartDate_m1=$(date -u -d "${startDate_m1}" ${dateString})
echo "DEBUG NOW: formattedStartDate_m1: $formattedStartDate_m1"
startDate_p1=$(date -u -d -I "+${startDate} + ${simLength}")
# NWR 20221201
# Write out everything in ISO-8601. Otherwise this may screwe up with different
# timezones and switch between CET and MESZ
formattedStartDate_p1=$(date -u -d "${startDate_p1}" ${dateString})
echo "DEBUG NOW: formattedStartDate_p1: $formattedStartDate_p1"
m0=$(date -u -d "${startDate}" '+%m')
y0=$(date -u -d "${startDate}" '+%Y')
mp1=$(date -u -d "${startDate} + ${simLength}" '+%m')
yp1=$(date -u -d "${startDate} + ${simLength}" '+%Y')
rundir=${BASE_RUNDIR}/${formattedStartDate}
pfidb="ParFlow_EU11_${formattedStartDate}"
pfidb_m1="ParFlow_EU11_${formattedStartDate_m1}"

# Calculate the number of leap-days between initDate and startDate/currentDate
# Those are needed by COSMO to proper calculate start-hours
numLeapDays=$(get_numLeapDays "$initDate" "$startDate")
numLeapDays_p1=$(get_numLeapDays "$initDate" "$startDate_p1")
echo "numLeapDays: ${numLeapDays}"
echo "numLeapDays_p1: ${numLeapDays_p1}"

# Calculate number of hours to simulate
# by calculating the different of (datep1 - date) in hours
numHours=$(datediff_inhour "${startDate}" "${startDate_p1}")
if [[ ${numLeapDays} -lt ${numLeapDays_p1} ]]; then
  echo "DEBUG NOW: HANDLING A LEAP YEAR / MONTH. startDate: ${startDate}"
  echo "numLeapDays_p1 - numLeapDays: $((numLeapDays_p1 - numLeapDays))"
  numHours=$((numHours - (numLeapDays_p1 - numLeapDays)*24))
fi
hstart=$(datediff_inhour "${initDate}" "${startDate}")
hstart=$(( hstart - numLeapDays*24 ))
hstop=$((hstart+numHours))

echo "DEBUG NOW: simLength=$simLength"
echo "DEBUG NOW: numLeapDays=$numLeapDays"
echo "DEBUG NOW: startDate=$startDate"
echo "DEBUG NOW: startDate_p1=$startDate_p1"
echo "DEBUG NOW: numHours=$numHours"
echo "DEBUG NOW: hstart=$hstart"
echo "DEBUG NOW: hstop=$hstop"

################################################################################
# Create rundir
################################################################################
echo "--- try to remove ${rundir} in case already exists"
rm -vr ${rundir}
echo "--- create ${rundir}"
mkdir -vp ${rundir}
cd ${rundir}

################################################################################
# Prepare individual components
# by copying namlist, geo files, and binaries as well as
# modifying the namelists according to variables parts as e.g. the date etc.
################################################################################
source ${BASE_ENVSDIR}/env_simulation
echo "--- -- copying binaries, geo files, and namlists for"
IFS='-' read -ra components <<< "${COMBINATION}"
for component in "${components[@]}"; do
  # COSMO
  if [ "${component}" = "cos" ]; then
	echo "--- -- - cos"
	mkdir -vp ${rundir}/cosmo_out
	cp ${BASE_NAMEDIR}/INPUT_* ${rundir}/
	sed -i "s,__hstart__,${hstart},g" INPUT_IO
	sed -i "s,__hstop__,${hstop},g" INPUT_IO
	sed -i "s,__cosmo_restart_dump_interval__,$hstop,g" INPUT_IO
	sed -i "s,__cosmo_ydir_restart_in__,${BASE_RUNDIR}/restarts/cosmo,g" INPUT_IO
	sed -i "s,__cosmo_ydir_restart_out__,${BASE_RUNDIR}/restarts/cosmo,g" INPUT_IO
	sed -i "s,__cosmo_ydirini__,${BASE_FORCINGDIR}/laf_lbfd/all,g" INPUT_IO
	sed -i "s,__cosmo_ydirbd__,${BASE_FORCINGDIR}/laf_lbfd/all,g" INPUT_IO
	sed -i "s,__cosmo_ydir__,${rundir}/cosmo_out,g" INPUT_IO

	cosmo_ydate_ini=$(date -u -d "${initDate}" '+%Y%m%d%H')
	sed -i "s,__hstart__,$hstart,g" INPUT_ORG
	sed -i "s,__hstop__,$hstop,g" INPUT_ORG
	sed -i "s,__cosmo_ydate_ini__,${cosmo_ydate_ini},g" INPUT_ORG
	sed -i "s,__nprocx_cos_bldsva__,${PROC_COSMO_X},g" INPUT_ORG
	sed -i "s,__nprocy_cos_bldsva__,${PROC_COSMO_Y},g" INPUT_ORG
	cp ${TSMP_BINDIR}/lmparbin_pur ${rundir}/

  # CLM
  elif [ "${component}" = "clm" ]; then
	echo "--- -- - clm"
	cp ${BASE_NAMEDIR}/lnd.stdin ${rundir}/
	nelapse=$((numHours*3600/900+1))
	sed -i "s,__nelapse__,${nelapse},g" lnd.stdin
	start_ymd=$(date -u -d "${startDate}" '+%Y%m%d')
	sed -i "s,__start_ymd__,${start_ymd},g" lnd.stdin
  # Do use `-` prefix for date string to avoid below error:
  # ERROR: value too great for base (error token is "09")
  # Solution found at: https://stackoverflow.com/a/65848366
	tmp_h=$(date -u -d "${startDate}" '+%-H')
	tmp_m=$(date -u -d "${startDate}" '+%-M')
	tmp_s=$(date -u -d "${startDate}" '+%-S')
	start_tod=$((tmp_h*60*60 + tmp_m*60 + tmp_s))
	sed -i "s,__start_tod__,${start_tod},g" lnd.stdin
	clm_restart_date=$(date -u -d "${startDate}" '+%Y-%m-%d')
  clm_restart_sec=$(printf "%05d" ${start_tod=})
	sed -i "s,__clm_restart__,clmoas.clm2.r.${clm_restart_date}-${clm_restart_sec}.nc,g" lnd.stdin
	sed -i "s,__BASE_RUNDIR__,${BASE_RUNDIR},g" lnd.stdin
	sed -i "s,__BASE_FORCINGDIR__,${BASE_FORCINGDIR},g" lnd.stdin
	sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" lnd.stdin
	sed -i "s,__sim_rundir__,${rundir},g" lnd.stdin
	# Check if COMBINATION does contain "cos", so that COSMO ist 
	# used, wherefore CLM does NOT needs forcing files
  if [[ $COMBINATION == *"cos"* ]]; then
	  # replace line matchin *offline_atmdir* with offline_atmdir = ''
	  # NWR test if below has to be filled with something
	  sed -i "s,.*offline_atmdir.*, offline_atmdir = 'BULLSHIT',g" lnd.stdin
	  #sed -i "s,.*offline_atmdir.*, offline_atmdir = '',g" lnd.stdin
  fi
	# 
	cp ${TSMP_BINDIR}/clm ${rundir}/

  # ParFlow
  elif [ "${component}" = "pfl" ]; then
	echo "--- -- - pfl"
        # Export PARFLOW_DIR, which is equal to TSMP_BINDIR, but needed
        # by ParFlow as PARFLOW_DIR
        export PARFLOW_DIR=${TSMP_BINDIR}
	cp ${BASE_NAMEDIR}/coup_oas.tcl ${rundir}/
	cp ${BASE_GEODIR}/parflow/* ${rundir}/
	sed -i "s,__TimingInfo.StopTime__,${numHours},g" coup_oas.tcl
  # Below test if restart file for ParFlow does exist is important!
  # If ParFlow is driven with netCDF files, a non existing ICPressure file
  # will not crash the program, but ParFlow is assuming init pressure of zero 
  # everywhere.
  # So check if file exist and force exit if needed.
  echo "test: ls -1 "${BASE_RUNDIR}/restarts/parflow/${pfidb_m1}.out.*.nc" | tail -1"
  # Just for cold start!
  pfl_restart_file=`ls -1 ${BASE_RUNDIR}/restarts/parflow/${pfidb_m1}.out.*.nc | tail -1`
  if [ -f "${pfl_restart_file}" ]; then
      cp -v ${pfl_restart_file} "${rundir}/"
  else
      echo "ParFlow restart file (${pfl_restart_file}) does not exist --> exit"
      exit 1
  fi
	cp ${BASE_RUNDIR}/restarts/parflow/${pfidb_m1}.out.*.nc .
	ic_pressure=`ls -1 ${pfidb_m1}.out.*.nc | tail -1`
	sed -i "s,__ICPressure__,${ic_pressure},g" coup_oas.tcl
	sed -i "s,__pfidb__,${pfidb},g" coup_oas.tcl
	sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" coup_oas.tcl
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" coup_oas.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" coup_oas.tcl
	# Check if COMBINATION does NOT contain "clm", so that neither COSMO nor
  # CLM ist used, wherefore ParFlow needs forcing files
    if [[ $COMBINATION != *"clm"* ]]; then
	  # Adjust lines if ParFlow forcing is needed
	  evaptransfile="SpinUpForcing_ClimateMean.pfb"
    pfl_EvapTrans="ParFlow_Spinup_30yAve"
	  cp -v ${BASE_FORCINGDIR}/${pfl_EvapTrans}/${evaptransfile} ${rundir}/
          sed -i "s,__EvapTransFile__,"True",g" coup_oas.tcl
          sed -i "s,__EvapTrans_FileName__,"${evaptransfile}",g" coup_oas.tcl
        else
	  # Remove lines if no ParFlow forcing is needed
	  sed -i '/__EvapTransFile__/d' coup_oas.tcl
	  sed -i '/__EvapTrans_FileName__/d' coup_oas.tcl
        fi

	echo "--- execute ParFlow distributeing tcl-scripts "
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_slopes.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_slopes.tcl
	tclsh ascii2pfb_slopes.tcl
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_SoilInd.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_SoilInd.tcl
	tclsh ascii2pfb_SoilInd.tcl
	sed -i "s,__nprocx_pfl_bldsva__,${PROC_PARFLOW_P},g" ascii2pfb_hetPermTen.tcl
	sed -i "s,__nprocy_pfl_bldsva__,${PROC_PARFLOW_Q},g" ascii2pfb_hetPermTen.tcl
	tclsh ascii2pfb_hetPermTen.tcl
  srun -N 1 -n 1 tclsh coup_oas.tcl
  #
	cp ${TSMP_BINDIR}/parflow ${rundir}/
  
  else
	echo "ERROR: unknown component ($component) --> Exit"
	exit 1
  fi
done

# OASIS
echo "--- -- - oasis"
cp ${BASE_GEODIR}/oasis/* ${rundir}/
cp ${BASE_NAMEDIR}/namcouple_${COMBINATION} ${rundir}/namcouple
runTime=$((numHours*3600+900))
sed -i "s,__runTime__,${runTime},g" namcouple

################################################################################
# Prepare slm_multiprog_mapping.conf
# prviding information which component to run at which CPUs
################################################################################
if [ "$COMBINATION" = "clm-cos-pfl" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" \
		$((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}" \
		${PROC_CLM} "./clm"
elif [ "$COMBINATION" = "clm-pfl" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}" \
		${PROC_CLM} "./clm"
elif [ "$COMBINATION" = "clm-cos" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" \
		${PROC_CLM} "./clm"
elif [ "$COMBINATION" = "cos" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		$((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" 
elif [ "$COMBINATION" = "clm" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
		${PROC_CLM} "./clm"
elif [ "$COMBINATION" = "pfl" ]; then
	get_mappingConf ./slm_multiprog_mapping.conf \
    $((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow ${pfidb}"
fi

################################################################################
# Running the simulation
################################################################################
rm -rf YU*
echo "DEBUG: start simulation"
srun --multi-prog slm_multiprog_mapping.conf
if [[ $? != 0 ]] ; then exit 1 ; fi
date
wait

################################################################################
# Moving model-output to simres and storing restart files
# for individual components
################################################################################
echo "--- create SIMRES dir (and sub-dirs) to store simulation results"
new_simres=${BASE_SIMRESDIR}/${formattedStartDate}
echo "--- new_simres: $new_simres"
mkdir -p "$new_simres/restarts"
mkdir -p "$new_simres/log"

echo "--- Moving model-output to simres/ and restarts/"
# looping over all component set in COMBINATION
IFS='-' read -ra components <<< "${COMBINATION}"
for component in "${components[@]}"; do
  # COSMO
  if [ "${component}" = "cos" ]; then
    echo "--- - COSMO"
    # Create component subdir
    mkdir -p "$new_simres/cosmo"
    # Save restart files for next simulation
    # -- COSMO does store the restart files in correct dir already
    # Move model-output to simres/
    cp -v ${rundir}/cosmo_out/* $new_simres/cosmo
    # COSMO writs restart direct to ${BASE_RUNDIR}/restarts/cosmo/
    cosmoRestartFileDate=$(date -u -d "${startDate_p1}" "+%Y%m%d%H")
    cp -v ${BASE_RUNDIR}/restarts/cosmo/lrfd${cosmoRestartFileDate}o $new_simres/restarts
    check4error $? "--- ERROR while moving COSMO model output to simres-dir"
  # CLM
  elif [ "${component}" = "clm" ]; then
    echo "--- - CLM"
    # Create component subdir
    mkdir -p "$new_simres/clm"

    # Do use `-` prefix for date string to avoid below error:
    # ERROR: value too great for base (error token is "09")
    # Solution found at: https://stackoverflow.com/a/65848366
	  tmp_h=$(date -u -d "${startDate_p1}" '+%-H')
	  tmp_m=$(date -u -d "${startDate_p1}" '+%-M')
	  tmp_s=$(date -u -d "${startDate_p1}" '+%-S')
	  start_tod_p1=$((tmp_h*60*60 + tmp_m*60 + tmp_s))
	  clm_restart_date_p1=$(date -u -d "${startDate_p1}" '+%Y-%m-%d')
    clm_restart_sec_p1=$(printf "%05d" ${start_tod_p1})
	  clm_restart_fiel_p1="clmoas.clm2.r.${clm_restart_date_p1}-${clm_restart_sec_p1}.nc"
    
    # Create component subdir

    cp -v ${rundir}/${clm_restart_fiel_p1} ${BASE_RUNDIR}/restarts/clm/
    # Move model-output to simres/
    cp -v ${rundir}/clmoas.clm2.h?.*.nc $new_simres/clm/
    check4error $? "--- ERROR while moving CLM model output to simres-dir"
    cp -v ${BASE_RUNDIR}/restarts/clm/${clm_restart_fiel_p1} $new_simres/restarts/
    check4error $? "--- ERROR while moving CLM model output to simres-dir"
  # PFL
  elif [ "${component}" = "pfl" ]; then
    echo "--- - PFL"
    # Create component subdir
    mkdir -p "$new_simres/parflow"
    # Save restart files for next simulation
    pfl_restart=`ls -1 ${rundir}/${pfidb}.out.?????.nc | tail -1`
    cp -v ${pfl_restart} ${BASE_RUNDIR}/restarts/parflow/
    # Move model-output to simres/
    cp -v ${rundir}/${pfidb}.out.* $new_simres/parflow
    cp -v ${BASE_RUNDIR}/restarts/parflow/${pfidb}.out.?????.nc $new_simres/restarts
    check4error $? "--- ERROR while moving ParFlow model output to simres-dir"
  else
    echo "ERROR: unknown component ($component) --> Exit"
    exit 1
  fi
done

# Wait for all procs to finish than save simres and clean rundir
wait
echo "--- remove write permission from all files in simres"
find ${new_simres} -type f -exec chmod a-w {} \;
echo "--- clean/remove rundir"
rm -r ${rundir}

################################################################################
# Creating HISTORY.txt and store TSMP build log (reusability etc.)
################################################################################
echo "--- save script end time to calculate total runtime"
scriptEndTime=$(date -u "+%s")
totalRunTime_sec=$(($scriptEndTime - $scriptStartTime))
# Oneliner to convert second in %H:%M:%S taken from:
# https://stackoverflow.com/a/39452629
totalRunTime=$(printf '%02dh:%02dm:%02ds\n' $((totalRunTime_sec/3600)) $((totalRunTime_sec%3600/60)) $((totalRunTime_sec%60)))

echo "--- Moving TSMP log to simres/"
cp ${TSMP_BINDIR}/log_all* ${new_simres}/log/TSMP_BuildLog.txt

echo "--- Moving SLURM log to simres/"
cp -v ${BASE_CTRLDIR}/logs/${CaseID}_simulation-??? $new_simres/log/

histfile=${new_simres}/log/HISTORY.txt

cd ${BASE_CTRLDIR}
git diff HEAD > ${new_simres}/log/GitDiffHead_workflow.diff
TAG_WORKFLOW=$(git describe --tags)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)

cd ${BASE_SRCDIR}/TSMP
git diff HEAD > ${new_simres}/log/GitDiffHead_model.diff
TAG_MODEL=$(git describe --tags)
COMMIT_MODEL=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_MODEL=$(git log --pretty=format:'author: %an' -n 1)
DATE_MODEL=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_MODEL=$(git log --pretty=format:'subject: %s' -n 1)
URL_MODEL=$(git config --get remote.origin.url)

cd ${BASE_GEODIR}
git diff HEAD > ${new_simres}/log/GitDiffHead_geo.diff
TAG_GEO=$(git describe --tags)
COMMIT_GEO=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_GEO=$(git log --pretty=format:'author: %an' -n 1)
DATE_GEO=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_GEO=$(git log --pretty=format:'subject: %s' -n 1)
URL_GEO=$(git config --get remote.origin.url)

/bin/cat <<EOM >$histfile
###############################################################################
Author: ${AUTHOR_NAME}
e-mail: ${AUTHOR_MAIL}
version: $(date)

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

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of \`git diff HEAD\` is printed to \`GitDiffHead_workflow.diff\`.
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

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of \`git diff HEAD\` is printed to \`GitDiffHead_model.diff\`.
The specific TSMP build log is stored in \`TSMP_BuildLog.txt\`, enableing to 
exactly reproduce the TSMP build command and sued component versions.
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

To check if no uncommited change is made to above repo, bypassing this tracking,
the output of \`git diff HEAD\` is printed to \`GitDiffHead_geo.diff\`.
###############################################################################
MACHINE: $(cat /etc/FZJ/systemname)
PARTITION: ${SIM_PARTITION}
simStatus: ${SIMSTATUS} 
CaseID: ${CaseID}
###############################################################################
# Total runtime: ${totalRunTime}
###############################################################################
EOM
check4error $? "--- ERROR while creating HISTORY.txt"

echo "ready: TSMP simulation for ${formattedStartDate} is complete!" > ${rundir}/ready.txt

echo "###################################################"
echo "STOP Logging ($(date)):"
echo "--- exe: $0"
echo "###################################################"
exit 0
