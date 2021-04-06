#!/bin/bash
#
#SBATCH --job-name="ERA5_simulation"
#SBATCH --nodes=12
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=48
#SBATCH --time=23:59:00
#SBATCH --partition=batch
#SBATCH --mail-type=ALL
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-01
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoJ=6 \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_simulation.sh

# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command 
# 1) CTRLDIR (tell the program where the ctrl dir of the workflow sit)
# 2) startDate (tell the program for which month to start the sim)
# 3) NoJ (tell the programm how many jobs/simulations/month to start)
echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source $BASE_CTRLDIR/start_helper.sh

###############################################################################
# Prepare
###############################################################################
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation start-date: ${startDate}"
echo "---            CTRLDIR:   ${BASE_CTRLDIR}"
echo "--- HOST:  $(hostname)"

loop_counter=1
while [ $loop_counter -le $NoJ ]
do
  cd $BASE_CTRLDIR
  ./start_simulation.sh $BASE_CTRLDIR $startDate
  if [[ $? != 0 ]] ; then exit 1 ; fi
  # forward startDate by one month
  startDate=$(date '+%Y%m%d' -d "$startDate + 1 month")
  loop_counter=$((loop_counter+1))
  wait
done
