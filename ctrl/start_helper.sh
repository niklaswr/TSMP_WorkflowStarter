#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 

###############################################################################
# Helper Functions
###############################################################################
raisERROR() {
    # call this function anywhere below its declaration with:
    # >> raisERROR MESSAGE
    message=$1
    echo "ERROR:"
    echo "--- -- $message"

    exit 9
}

check4error() {
    # a wraper to check if script/command executed before finished successfully
    # USAGE: check4error $? MESSAGE
    if [[ $1 != 0 ]] ; then
        echo " check4error: $1"
        raisERROR "$2"
    fi
}

# load function to calculate the number of leapdays between 
# initDate and currentDate
source ${BASE_CTRLDIR}/get_NumLeapDays.sh

get_mappingConf() {
  #----------------------------------------------------------------------------
  # This script does generically create the 'slm_multiprog_mapping.conf ' file
  # needed by TSMP
  # Bases on the individual proc distribution this is written to the form:
  #   0-(XXX-1)     ./XXX_exe
  #   XXX-(YYY-1)   ./YYY_exe
  #   YYY-(ZZZ-1)   ./ZZZ_exe
  #   [...]
  # USAGE:
  # >> get_mappingConf ./OUTFILE \
  #      $((${PROC_COSMO_X} * ${PROC_COSMO_Y})) "./lmparbin_pur" \
  #      $((${PROC_PARFLOW_P} * ${PROC_PARFLOW_Q})) "./parflow __pfidb__" \
  #      ${PROC_CLM} "./clm"
  # Whereby OUTFILE is used as output
  #----------------------------------------------------------------------------

  # Create empty OUTFILE
  OUTFILE=$1
  :> $OUTFILE

  # Loop over otther arguments to fill OUTFILE
  shift 1
  PROCm1=0
  while [ $# -gt 0 ]; do
      PROC=$(( ${PROCm1} + $1 - 1 ))
      EXE=$2
/bin/cat <<EOM >>${OUTFILE}
${PROCm1}-${PROC} ${EXE}
EOM
      PROCm1=$(( ${PROC} + 1 ))
      shift 2
  done
}

parallelGzip() {
  MAX_PARALLEL=$1
  shift
  echo "MAX_PARALLEL: $MAX_PARALLEL"
  inFiles=$@
  echo "${inFiles[@]}"
  # set some helper-vars
  tmp_parallel_counter=0
  for inFile in $inFiles
  do
    gzip ${inFile} &
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
}

parallelGunzip() {
  MAX_PARALLEL=$1
  shift
  echo "MAX_PARALLEL: $MAX_PARALLEL"
  inFiles=$@
  echo "${inFiles[@]}"
  # set some helper-vars
  tmp_parallel_counter=0
  for inFile in $inFiles
  do
    gunzip ${inFile} &
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
}

calc_sha512sum() (
  # Simple calculates the sha512 sum for given file.
  # Assuming to get abs. paths to file, spliting into PATH and FILE to cd into
  # PATH first to get proper stats in CheckSum.sha512
  inFile=$1
  inFilePath="${inFile%/*}"
  inFileName="${inFile##*/}"
  cd ${inFilePath}
  sha512sum ${inFileName} >> "checksum.sha512"
)
wrap_calc_sha512sum() {
  MAX_PARALLEL=$1
  shift
  echo "MAX_PARALLEL: $MAX_PARALLEL"
  inFiles=$@
  echo "${inFiles[@]}"
  # set some helper-vars
  tmp_parallel_counter=0
  for inFile in $inFiles
  do
    calc_sha512sum ${inFile} &
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
}

checkGitStatus() {
  # The simulation status should indicate if 
  # test runs are performed --> simStatus="test"
  # or if 
  # production runs are performed --> simStatus="prod".
  # colored text output:
  red=`tput setaf 1`
  green=`tput setaf 2`
  reset=`tput sgr0`
  local simStatus=$1
  if [[ $simStatus == "test" ]]; then
    echo "###################################################"
    echo "${green}You are running under test-mode. No special treatment${reset}"
    echo "(--> simStatus is set in starter.sh)"
  elif [[ $simStatus == "prod" ]]; then
    echo "###################################################"
    echo "You are running under production-mode"
    echo "(--> simStatus is set in starter.sh)"
    # In case of production run, we want a clean working tree to make sure we
    # do track everything with the HISTORY.txt
    if [ -z "$(git status --untracked-files=no --porcelain)" ]; then
      echo "${green}Working directory is clean${reset}"
    else
      echo "${red}Uncommitted changes in tracked files${reset}"
      echo $(git status --untracked-files=no --porcelain)
      echo "${red}Are you aware of this?${reset}"
      echo "${red}Changes not tracked by git are not part of HISTORY.txt${reset}"
    fi
    ## Further we want a tag at the current commit (git tag --points-at HEAD)
    ## to make sure we find this commit again, e.g. in case a rebase was
    ## performed which does change the commit-hash
    #if [ -z "$(git tag --points-at HEAD)" ]; then
    #  # No tag at current commit found --> set a tag
    #
    #  # Fetch current version / tag
    #  local version=$(git describe --abbrev=0 --tags)
    #  # Remove the v in the tag v2.1.0 for example
    #  local version=${version:1}
    #  # Build array from version string.
    #  local a=( ${version//./ } )
    #  # Increase pacth numver in vMAJOR.MINOR.PATCH
    #  ((a[2]++))
    #  # Def new version / tag
    #  local next_version="${a[0]}.${a[1]}.${a[2]}"
    #  # Set new version / tag
    #  git tag -a "v$next_version" -m "set by workflow"
    #fi
    ## Further we want a tag at the current commit (git tag --points-at HEAD)
    ## to make sure we find this commit again, e.g. in case a rebase was
    ## performed which does change the commit-hash
    #if [ -z "$(git tag --points-at HEAD)" ]; then
    #  # No tag at current commit found --> set a tag
    #
    #  # Fetch current version / tag
    #  local version=$(git describe --abbrev=0 --tags)
    #  # Remove the v in the tag v2.1.0 for example
    #  local version=${version:1}
    #  # Build array from version string.
    #  local a=( ${version//./ } )
    #  # Increase pacth numver in vMAJOR.MINOR.PATCH
    #  ((a[2]++))
    #  # Def new version / tag
    #  local next_version="${a[0]}.${a[1]}.${a[2]}"
    #  # Set new version / tag
    #  git tag -a "v$next_version" -m "set by workflow"
    #fi
  else
    echo "###################"
    echo "You are running with an unsupported simulation status!"
    echo "simStatus=$simStatus --> EXIT"
    echo "(--> simStatus is set under starter.sh)"
    echo "###################"
    exit 1
  fi
}

datediff_inhour() {
  d1=$(date -u -d "$1" +%s)
  d2=$(date -u -d "$2" +%s)
  # sec --> hour: 1/(60*60) --> 1/(3600)
  hours=$(( (d2 - d1) / 3600 ))
  echo "$hours"
}

updatePathsForCASES() {
    # Author: Niklas WAGNER
    # E-mail: n.wagner@fz-juelich.de
    # Version: 2022-06-01
    # Description:
    # This function does update the paths which are exported as environmental 
    # variables within the export_paths.ksh. The update is needed if the 
    # workflow is running in CaseMode to ensure all simulations are 
    # running within its own sub directory to avoid interference.
    # IMPORTANT
    # Make sure this is called after 'export_paths.ksh' is sourced
    ConfigFile=$1
    CaseID=$2
    CASENAMEDIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-NAMEDIR)
    export BASE_NAMEDIR="${BASE_NAMEDIR}${CASENAMEDIR}"
    CASEFORCINGDIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-FORCINGDIR)
    export BASE_FORCINGDIR="${BASE_FORCINGDIR}${CASEFORCINGDIR}"
    CASERUNDIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-RUNDIR)
    export BASE_RUNDIR="${BASE_RUNDIR}${CASERUNDIR}"
    CASESIMRESDIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-SIMRESDIR)
    export BASE_SIMRESDIR="${BASE_SIMRESDIR}${CASESIMRESDIR}"
    CASEGEODIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-GEODIR)
    export BASE_GEODIR="${BASE_GEODIR}${CASEGEODIR}"
    CASEPOSTPRODIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-POSTPRODIR)
    export BASE_POSTPRODIR="${BASE_POSTPRODIR}${CASEPOSTPRODIR}"
    CASEMONITORINGDIR=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-MONITORINGDIR)
    export BASE_MONITORINGDIR="${BASE_MONITORINGDIR}${CASEMONITORINGDIR}"
    CaseName=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-NAME)
    export CaseName="${CaseName}"
    CaseCalendar=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-CALENDAR)
    export CaseCalendar="${CaseCalendar}"
    CaseCombination=$(git config -f ${ConfigFile} --get ${CaseID}.CASE-COMBINATION)
    export COMBINATION="${CaseCombination}"
}
