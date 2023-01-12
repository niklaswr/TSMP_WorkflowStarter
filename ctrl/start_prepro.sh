#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> ./$0 startDate

echo "--- source helper script"
startDate=$1
source ${BASE_CTRLDIR}/start_helper.sh

###############################################################################
# Prepare
###############################################################################
# echo for logfile
tmp_filename=$0
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-data: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "--- HOST:  $(hostname)"

###############################################################################
# Pre-Pro
###############################################################################
# clear $? before continue
echo $?

# EDIT YOUR POSTPRO STEPS HERE
echo "DEBUG: "
echo "--- THIS STEP IS CURRENTLY EMPTY"

