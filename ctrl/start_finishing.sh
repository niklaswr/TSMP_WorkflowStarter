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
initDate="19800101" #DO NOT TOUCH! start of the whole TSMP simulation
WORK_DIR="${BASE_RUNDIR_TSMP}"
WORK_FOLDER="sim_output_heter_geology_improved_with_pfl_sink"
template_FOLDER="tsmp_era5clima_template"
expID="TSMP_3.1.0MCT_cordex11_${y0}_${m0}"
rundir=${WORK_DIR}/${WORK_FOLDER}/${expID}

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
WORKFLOW 'ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3'
-- REPO:
https://icg4geo.icg.kfa-juelich.de/ModelSystems/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3.git
-- COMMIT: 
EOM
cd ${BASE_CTRLDIR}
git show --oneline -s >> $histfile

# NOTE the difference > and >> here and above!
/bin/cat <<EOM >>$histfile
###############################################################################
SETUP / CONFIGURATION 'tsmp_era5clima_template'
-- REPO:
https://icg4geo.icg.kfa-juelich.de/Configurations/TSMP/tsmp_era5clima_template
-- COMMIT:
EOM
cd ${BASE_RUNDIR_TSMP}/${WORK_FOLDER}/${template_FOLDER}
git show --oneline -s >> $histfile

# NOTE the difference > and >> here and above!
/bin/cat <<EOM >>$histfile
###############################################################################
MODEL 'TSMP' (build with: './build_tsmp.ksh -v 3.1.0MCT -c clm-cos-pfl -m JUWELS -O Intel')
-- REPO:
https://github.com/HPSCTerrSys/TSMP
-- COMMIT:
EOM
cd ${BASE_SRCDIR}/TSMP
git show --oneline -s >> $histfile
check4error $? "--- ERROR while creating HISTORY.txt"

echo "--- move modeloutput to individual simresdir"
cp ${rundir}/cosmo_out/* $new_simres/cosmo
cp ${rundir}/cordex0.11_${y0}_${m0}.out.*.pfb $new_simres/parflow
cp ${rundir}/clmoas.clm2.h?.*.nc $new_simres/clm
cp ${WORK_DIR}/${WORK_FOLDER}/restarts/cosmo/lrfd${yp1}${mp1}0100o $new_simres/restarts
cp ${WORK_DIR}/${WORK_FOLDER}/restarts/parflow/cordex0.11_${y0}_${m0}.out.press.?????.pfb $new_simres/restarts
cp ${WORK_DIR}/${WORK_FOLDER}/restarts/clm/clmoas.clm2.r.${yp1}-${mp1}-01-00000.nc $new_simres/restarts
check4error $? "--- ERROR while moving model output to simres-dir"
wait

echo "--- gzip individual files in simresdir"
cd $new_simres
parallelGzip 48 $new_simres/cosmo
wait
parallelGzip 48 $new_simres/parflow
wait
parallelGzip 48 $new_simres/clm
wait
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

