#!/bin/bash
#
#SBATCH --job-name="ERA5_postpro"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=23:59:00
#SBATCH --partition=batch
#SBATCH --mail-type=NONE

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-12-11
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoJ=6 \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_postpro.sh

# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command
# 1) CTRLDIR (tell the program where the ctrl dir of the workflow sit)
# 2) startDate (tell the program for which month to start the sim)
# 3) NoJ (tell the programm how many jobs to start)
###############################################################################
# Prepare
###############################################################################
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation start-date: ${startDate}"
echo "--- HOST:  $(hostname)"

echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_CTRLDIR}/postpro/loadenvs

###############################################################################
# Post-Pro
###############################################################################
loop_counter=1
while [ $loop_counter -le $NoJ ]
do
  cd $BASE_CTRLDIR
  ./start_postpro.sh $BASE_CTRLDIR $startDate
  if [[ $? != 0 ]] ; then exit 1 ; fi
  # forward startDate by one month
  startDate=$(date '+%Y%m%d' -d "$startDate + 1 month")
  loop_counter=$((loop_counter+1))
  wait
done
exit 0

