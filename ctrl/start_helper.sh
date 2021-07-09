#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-05-26
# USAGE: 

###############################################################################
# Helper Functions
###############################################################################
resubmit() {
    # call this function anywhere below its declaration with:
    # >> resubmit MESSAGE
    message=$1
    echo "RESUBMIT: going to resubmit!"
    echo "--- -- $message"

    ndate=$(date '+%Y-%m-%dT%H:%M' -d "900 seconds")
    #sbatch --begin=${ndate} cron_starter.ksh ${initDate}
    exit
}

raisERROR() {
    # call this function anywhere below its declaration with:
    # >> raisERROR MESSAGE
    message=$1
    echo "ERROR:"
    echo "--- -- $message"

    exit
}

check4error() {
    # a wraper to check if script/command executed before finished successfully
    # USAGE: check4error $? MESSAGE
    if [[ $1 != 0 ]] ; then
        echo " check4error: $1"
        raisERROR $2
    fi
}

# load function to calculate the number of leapdays between 
# initDate and currentDate
source ${BASE_CTRLDIR}/get_NumLeapDays.sh
# load function to create 'slm_multiprog_mapper.conf' needed by TSMP
source ${BASE_CTRLDIR}/get_MappingConf.sh

parallelGzip() {
    # Idea is taken from:
    # https://www.unix.com/unix-for-dummies-questions-and-answers/117695-gzip-parallelized.html
    cd $2
    DIR=$2
    MAX_PARALLEL=$1
    if [[ ! -d $DIR ]]; then echo "START_HELPER.sh parallelGzip: DIR does not exist --> EXIT" && exit 1; fi
    nroffiles=$(ls $DIR|wc -w)
    (( setsize=nroffiles/MAX_PARALLEL ))
    # catch case if setsize / -n is less or equal 1
    # in this case parallel execution makes no sense
    if [ $setsize -le 1 ]; then 
        gzip ./*
    else
        ls -1 $DIR/* | xargs -n $setsize | while read workset; do
          gzip $workset&
        done
    fi
    wait
}
parallelGunzip() {
    # Idea is taen from:
    # https://www.unix.com/unix-for-dummies-questions-and-answers/117695-gzip-parallelized.html
    cd $2
    DIR=$2
    MAX_PARALLEL=$1
    if [[ ! -d $DIR ]]; then echo "START_HELPER.sh parallelGunzip: DIR does not exist --> EXIT" && exit 1; fi
    nroffiles=$(ls $DIR|wc -w)
    (( setsize=nroffiles/MAX_PARALLEL ))
    # catch case if setsize / -n is less or equal 1
    # in this case parallel execution makes no sense
    if [ $setsize -le 1 ]; then 
        gunzip ./*
    else
        ls -1 $DIR/* | xargs -n $setsize | while read workset; do
          gunzip $workset&
        done
        wait
    fi
}

checkGitStatus() {
  # The simulation status should indicate if 
  # test runs are performed --> simStatus="test"
  # or if 
  # production runs are performed --> simStatus="prod".
  local simStatus=$1
  if [[ $simStatus == "test" ]]; then
    echo "###################"
    echo "You are running under test-mode. No special treatment"
    echo "(--> simStatus is set under export_paths.ksh)"
  elif [[ $simStatus == "prod" ]]; then
    echo "###################"
    echo "You are running under production-mode"
    echo "(--> simStatus is set under export_paths.ksh)"
    # In case of production run, we want a clean working tree to make sure we
    # do track everything with the HISTORY.txt
    if [ -z "$(git status --untracked-files=no --porcelain)" ]; then
      echo "Working directory is clean"
    else
      echo "Uncommitted changes in tracked files"
      echo $(git status --untracked-files=no --porcelain)
      echo "Are you aware of this?"
      echo "Changes not tracked by git are not part of HISTORY.txt"
    fi
    # Further we want a tag at the current commit (git tag --points-at HEAD)
    # to make sure we find this commit again, e.g. in case a rebase was
    # performed which does change the commit-hash
    if [ -z "$(git tag --points-at HEAD)" ]; then
      # No tag at current commit found --> set a tag

      # Fetch current version / tag
      local version=$(git describe --abbrev=0 --tags)
      # Remove the v in the tag v2.1.0 for example
      local version=${version:1}
      # Build array from version string.
      local a=( ${version//./ } )
      # Increase pacth numver in vMAJOR.MINOR.PATCH
      ((a[2]++))
      # Def new version / tag
      local next_version="${a[0]}.${a[1]}.${a[2]}"
      # Set new version / tag
      git tag -a "v$next_version" -m "set by workflow"
    fi
  else
    echo "###################"
    echo "You are running with an unsupported simulation status!"
    echo "simStatus=$simStatus --> EXIT"
    echo "(--> simStatus is set under export_paths.ksh)"
    echo "###################"
    exit 1
  fi
}
