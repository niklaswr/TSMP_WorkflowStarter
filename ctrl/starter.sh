#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> ./$0
# >> ./starter_new.sh

###############################################################################
#### Adjust according to your need BELOW
###############################################################################
simLength='1 month'  # length of one simulaiton. Has to be a valid `date` 
                     # option like '1 month', '10 days', etc. (number is 
                     # IMPORTANT!)
                     # AT THE MOMENT simLength>=1day IS NEEDED!
NoS=1                # number of simulations 
startDate="2020-01-01T00:00Z" # start date - is changing while simulation is
                     # progressing.
initDate="2020-01-01T00:00Z"  # init date - is fix for entre simulation 
                     # The format of `startDate` and `initDate` hast to follow 
		                 # ISO norm 8601 --> https://de.wikipedia.org/wiki/ISO_8601
		                 # This is importat to ensure `date` is working properly!
dateString='+%Y%m%d%H' # The date string used to name simulation results etc.
                     # Again, this has to be a valid `date` option
dependency=3556111   # JOBID to depend the following jobs at
                     # if set JOBID is below latest JOBID the job starts without
		                 # dependency automatically
simPerJob=5          # number of simulaitons to run within one job (less queuing 
                     # time?)
                     # -> 6: run 6 simulaitons within one big job
pre=false            # Define which substeps (PREprocessing, SIMulation, 
sim=true             # POStprocessing, FINishing) should be run. Default is to
pos=false            # set each substep to 'true', if one need to run individual 
fin=false            # steps exclude other substeps by setting to 'false'
computeAcount='jjsc39' # jjsc39, slts, esmtst
CTRLDIR=$(pwd)       # assuming one is executing this script from the 
                     # BASE_CTRLDIR, what is the cast most of the time
COMBINATION="clm-cos-pfl" # Set the component model combination run run. 
                     # "cos-clm-pfl" is fully coupled.
		                 # IMPORTANT if CaseMode=true (below) COMBINATION is 
		                 # overwritten by the individual setting in CASE.conf !


CaseMode=true        # true, if running in case mode, false if not.
CaseID="SPINUP"      # already implemented for alter use -- currently NOT used.
                     # This will be needed if I implement the 'CaseMode'


simStatus="test"     # supported are "test" and "prod"
# PROC (processor) distribution of individual component models
PROC_COSMO_X=16
PROC_COSMO_Y=24
PROC_PARFLOW_P=12
PROC_PARFLOW_Q=12
PROC_CLM=48
# def SBATCH for prepro
pre_NODES=1
pre_NTASKS=1
pre_NTASKSPERNODE=1
pre_WALLCLOCK=23:59:00
pre_PARTITION=dc-cpu
pre_MAILTYPE=NONE
# def SBATCH for simulation
# sim_NODES and sim_NTASKS are set automatically based on
# PROC_* further below.
sim_NTASKSPERNODE=128 # 128, 48 
sim_WALLCLOCK=1:59:00
sim_PARTITION=dc-cpu #dc-cpu, mem192, batch, esm
sim_MAILTYPE=NONE
# def SBATCH for postpro
pos_NODES=1
pos_NTASKS=1
pos_NTASKSPERNODE=1
pos_WALLCLOCK=01:59:00
pos_PARTITION=dc-cpu-devel
pos_MAILTYPE=NONE
# def SBATCH for finishing
fin_NODES=1
fin_NTASKS=48
fin_NTASKSPERNODE=48
fin_WALLCLOCK=23:59:00
fin_PARTITION=dc-cpu
fin_MAILTYPE=NONE
###############################################################################
#### Adjust according to your need ABOVE
###############################################################################
# Export those variables set above which are needed in all scripts:
export simLength=${simLength}
export dateString=${dateString}
export initDate=${initDate}
export CaseMode=${CaseMode}
export CaseID=${CaseID}
export PROC_COSMO_X=${PROC_COSMO_X}
export PROC_COSMO_Y=${PROC_COSMO_Y}
export PROC_PARFLOW_P=${PROC_PARFLOW_P}
export PROC_PARFLOW_Q=${PROC_PARFLOW_Q}
export PROC_CLM=${PROC_CLM}
export SIMSTATUS=${simStatus}
export PRE_PARTITION=${pre_PARTITION}
export PRE_NTASKS=${pre_NTASKS}
export SIM_PARTITION=${sim_PARTITION}
export SIM_NTASKS=${sim_NTASKS}
export POST_PARTITION=${pos_PARTITION}
export POST_NTASKS=${pos_NTASKS}
export FIN_PARTITION=${fin_PARTITION}
export FIN_NTASKS=${fin_NTASKS}
# Export simulation information stored in SimInfo.sh as variables:
source ${CTRLDIR}/SimInfo.sh
# Load export_paths.ksh
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh
# In case of CaseMode=true, update some paths exported via 'export_paths.ksh'
# 'updatePathsForCASES()' is located in 'start_helper.sh'
if [ "$CaseMode" = true ]; then
    updatePathsForCASES ${BASE_CTRLDIR}/CASES.conf ${CaseID}
