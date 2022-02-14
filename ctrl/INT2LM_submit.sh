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
# author: Liuba POSHYVAILO, Niklas WAGNER
# e-mail: l.poshyvailo@fz-juelich.de, n.wagner@fz-juelich.de
# last modified: 2022-01-11
# USAGE: 
# >> sbatch $0 CTRLDIR
# >> sbatch INT2LM_submit.sh $(pwd)
# 
###############################################################################
#### Adjust according to your need BELOW
###############################################################################
startDate=20090101  # start date
int2lm_hstop=2976   # --> 366 * 24h
int2lm_hincbound=3  # dumpinterval of forcing (3h, 6h, daily, etc)
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
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_NAMEDIR}/loadenv_int2lm

h0=$(date -u -d "$startDate" '+%H')
d0=$(date -u -d "$startDate" '+%d')
m0=$(date -u -d "$startDate" '+%m')
y0=$(date -u -d "$startDate" '+%Y')

echo "DEBUG: def. individual settings"
int2lm_nam_template="INT2LM_template_ERA5"

echo "DEBUG: create INT2LM lm_cat_dir dir"
int2lm_LmCatDir="${BASE_FORCINGDIR}/laf_lbfd/${y0}"
mkdir -p ${int2lm_LmCatDir}

echo "DEBUG: create INT2LM rundir"
rundir="${BASE_RUNDIR}/INT2LM_${y0}"
mkdir -p ${rundir}

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
cp ${BASE_BINDIR_INT2LM}/${BASE_INT2LM_EXNAME} ${rundir}/

echo "DEBUG start_date: ${start_date}"
int2lm_start_date=${y0}${m0}${d0}${h0}

echo "DEBUG: int2lm_start_date: ${int2lm_start_date}"

echo "DEBUG: copy namelist for current loop"
cp ${BASE_NAMEDIR}/${int2lm_nam_template} ${rundir}/INPUT

echo "DEBUG: modify namelist (sed inserts etc.)"
sed "s,__start_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__init_date__,${int2lm_start_date},g" -i ${rundir}/INPUT
sed "s,__hstop__,${int2lm_hstop},g" -i ${rundir}/INPUT
sed "s,__hincbound__,${int2lm_hincbound},g" -i ${rundir}/INPUT
sed "s,__lm_ext_dir__,${BASE_GEODIR}/int2lm,g" -i ${rundir}/INPUT
sed "s,__in_ext_dir__,${BASE_FORCINGDIR}/IrawIN/NT2LM_inext,g" -i ${rundir}/INPUT
sed "s,__in_cat_dir__,${BASE_FORCINGDIR}/rawIN/${y0},g" -i ${rundir}/INPUT
sed "s,__lm_cat_dir__,${int2lm_LmCatDir},g" -i ${rundir}/INPUT
 
echo "DEBUG: enter INT2LM rundir and start INT2LM"
cd ${rundir}
# just to be sure, clean rundir before starting (e.g. in case of restart)
rm -rf YU*  
srun ./${BASE_INT2LM_EXNAME}
# exit script, if something crashed int2lm
if [[ $? != 0 ]] ; then exit 1 ; fi
wait

exit 0
