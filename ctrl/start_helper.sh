#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-08-04
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

parallelGzip() {
    # Idea is taken from:
    # https://www.unix.com/unix-for-dummies-questions-and-answers/117695-gzip-parallelized.html
    cd $2
    DIR=$2
    MAX_PARALLEL=$1
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
