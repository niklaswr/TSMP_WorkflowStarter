#!/bin/bash

#SBATCH --job-name="ERA5_finish"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --time=00:30:00
#SBATCH --partition=devel
#SBATCH --mail-type=NONE
#SBATCH --account=jibg35

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-12-11
# USAGE: 

# IMPORTANT
# CTRLDIR and startDate HAVE TO be set via sbatch --export command 
echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_CTRLDIR}/postpro/loadenvs
cd ${BASE_CTRLDIR}

###############################################################################
# Prepare
###############################################################################

h0=$(TZ=UTC date '+%H' -d "$startDate")
d0=$(TZ=UTC date '+%d' -d "$startDate")
m0=$(TZ=UTC date '+%m' -d "$startDate")
y0=$(TZ=UTC date '+%Y' -d "$startDate")
dp1=$(TZ=UTC date '+%d' -d "$startDate +1 month")
mp1=$(TZ=UTC date '+%m' -d "$startDate +1 month")
yp1=$(TZ=UTC date '+%Y' -d "$startDate +1 month")

# echo for logfile
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation start-date: ${startDate}"
echo "--- HOST:  $(hostname)"

###############################################################################
# finishing
###############################################################################

#---------------insert here initial, start and final dates of TSMP simulations----------
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
WORK_DIR="${BASE_RUNDIR_TSMP}"
expID="TSMP_3.1.0MCT_cordex11_${y0}_${m0}"
rundir=${WORK_DIR}/${expID}

echo "--- create SIMRES dir (and sub-dirs) to store simulation results"
new_simres_name="${expid}_$(date '+%Y%m%d' -d "$startDate")"
new_simres=${BASE_SIMRESDIR}/${new_simres_name}
echo "--- new_simres: $new_simres"
mkdir -p "$new_simres/cosmo"
mkdir -p "$new_simres/parflow"
mkdir -p "$new_simres/clm"
mkdir -p "$new_simres/int2lm"
mkdir -p "$new_simres/restarts"
check4error $? "--- ERROR while creating simres-dir"

echo "--- store setup/history information in simres (reusability etc.)"
histfile=$new_simres/HISTORY.txt
/bin/cat <<EOM >$histfile
This simulation was run with 
###############################################################################
WORKFLOW 
-- REPO:
__URL_WORKFLOW__
-- LOG: 
tag: __TAG_WORKFLOW__
__COMMIT_WORKFLOW__
__AUTHOR_WORKFLOW__
__DATE_WORKFLOW__
__SUBJECT_WORKFLOW__
###############################################################################
MODEL (build with: './build_tsmp.ksh -v 3.1.0MCT -c clm-cos-pfl -m JUWELS -O Intel')
-- REPO:
__URL_MODEL__
-- LOG:
tag: __TAG_MODEL__
__COMMIT_MODEL__
__AUTHOR_MODEL__
__DATE_MODEL__
__SUBJECT_MODEL__
###############################################################################
EOM
cd ${BASE_CTRLDIR}
TAG_WORKFLOW=$(git tag --points-at HEAD)
COMMIT_WORKFLOW=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_WORKFLOW=$(git log --pretty=format:'author: %an' -n 1)
DATE_WORKFLOW=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_WORKFLOW=$(git log --pretty=format:'subject: %s' -n 1)
URL_WORKFLOW=$(git config --get remote.origin.url)
sed -i "s;__TAG_WORKFLOW__;${TAG_WORKFLOW};g" ${histfile}
sed -i "s;__COMMIT_WORKFLOW__;${COMMIT_WORKFLOW};g" ${histfile}
sed -i "s;__AUTHOR_WORKFLOW__;${AUTHOR_WORKFLOW};g" ${histfile}
sed -i "s;__DATE_WORKFLOW__;${DATE_WORKFLOW};g" ${histfile}
sed -i "s;__SUBJECT_WORKFLOW__;${SUBJECT_WORKFLOW};g" ${histfile}
sed -i "s;__URL_WORKFLOW__;${URL_WORKFLOW};g" ${histfile}

cd ${BASE_SRCDIR}/TSMP
TAG_MODEL=$(git tag --points-at HEAD)
COMMIT_MODEL=$(git log --pretty=format:'commit: %H' -n 1)
AUTHOR_MODEL=$(git log --pretty=format:'author: %an' -n 1)
DATE_MODEL=$(git log --pretty=format:'date: %ad' -n 1)
SUBJECT_MODEL=$(git log --pretty=format:'subject: %s' -n 1)
URL_MODEL=$(git config --get remote.origin.url)
sed -i "s;__TAG_MODEL__;${TAG_MODEL};g" ${histfile}
sed -i "s;__COMMIT_MODEL__;${COMMIT_MODEL};g" ${histfile}
sed -i "s;__AUTHOR_MODEL__;${AUTHOR_MODEL};g" ${histfile}
sed -i "s;__DATE_MODEL__;${DATE_MODEL};g" ${histfile}
sed -i "s;__SUBJECT_MODEL__;${SUBJECT_MODEL};g" ${histfile}
sed -i "s;__URL_MODEL__;${URL_MODEL};g" ${histfile}
check4error $? "--- ERROR while creating HISTORY.txt"

echo "--- move modeloutput to individual simresdir"
cp ${rundir}/cosmo_out/* $new_simres/cosmo
cp ${rundir}/cordex0.11_${y0}_${m0}.out.*.pfb $new_simres/parflow
cp ${rundir}/clmoas.clm2.h?.*.nc $new_simres/clm
cp ${WORK_DIR}/restarts/cosmo/lrfd${yp1}${mp1}0100o $new_simres/restarts
cp ${WORK_DIR}/restarts/parflow/cordex0.11_${y0}_${m0}.out.press.?????.pfb $new_simres/restarts
cp ${WORK_DIR}/restarts/clm/clmoas.clm2.r.${yp1}-${mp1}-01-00000.nc $new_simres/restarts
check4error $? "--- ERROR while moving model output to simres-dir"
wait

echo "--- gzip and sha512sum individual files in simresdir"
cd ${new_simres}/cosmo
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/cosmo
wait
cd ${new_simres}/parflow
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/parflow
wait
cd ${new_simres}/clm
sha512sum ./* > ./CheckSum.sha512
parallelGzip 48 $new_simres/clm
wait
cd ${new_simres}/restarts
sha512sum ./* > CheckSum.sha512
parallelGzip 48 $new_simres/restarts
wait


# NWR 20201215
# ARCHIVE is not accessable from computenode, wherefore I need to rethink
# the archiving routine
# write an extra script for tar -cf (direkt to archive) and ln -sf
#echo "-- tar simres/${y0}_${m0}"
#cd ${BASE_SIMRESDIR}
#tar cf ${new_simres_name}.tar -C ${BASE_SIMRESDIR} ${new_simres_name}
#if [[ $? != 0 ]] ; then exit 1 ; fi
#rm -rf ${new_simres}

echo "--- clean/remove rundir"
#mv $rundir ${rundir}_REMOVE
rm -r ${rundir}

exit 0

