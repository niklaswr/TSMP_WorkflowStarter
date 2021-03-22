#!/bin/bash

#SBATCH --job-name="ERA5_simulation"
#SBATCH --nodes=12
#SBATCH --ntasks=576
#SBATCH --ntasks-per-node=48
#SBATCH --time=05:00:00
#SBATCH --partition=batch
#SBATCH --mail-type=ALL
#SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=jibg35

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2021-03-16
# USAGE: 

# IMPORTANT
# CTRLDIR and startDate HAVE TO be set via sbatch --export command 
echo "--- source environment"
source $CTRLDIR/export_paths.ksh
source $BASE_CTRLDIR/start_helper.sh

###############################################################################
# Prepare
###############################################################################

h0=$(TZ=UTC date '+%H' -d "$startDate")
d0=$(TZ=UTC date '+%d' -d "$startDate")
m0=$(TZ=UTC date '+%m' -d "$startDate")
y0=$(TZ=UTC date '+%Y' -d "$startDate")

dm1=$(TZ=UTC date '+%d' -d "$startDate - 1 month")
mm1=$(TZ=UTC date '+%m' -d "$startDate - 1 month")
ym1=$(TZ=UTC date '+%Y' -d "$startDate - 1 month")

# echo for logfile
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation start-date: ${startDate}"
echo "---            CTRLDIR:   ${BASE_CTRLDIR}"
echo "--- HOST:  $(hostname)"

###############################################################################
# Simulation
###############################################################################

# Something TSMP related
# --> aks ABouzar if still needed
export PSP_RENDEZVOUS_OPENIB=-1

#---------------insert here initial, start and final dates of TSMP simulations----------
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
WORK_DIR="${BASE_RUNDIR_TSMP}"
template_FOLDER="tsmp_era5clima_template"

# calculate the number of leap-days between initDate and startDate/currentDate
# Those are needed by COSMO to proper calculate start-hours
get_numLeapDays "$initDate" "$startDate"
numLeapDays=$?

#----------numbers of hours for each month--------
if [ "$m0" -eq 02 ]; then
  numHours=672;
elif [ "${m0}" -eq 1 ] || [ "${m0}" -eq 3 ] || [ "${m0}" -eq 5 ] || [ "${m0}" -eq 7 ] || [ "${m0}" -eq 8 ] || [ "${m0}" -eq 10 ] || [ "${m0}" -eq 12 ]; then
  numHours=744;
else  
  numHours=720;
fi
hstart=$(( ($(date -u '+%s' -d "${startDate}") - $(date -u '+%s' -d "${initDate}"))/3600 - numLeapDays*24))
hstop=$((hstart+numHours))

#----------copy temlate dir to new rundir-----------
expID="TSMP_3.1.0MCT_cordex11_${y0}_${m0}"
cp -r ${WORK_DIR}/${template_FOLDER} ${WORK_DIR}/${expID}
#----------copy geodir (at least parflow) to new rundir----------
#----------and execute tcl-scripts-------------------------------
cp ${BASE_GEODIR}/parflow/* ${WORK_DIR}/${expID}/
cd ${WORK_DIR}/${expID}
tclsh ascii2pfb_slopes.tcl
tclsh ascii2pfb_SoilInd.tcl

cd ${WORK_DIR}/${expID}
mkdir ${WORK_DIR}/${expID}/cosmo_out

source ${WORK_DIR}/${expID}/loadenvs

##############################################################
# Modifying COSMO namelists
##############################################################
sed -i "s,__hstart__,${hstart},g" INPUT_IO
sed -i "s,__hstop__,${hstop},g" INPUT_IO
sed -i "s,__cosmo_ydirini__,${WORK_DIR}/laf_lbfd/all,g" INPUT_IO
sed -i "s,__cosmo_ydirbd__,${WORK_DIR}/laf_lbfd/all,g" INPUT_IO
sed -i "s,__exp_id__,TSMP_3.1.0MCT_cordex11_${y0}_${m0},g" INPUT_IO
sed -i "s,__work_dir_rep__,${WORK_DIR},g" INPUT_IO

cosmo_ydate_ini=$(date '+%Y%m%d%H' -d "${initDate}")
sed -i "s,__hstart__,$hstart,g" INPUT_ORG
sed -i "s,__hstop__,$hstop,g" INPUT_ORG
sed -i "s,__cosmo_ydate_ini__,${cosmo_ydate_ini},g" INPUT_ORG

##############################################################
# Modifying CLM namelists
##############################################################
nelapse=$((numHours*3600/900+1))
sed -i "s,__nelapse__,${nelapse},g" lnd.stdin
start_ymd=$(date '+%Y%m%d' -d "${startDate}")
sed -i "s,__start_ymd__,${start_ymd},g" lnd.stdin
sed -i "s,__exp_id__,TSMP_3.1.0MCT_cordex11_${y0}_${m0},g" lnd.stdin
clm_restart=$(date '+%Y-%m-%d' -d "${startDate}")
sed -i "s,__clm_restart__,clmoas.clm2.r.${clm_restart}-00000.nc,g" lnd.stdin
#sed -i "s,__setup_dir_rep__,${SETUP_DIR}/g" lnd.stdin
sed -i "s,__work_dir_rep__,${WORK_DIR},g" lnd.stdin
sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" lnd.stdin

##############################################################
# Modifying ParFlow TCL flags
##############################################################
sed -i "s,##numHours##,${numHours},g" coup_oas.tcl
cp ${WORK_DIR}/restarts/parflow/cordex0.11_${ym1}_${mm1}.out.press.*.pfb .
ic_pressure=`ls -1rt cordex0.11_${ym1}_${mm1}.out.press.*.pfb | tail -1`
sed -i "s,__ICPressure__,${ic_pressure},g" coup_oas.tcl
sed -i "s,__year__,${y0},g" coup_oas.tcl
sed -i "s,__month__,${m0},g" coup_oas.tcl
sed -i "s,__BASE_GEODIR__,${BASE_GEODIR},g" coup_oas.tcl
tclsh coup_oas.tcl

sed -i "s,__pfidb__,cordex0.11_${y0}_${m0},g" slm_multiprog_mapping.conf

##############################################################
# Modifying OASIS3-MCT namelist
##############################################################
runTime=$((numHours*3600+900))
sed -i "s,__runTime__,${runTime},g" namcouple

##############################################################
# Running the simulation
##############################################################
echo "started" > started.txt
rm -rf YU*
echo "DEBUG: start simulation"
srun --multi-prog slm_multiprog_mapping.conf
if [[ $? != 0 ]] ; then exit 1 ; fi
date
wait

##############################################################
# Copy CLM and ParFlow restarts to central directory
# COSMO writes restarts to central directory
##############################################################
echo "DEBUG: start copying restar files"
clm_restart=`ls -1rt clmoas.clm2.r.*00000.nc | tail -1`
cp ${clm_restart} ${WORK_DIR}/restarts/clm
pfl_restart=`ls -1rt cordex0.11_${y0}_${m0}.out.press*.pfb | tail -1`
cp ${pfl_restart} ${WORK_DIR}/restarts/parflow
wait
echo "ready: TSMP simulation for ${cur_month} is complete!" > ready.txt

exit 0
