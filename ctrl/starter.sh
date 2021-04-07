#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-04-01
# USAGE: 
# >> ./$0
# >> ./starter_new.sh

###############################################################################
#### Adjust according to your need BELOW
###############################################################################
NoJ=24              # number of jobs (simulating 24 months -> NoJ=24)
startDate=19790101  # start date
dependency=3525642  # JOBID to depend the following jobs at
                    # if set JOBID is below latest JOBID the job starts without
		    # dependency automatically
simPerJob=6         # number of simulaitons to run within one job (less queuing time?)
                    # -> 6: run 6 simulaitons within one big job
userEmail='n.wagner@fz-juelich.de' 
computeAcount='esmtst'
CTRLDIR=$(pwd)      # assuming one is executing this script from the 
                    # BASE_CTRLDIR, what is the cast most of the time
###############################################################################
#### Adjust according to your need ABOVE
###############################################################################

source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh

# echo for logfile
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- pwd: $(pwd)"
echo "--- Simulation init-date: ${initDate}"
echo "---            CTRLDIR:   ${CTRLDIR}"
echo "--- HOST:  $(hostname)"

cd $BASE_CTRLDIR
# start flat chain jobs
#submit_prepro=$(sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
#	-o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#	--mail-user=$userEmail --account=$computeAcount \
#	submit_prepro.sh 2>&1 | awk '{print $(NF)}')
#echo "prepro: $submit_prepro"

submit_simulation=$dependency # fake $start_simulation for the first time
loop_counter=0
while [ $loop_counter -lt $NoJ ]
do
  # if there are not enough simmulations left to fill the job
  # reduce $simPerJob to number of jobs left
  if [[ $((loop_counter+simPerJob)) -gt $NoJ ]]; then
      echo "-- to less simulations left, run last job with $simPerJob simulations"
      simPerJob=$((NoJ-loop_counter))
  fi
  # Note that $submit_simulation is decoupled from postpro and finishing
  # and therefore the simulaitons are running as fast as possible,
  # since no jobs are executed in between.
  submit_simulation=$(sbatch -d afterok:${submit_simulation} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoJ=$simPerJob \
	  -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
	  --mail-user=$userEmail --account=$computeAcount \
	  submit_simulation.sh 2>&1 | awk '{print $(NF)}')
  echo "simulation for $startDate: $submit_simulation"

  submit_postpro=$(sbatch -d afterok:${submit_simulation} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoJ=$simPerJob \
	  -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
	  --mail-user=$userEmail --account=$computeAcount \
	  submit_postpro.sh 2>&1 | awk '{print $(NF)}')
  echo "postpro for $startDate: $submit_postpro"

  submit_finishing=$(sbatch -d afterok:${submit_postpro} \
	  --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoJ=$simPerJob \
	  -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
	  --mail-user=$userEmail --account=$computeAcount \
	  submit_finishing.sh 2>&1 | awk '{print $(NF)}')
  echo "finishing for $startDate: $submit_finishing"

  loop_counter=$((loop_counter+simPerJob))
  echo "-- started: $startDate + ${simPerJob}"
  startDate=$(date '+%Y%m%d' -d "${startDate} +${simPerJob} month")
done
exit 0
