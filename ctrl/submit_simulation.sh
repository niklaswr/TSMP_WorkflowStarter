#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2022-02-11
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=6 \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_simulation.sh

# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command 
# 1) CTRLDIR (tell the program where the ctrl dir of the workflow sit)
# 2) startDate (tell the program for which date to start the simulation)
# 3) NoS (tell the programm how many simulations to start)
###############################################################################
# Prepare
###############################################################################
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


loop_counter=1
while [ $loop_counter -le $NoS ]
do
  cd $BASE_CTRLDIR
  ./start_simulation.sh $BASE_CTRLDIR $startDate
  if [[ $? != 0 ]] ; then exit 1 ; fi
  # forward startDate by one month
  startDate=$(date -u -d "${startDate} + ${simLength}" "+%Y-%m-%dT%H:%MZ")
  # increment loop counter
  ((loop_counter++))
  wait
done