fi
export COMBINATION=${COMBINATION}
TSMPbuild="JURECA_3.1.0MCT_${COMBINATION}" # The TSMP build name.
#TSMPbuild="JUWELS_3.1.0MCT_${COMBINATION}" # The TSMP build name.
                     # This name is automatically created during the TSMP 
		     # builing step (compilation) and typically consists of
		     # JSCMACHINE_TSMPVERSION_COMBINATION. One can look up
		     # this name within the TSMP/bin/ dir.
export TSMP_BINDIR=${BASE_SRCDIR}/TSMP/bin/${TSMPbuild}

# For SIMSTATUS=prod perform two checks:
#  i) Check if git / working tree to be clean. If not print a message to stdout.
# ii) Check current git commit has a tag. If not, create a new tag with 
#     increased digit at patch level.
# The function 'checkGitStatus()' performing above two checks (including the 
# check if SIMSTATUS=prod|test is located in 'start_helper.sh'.
checkGitStatus ${SIMSTATUS}

################################################################################
# Calculate sim_NTASKS
# based on PROC_* and COMBINATION
################################################################################
sim_NTASKS=0
IFS='-' read -ra components <<< "${COMBINATION}"
for component in "${components[@]}"; do
  # COSMO
  if [ "${component}" = "cos" ]; then
    sim_NTASKS=$(( ($PROC_COSMO_X*$PROC_COSMO_Y) + $sim_NTASKS ))
  elif [ "${component}" = "clm" ]; then
    sim_NTASKS=$(( $PROC_CLM + $sim_NTASKS ))
  elif [ "${component}" = "pfl" ]; then
    sim_NTASKS=$(( ($PROC_PARFLOW_P*$PROC_PARFLOW_Q) + $sim_NTASKS ))
  else
    echo "ERROR: unknown component ($component) --> Exit"
    exit 1
  fi
done
sim_NODES=$(((${sim_NTASKS}+${sim_NTASKSPERNODE}-1)/${sim_NTASKSPERNODE}))


# echo for logfile
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- pwd: $(pwd)"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-data: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "---             COMBINATION: ${COMBINATION}"
echo "---              sim_NTASKS: ${sim_NTASKS}"
echo "---               sim_NODES: ${sim_NODES}"
echo "--- HOST:  $(hostname)"

cd $BASE_CTRLDIR
# start flat chain jobs

