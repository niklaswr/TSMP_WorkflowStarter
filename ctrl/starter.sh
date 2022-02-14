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
export simLength='1 month' # length of one simulaiton. Has to be a valid `date` 
                    # option like '1 month', '10 days', etc. (number is 
                    # IMPORTANT!)
NoS=2               # number of simulations 
startDate="2009-01-01T00:00Z" # start date
                    # The format of `startDate` hast to follow ISO norm 8601
		    # --> https://de.wikipedia.org/wiki/ISO_8601
		    # This is importat to ensure `date` is working properly!
export dateString='+%Y%m%d%H' # The date string used to name simulation results etc.
                    # Again, this has to be a valid `date` option
dependency=3556111  # JOBID to depend the following jobs at
                    # if set JOBID is below latest JOBID the job starts without
		    # dependency automatically
simPerJob=1         # number of simulaitons to run within one job (less queuing 
                    # time?)
                    # -> 6: run 6 simulaitons within one big job
pre=false           # Define which substeps (PREprocessing, SIMulation, 
sim=true            # POStprocessing, FINishing) should be run. Default is to
pos=true            # set each substep to 'true', if one need to run individual 
fin=true            # steps exclude other substeps by setting to 'false'
computeAcount='esmtst'
CTRLDIR=$(pwd)      # assuming one is executing this script from the 
                    # BASE_CTRLDIR, what is the cast most of the time
export CaseID=""    # already implemented for alter use -- currently NOT used.
                    # This will be needed if I implement the 'CaseMode'
# def SBATCH for prepro
pre_NODES=1
pre_NTASKS=1
pre_NTASKSPERNODE=1
pre_WALLCLOCK=01:59:00
pre_PARTITION=esm
pre_MAILTYPE=NONE
# def SBATCH for simulation
sim_NODES=8
sim_NTASKS=384
sim_NTASKSPERNODE=48
sim_WALLCLOCK=01:59:00
sim_PARTITION=devel
sim_MAILTYPE=ALL
# def SBATCH for postpro
pos_NODES=1
pos_NTASKS=1
pos_NTASKSPERNODE=1
pos_WALLCLOCK=23:59:00
pos_PARTITION=esm
pos_MAILTYPE=NONE
# def SBATCH for finishing
fin_NODES=1
fin_NTASKS=48
fin_NTASKSPERNODE=48
fin_WALLCLOCK=23:59:00
fin_PARTITION=esm
fin_MAILTYPE=NONE
###############################################################################
#### Adjust according to your need ABOVE
###############################################################################

source ${CTRLDIR}/export_paths.ksh
userEmail=${AUTHOR_MAIL}
source ${BASE_CTRLDIR}/start_helper.sh
# Check git / working tree status:
# 'checkGitStatus()' is located in 'start_helper.sh'
checkGitStatus ${SIMSTATUS}

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

submit_simulation=$dependency # fake $start_simulation for the first time
submit_prepro=$dependency # fake $start_simulation for the first time
loop_counter=0
while [ $loop_counter -lt $NoS ]
do
  # if there are not enough simmulations left to fill the job
  # reduce $simPerJob to number of jobs left
  if [[ $((loop_counter+simPerJob)) -gt $NoS ]]; then
      echo "-- to less simulations left, to run last job with $simPerJob simulations"
      simPerJob=$((NoS-loop_counter))
  fi

  if [ "$pre" = false ]; then
    # in case not simulation is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_prepro=$dependency
  else
    submit_prepro=$(sbatch -d afterok:${submit_prepro} \
          --job-name="${CaseID}_prepro" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=$userEmail --account=$computeAcount \
          --nodes=${pre_NODES} --ntasks=${pre_NTASKS} \
          --ntasks-per-node=${pre_NTASKSPERNODE} --mail-type=${pre_MAILTYPE} \
          --time=${pre_WALLCLOCK} --partition=${pre_PARTITION} \
          submit_prepro.sh 2>&1 | awk 'END{print $(NF)}')
          #submit_prepro.sh 2>&1 | awk '{print $(NF)}')
    echo "prepro for $startDate: $submit_prepro"
  fi

  # Note that $submit_simulation is decoupled from postpro and finishing.
  # The simulation therby depends on the prepro and itself only, aiming to
  # runn the individual simulations as fast as possible, since no jobs are
  # executed in between.
  if [ "$sim" = false ]; then
    # in case not simulation is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_simulation=$submit_prepro
  else
    submit_simulation=$(sbatch -d afterok:${submit_prepro}:${submit_simulation} \
          --job-name="${CaseID}_simulation" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=$userEmail --account=$computeAcount \
          --nodes=${sim_NODES} --ntasks=${sim_NTASKS} \
          --ntasks-per-node=${sim_NTASKSPERNODE} --mail-type=${sim_MAILTYPE} \
          --time=${sim_WALLCLOCK} --partition=${sim_PARTITION} \
          submit_simulation.sh 2>&1 | awk 'END{print $(NF)}')
    echo "simulation for $startDate: $submit_simulation"
  fi

  if [ "$pos" = false ]; then
    # in case not postprocessing is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_postpro=$submit_simulation
  else
    submit_postpro=$(sbatch -d afterok:${submit_simulation} \
          --job-name="${CaseID}_postpro" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=$userEmail --account=$computeAcount \
          --nodes=${pos_NODES} --ntasks=${pos_NTASKS} \
          --ntasks-per-node=${pos_NTASKSPERNODE} --mail-type=${pos_MAILTYPE} \
          --time=${pos_WALLCLOCK} --partition=${pos_PARTITION} \
          submit_postpro.sh 2>&1 | awk 'END{print $(NF)}')
    echo "postpro for $startDate: $submit_postpro"
  fi

  if [ "$fin" = false ]; then
    # in case not postprocessing is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_finishing=$submit_postpro
  else
    submit_finishing=$(sbatch -d afterok:${submit_postpro} \
          --job-name="${CaseID}_finishing" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=$userEmail --account=$computeAcount \
          --nodes=${fin_NODES} --ntasks=${fin_NTASKS} \
          --ntasks-per-node=${fin_NTASKSPERNODE} --mail-type=${fin_MAILTYPE} \
          --time=${fin_WALLCLOCK} --partition=${fin_PARTITION} \
          submit_finishing.sh 2>&1 | awk 'END{print $(NF)}')
    echo "finishing for $startDate: $submit_finishing"
  fi
  
  # UPDATE INCREMENTS
  # Itterate 'simPerJob' times and increment `startDate` to calculate the 
  # new startDate of the next job. This loops to me seems the easyest solution
  # to make use of native `date` increments like ''1 month', '10 days', etc.  
  # And increment `loop_counter` as well...
  for i in {1..simPerJob}; do
    startDate=$(date -u -d "${startDate} +${simLength}" "+%Y-%m-%dT%H:%MZ")
    ((loop_counter++))
  done

done
exit 0

