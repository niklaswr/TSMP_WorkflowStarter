#!/bin/bash
#
#SBATCH --job-name="int2lm"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --output=int2lm.out
#SBATCH --error=int2lm.err
#SBATCH --time=03:00:00
#SBATCH --partition=esm
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=esmtst
#
# author: Liubai POSHYVAILO, Niklas WAGNER
# e-mail: l.poshyvailo@fz-juelich.de, n.wagner@fz-juelich.de
# last modified: 2021-07-06
# USAGE: 
# >> sbatch $0 CTRLDIR
# >> sbatch start_int2lm.sh $(pwd)
# 
###############################################################################
#### Adjust according to your need BELOW
###############################################################################
startDate=20080101  # start date
dependency=3949924  # JOBID to depend the following jobs at
                    # if set JOBID is below latest JOBID the job starts without
                    # dependency automatically
CTRLDIR=$1          # assuming one is executing this script from the
                    # BASE_CTRLDIR, what is the cast most of the time
###############################################################################
#### Adjust according to your need ABOVE
###############################################################################

echo "DEBUG: setup environment"
source ${CTRLDIR}/export_paths.ksh
source ${BASE_NAMEDIR}/loadenv_int2lm

echo "DEBUG: def. individual settings"
start_date=$(TZ=UTC date --date "$startDate")
cur_year=$(TZ=UTC date '+%Y' --date="${start_date}")
int2lm_hstop=240
int2lm_hincbound=3
int2lm_nam_template="INT2LM_template_ERA5"

echo "DEBUG: create INT2LM lm_cat_dir (ex OUTPUT_DIR) dir"
int2lm_LmCatDir="${BASE_RUNDIR_TSMP}/laf_lbfd/${cur_year}"
mkdir -p ${int2lm_LmCatDir}

###############################################################################
# Creating HISTORY.txt (reusability etc.)
###############################################################################
histfile=${int2lm_LmCatDir}/HISTORY.txt
echo "DEBUG: creating HISTORY.txt (reusability etc.)"
cd ${BASE_BINDIR_INT2LM}
TAG_INT2LM=$(git describe --tags)
COMMIT_INT2LM=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_INT2LM=$(git log --pretty=format:'author: %an' -n 1)
DATE_INT2LM=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_INT2LM=$(git log --pretty=format:'subject: %s' -n 1)
URL_INT2LM=$(git config --get remote.origin.url)
cd ${BASE_CTRLDIR}
TAG_WORKFLOW=$(git describe --tags)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)
/bin/cat <<EOM >$histfile
###############################################################################
The following setup was used:
###############################################################################
INT2LM version
-- REPO:
${URL_INT2LM}
-- LOG: 
tag: ${TAG_INT2LM}
${COMMIT_INT2LM}
${AUTHOR_INT2LM}
${DATE_INT2LM}
${SUBJECT_INT2LM}
###############################################################################
WORKFLOW (for INT2LM namelist etc)
-- REPO:
${URL_WORKFLOW}
-- LOG:
tag: ${TAG_WORKFLOW}
${COMMIT_WORKFLOW}
${AUTHOR_WORKFLOW}
${DATE_WORKFLOW}
${SUBJECT_WORKFLOW}
###############################################################################
EOM
check4error $? "--- ERROR while creating HISTORY.txt"

echo "DEBUG: copy INT2LM executable to BASE_RUNDIR_INT2LM"
cp ${BASE_BINDIR_INT2LM}/${BASE_INT2LM_EXNAME} ${BASE_RUNDIR_INT2LM}/

#--------------------------------
# last changes: L.Poshyvailo, 2020
# In the following for loop int2lm processes 240 hours(10 days) of data in one
# cycle, correcponds to hstop=240 (in INPUT_template); use like this for grb 
# output. In case of .nc output it is possible to increase hstop (as needed) 
# and to not use ii loop
# To process one complete year (365 days) int2lm is run in 40 cycles. Last few 
# cycles may be dummy cycles where int2lm will not produce any output.
# replace ii<=40 -- cycles of 10 days; depending on the calendar, 
# run Jan-Feb for the leap years, and then Mar-Dec.
for ((ii=1; ii<=40; ii++))
do
  echo "DEBUG start_date: ${start_date}"
  int2lm_start_date=$(TZ=UTC date '+%Y%m%d%H' --date="${start_date}")
  echo "DEBUG: int2lm_start_date: ${int2lm_start_date}"

  echo "DEBUG: copy namelist for current loop"
  cp ${BASE_NAMEDIR}/${int2lm_nam_template} ${BASE_RUNDIR_INT2LM}/INPUT

  echo "DEBUG: modify namelist (sed inserts etc.)"
  sed "s,__start_date__,${int2lm_start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__init_date__,${int2lm_start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__hstop__,${int2lm_hstop},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__hincbound__,${int2lm_hincbound},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__ext_dir__,${BASE_EXTDIR},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__in_cat_dir__,${BASE_FORCINGDIR}/ERA5/${cur_year},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__lm_cat_dir__,${int2lm_LmCatDir},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
 
  echo "DEBUG: enter INT2LM rundir and start INT2LM"
  cd ${BASE_RUNDIR_INT2LM}
  rm -rf YU*  
  srun ./${BASE_INT2LM_EXNAME}
  # exit loop / script, if something crashed int2lm
  if [[ $? != 0 ]] ; then exit 1 ; fi
  wait

  start_date=$(TZ=UTC date --date="${start_date} + ${int2lm_hstop} hours")
  #start_date=$(TZ=UTC date --date="${start_date} + $(( ${int2lm_hstop} + ${int2lm_hincbound} )) hours")
done
