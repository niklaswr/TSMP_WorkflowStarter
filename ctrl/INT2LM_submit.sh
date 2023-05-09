#!/bin/bash -x
#
#SBATCH --job-name="int2lm"
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=128
#SBATCH --output=int2lm.out
#SBATCH --error=int2lm.err
#SBATCH --time=23:59:00
#SBATCH --partition=dc-cpu
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=jjsc39
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de;
#                 Liuba POSHYVAILO, l.poshyvailo@fz-juelich.de
# USAGE: 
# >> sbatch $0 CTRLDIR
# >> sbatch INT2LM_submit.sh $(pwd)
# 
###############################################################################
#### Adjust according to your need BELOW
###############################################################################
startDate=19700101  # start date
int2lm_hstop=8784   # --> 366 * 24h
dependency=3949924  # JOBID to depend the following jobs at
                    # if set JOBID is below latest JOBID the job starts without
                    # dependency automatically
CTRLDIR=$1          # assuming one is executing this script from the
                    # BASE_CTRLDIR, what is the cast most of the time
# PROC (processor) distribution for int2lm
PROCX_INT2LM=16
PROCY_INT2LM=8
PROCIO_INT2LM=0
###############################################################################
#### Adjust according to your need ABOVE
###############################################################################

echo "DEBUG: setup environment"
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh
export INT2LM_BINDIR="${BASE_SRCDIR}/int2lm3.00"
export INT2LM_EXNAME="int2lm3.00"
source ${BASE_ENVSDIR}/loadenv_int2lm

h0=$(date -u -d "$startDate" '+%H')
d0=$(date -u -d "$startDate" '+%d')
m0=$(date -u -d "$startDate" '+%m')
y0=$(date -u -d "$startDate" '+%Y')

echo "DEBUG: def. individual settings"

echo "DEBUG: create INT2LM lm_cat_dir dir"
int2lm_LmCatDir="${BASE_FORCINGDIR}/laf_lbfd/${y0}"
mkdir -p ${int2lm_LmCatDir}

echo "DEBUG: create INT2LM rundir"
rundir="${BASE_RUNDIR}/INT2LM_${y0}"
mkdir -p ${rundir}

################################################################################
# Creating HISTORY.txt (reusability etc.)
################################################################################
histfile=${int2lm_LmCatDir}/HISTORY.txt
echo "DEBUG: creating HISTORY.txt (reusability etc.)"
cd ${INT2LM_BINDIR}
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
date executed: ${y0}-${m0}-${d0}
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

echo "DEBUG: copy INT2LM executable to rundir"
cp ${INT2LM_BINDIR}/${INT2LM_EXNAME} ${rundir}/

echo "DEBUG start_date: ${start_date}"
int2lm_start_date=${y0}${m0}${d0}${h0}

echo "DEBUG: int2lm_start_date: ${int2lm_start_date}"

echo "DEBUG: copy namelist for current loop"
cp ${BASE_NAMEDIR}/INT2LM/INPUT ${rundir}/INPUT

echo "DEBUG: modify namelist (sed inserts etc.)"
sed "s,__start_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__init_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__hstop__,${int2lm_hstop},g" -i ${rundir}/INPUT
sed "s,__lm_ext_dir__,${BASE_GEODIR}/TSMP_EUR-11/static/int2lm,g" -i ${rundir}/INPUT
sed "s,__in_ext_dir__,${BASE_FORCINGDIR}/ERA5raw/INT2LM_inext,g" -i ${rundir}/INPUT
sed "s,__in_cat_dir__,${BASE_FORCINGDIR}/ERA5raw/${y0},g" -i ${rundir}/INPUT
sed "s,__lm_cat_dir__,${int2lm_LmCatDir},g" -i ${rundir}/INPUT
sed "s,__nprocx_int2lm__,${PROCX_INT2LM},g" -i ${rundir}/INPUT
sed "s,__nprocy_int2lm__,${PROCY_INT2LM},g" -i ${rundir}/INPUT
sed "s,__nprocio_int2lm__,${PROCIO_INT2LM},g" -i ${rundir}/INPUT
 
echo "DEBUG: enter INT2LM rundir and start INT2LM"
cd ${rundir}
# just to be sure, clean rundir before starting (e.g. in case of restart)
rm -rf YU*  
srun ./${INT2LM_EXNAME}
# exit script, if something crashed int2lm
if [[ $? != 0 ]] ; then exit 1 ; fi
wait

exit 0