submit_simulation=$dependency # fake $start_simulation for the first time
submit_prepro=$dependency # fake $start_simulation for the first time
loop_counter=0
while [ $loop_counter -lt $NoS ]
do
  echo "loop_counter $loop_counter / NoS $NoS"
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
    submit_prepro_return=$(sbatch -d afterok:${submit_prepro} \
          --job-name="${CaseID}_prepro" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=${AUTHOR_MAIL} --account=$computeAcount \
          --nodes=${pre_NODES} --ntasks=${pre_NTASKS} \
          --ntasks-per-node=${pre_NTASKSPERNODE} --mail-type=${pre_MAILTYPE} \
          --time=${pre_WALLCLOCK} --partition=${pre_PARTITION} \
	  submit_prepro.sh 2>&1)
          #submit_prepro.sh 2>&1 | awk '{print $(NF)}')
    echo "${submit_prepro_return}"
    submit_prepro=$(echo $submit_prepro_return | awk '{print $(NF)}')
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
    submit_simulation_return=$(sbatch -d afterok:${submit_prepro}:${submit_simulation} \
          --job-name="${CaseID}_simulation" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=${AUTHOR_MAIL} --account=$computeAcount \
          --nodes=${sim_NODES} --ntasks=${sim_NTASKS} \
          --ntasks-per-node=${sim_NTASKSPERNODE} --mail-type=${sim_MAILTYPE} \
          --time=${sim_WALLCLOCK} --partition=${sim_PARTITION} \
	  submit_simulation.sh 2>&1)
	  #submit_simulation.sh 2>&1 | awk 'END{print $(NF)}')
    echo "${submit_simulation_return}"
    submit_simulation=$(echo $submit_simulation_return | awk 'END{print $(NF)}')
    echo "simulation for $startDate: $submit_simulation"
  fi

  if [ "$pos" = false ]; then
    # in case not postprocessing is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_postpro=$submit_simulation
  else
    submit_postpro_return=$(sbatch -d afterok:${submit_simulation} \
          --job-name="${CaseID}_postpro" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=${AUTHOR_MAIL} --account=$computeAcount \
          --nodes=${pos_NODES} --ntasks=${pos_NTASKS} \
          --ntasks-per-node=${pos_NTASKSPERNODE} --mail-type=${pos_MAILTYPE} \
          --time=${pos_WALLCLOCK} --partition=${pos_PARTITION} \
          submit_postpro.sh 2>&1)
          #submit_postpro.sh 2>&1 | awk 'END{print $(NF)}')
    echo "${submit_postpro_return}"
    submit_postpro=$(echo ${submit_postpro_return} | awk 'END{print $(NF)}')
    echo "postpro for $startDate: $submit_postpro"
  fi

  if [ "$fin" = false ]; then
    # in case not postprocessing is not started one need to handle the job
    # dependency manualy by setting to JOBID of substep before
    submit_finishing=$submit_postpro
  else
    submit_finishing_return=$(sbatch -d afterok:${submit_postpro} \
          --job-name="${CaseID}_finishing" \
          --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR,NoS=$simPerJob \
          -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
          --mail-user=${AUTHOR_MAIL} --account=$computeAcount \
          --nodes=${fin_NODES} --ntasks=${fin_NTASKS} \
          --ntasks-per-node=${fin_NTASKSPERNODE} --mail-type=${fin_MAILTYPE} \
          --time=${fin_WALLCLOCK} --partition=${fin_PARTITION} \
          submit_finishing.sh 2>&1)
          #submit_finishing.sh 2>&1 | awk 'END{print $(NF)}')
    echo "${submit_finishing_return}"
    submit_finishing=$(echo ${submit_finishing_return} | awk 'END{print $(NF)}')
    echo "finishing for $startDate: $submit_finishing"
  fi
  
  # UPDATE INCREMENTS
  # Itterate 'simPerJob' times and increment `startDate` to calculate the 
  # new startDate of the next job. This loops to me seems the easyest solution
  # to make use of native `date` increments like ''1 month', '10 days', etc.  
  # And increment `loop_counter` as well...
  i=1; while [ $i -le $simPerJob ]; do
    startDate=$(date -u -d "${startDate} +${simLength}" "+%Y-%m-%dT%H:%MZ")
    ((loop_counter++))
    ((i++))
  done

done
exit 0

