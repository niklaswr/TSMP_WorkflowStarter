#!/bin/bash

#SBATCH --job-name="ERA5_starter"
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=ERA5Clima_starter-out.%j
#SBATCH --error=ERA5Clima_starter-err.%j
#SBATCH --time=00:05:00
#SBATCH --mail-type=NONE
#SBATCH --partition=devel
#SBATCH --account=jibg35

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-12-11
# USAGE: sbatch --export=ALL,startDate=YYYYMMDD,months=X,CTRLDIR="PATH/TO/CRTL/DIR" starter.sh

# IMPORTANT
# initDate HASE TO be set via sbatch --export command
###############################################################################
# Prepare
###############################################################################
# import/export global paths and variables (e.g. $EXPID)
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh

# echo for logfile
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation init-date: ${initDate}"
echo "---            CTRLDIR:   ${CTRLDIR}"
echo "--- HOST:  $(hostname)"

cd $BASE_CTRLDIR
# start flat chain jobs
start_prepro=$(sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
	-o "${BASE_LOGDIR}/%x-out.%j" -e "${BASE_LOGDIR}/%x-err.%j" \
	start_prepro.sh 2>&1 | awk '{print $(NF)}')
echo $start_prepro

start_simulation=$start_prepro
loop_counter=1
while [ $loop_counter -le $months ]
do
  # Note that $start_simulation is overwritten with the next lines,
  # that postpro and finishing are running decoupled from the main-loop
  # and therefore the simulaitons are running as fast as possible,
  # sinde no jobs in between are executed.
  start_simulation=$(sbatch -d afterok:${start_simulation} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
	  -o "${BASE_LOGDIR}/%x-out.%j" -e "${BASE_LOGDIR}/%x-err.%j" \
	  start_simulation.sh 2>&1 | awk '{print $(NF)}')
  echo $start_simulation

  start_postpro=$(sbatch -d afterok:${start_simulation} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
	  -o "${BASE_LOGDIR}/%x-out.%j" -e "${BASE_LOGDIR}/%x-err.%j" \
	  start_postpro.sh 2>&1 | awk '{print $(NF)}')
  echo $start_postpro

  start_finishing=$(sbatch -d afterok:${start_postpro} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
	  -o "${BASE_LOGDIR}/%x-out.%j" -e "${BASE_LOGDIR}/%x-err.%j" \
	  start_finishing.sh 2>&1 | awk '{print $(NF)}')
  echo $start_finishing

  loop_counter=$[${loop_counter}+1]
  echo "-- started: $startDate"
  startDate=$(date '+%Y%m%d' -d "${startDate} +1 month")
done
exit 0
