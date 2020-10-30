#!/bin/bash
#
# author: Liubai POSHYVAILO, Niklas WAGNER
# e-mail: l.poshyvailo@fz-juelich.de, n.wagner@fz-juelich.de
# last modified: 2020-10-21
# USAGE: sbatch --export=ALL,initDate=$initDate,CTRLDIR=$BASE_CTRLDIR $0
#
#SBATCH --job-name="int2lm"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --output=int2lm-out.%j
#SBATCH --error=int2lm-err.%j
#SBATCH --time=1:00:00
#SBATCH --partition=devel
##SBATCH --mail-type=ALL
#SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=jibg35

#for int2lm interpolation, set init_date and ii number in a loop below (for output in grb format), WORK_DIR and SETUP_DIR

source ${CTRLDIR}/export_paths.ksh
source ${BASE_SRCDIR}/module_load_new

init_date=$(TZ=UTC date '+%Y%m%d%H' -d "1980-01-01T00:00Z")
INT2LM_init_date=$(TZ=UTC date '+%Y%m%d%H' -d "1980-01-01T00:00Z")
int2lm_exe="int2lm_204a"
#int2lm_exe="int2lm_200"

WORK_DIR="${BASE_RUNDIR_TSMP}"
#WORK_DIR="/p/scratch/cjibg35/poshyvailo1/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005"
SETUP_DIR="${BASE_CTRLDIR}"
#SETUP_DIR="/p/project/cesmtst/poshyvailo1/INT2LM/int2lm_GCM_2019a_JUWELs_histcl_IBG3_final_COSMO_clim_apix/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005"
OUTPUT_FOLDER="laf_lbfd_int2lm_juwels2019a_ouput"


export LD_LIBRARY_PATH=${BASE_SRCDIR}/libgrib_api/lib:$LD_LIBRARY_PATH
export PATH=${BASE_SRCDIR}/libgrib_api/bin:$PATH
export GRIB_DEFINITION_PATH=${BASE_SRCDIR}/libgrib_api/share/grib_api/definitions/:${BASE_SRCDIR}/int2lm_2.00/1.11.0/definitions.edzw:${BASE_SRCDIR}/int2lm_2.00/1.11.0/definitions
export GRIB_SAMPLES_PATH=${BASE_SRCDIR}/libgrib_api/share/grib_api/samples/:${BASE_SRCDIR}/int2lm_2.00/1.11.0/samples/


#-----------------------------------------------------------
#-----------------------------------------------------------
#-----------------------------------------------------------
cur_year=$(echo ${init_date} | cut -c1-4) #current year LPo

# Adds a backslash in front of each slash, to make sed work 
#WORK_DIR_REPLACE=$(echo $WORK_DIR | sed 's/\//\\\//g')
#SETUP_DIR_REPLACE=$(echo $SETUP_DIR | sed 's/\//\\\//g')

cd ${WORK_DIR}/${OUTPUT_FOLDER}  
mkdir -p ${cur_year} #LPo  mkdir -p always create dir, does not fail if already exists

#--------------------------------
#last changes: L.Poshyvailo, 2020
#In the following for loop int2lm processes 240 hours(10 days) of data in one cycle, correcponds to hstop=240 (in INPUT_template); use like this for grb output. In case of .nc output it is possible to increase hstop (as needed) and to not use ii loop
# To process one complete year (365 days) int2lm is run in 40 cycles. Last few cycles may be dummy cycles where int2lm will not produce any output.
for ((ii=1; ii<=40; ii++)) #replace ii<=40 -- cycles of 10 days; depending on the calendar, run Jan-Feb for the leap years, and then Mar-Dec.
do
        INT2LM_nam_template="INT2LM_template_ERA5"
        cp ${BASE_TEMPLATEDIR}/${INT2LM_nam_template} ${BASE_RUNDIR_INT2LM}/INPUT
        #cp INPUT_template INPUT
	if [ $ii = 1 ] ; then
		start_date=${init_date}
	else
       	last_file=$(ls ${WORK_DIR}/${OUTPUT_FOLDER}/${cur_year}/lbfd* -1rt | cut -d"/" -f11 | tail -1)
        echo "DEBUG last_file: $(ls ${WORK_DIR}/${OUTPUT_FOLDER}/${cur_year}/lbfd* -1rt)" 
		echo $last_file >> FILE
		prev_yr=`echo ${last_file} | cut -c5-8`
        echo "DEBUG prev_year: ${prev_year}" 
		echo $prev_year >> FILE
		prev_mon=`echo ${last_file} | cut -c9-10`
        echo "DEBUG prev_mon: ${prev_mon}" 
		prev_day=`echo ${last_file} | cut -c11-12`
        echo "DEBUG prev_day: ${prev_day}" 
		prev_hr=`echo ${last_file} | cut -c13-14`
        echo "DEBUG prev_hr: ${prev_hr}" 
		start_date=$(date -u '+%Y%m%d%H' --date="${prev_yr}-${prev_mon}-${prev_day} ${prev_hr} + 3 hours")
		#date -u '+%Y%m%d%H' --date="${prev_yr}-${prev_mon}-${prev_day} ${prev_hr} + 3 hours"
	fi

	echo $start_date >> FILE 
        echo "DEBUG start_date: ${start_date}" 

	#sed -i "s/__start_date__/${start_date}/g" INPUT
	#sed -i "s/__prev_yr__/${prev_yr}/g" INPUT
	#sed -i "s/__cur_year__/${cur_year}/g" INPUT
        #sed -i "s/__setup_dir__/${SETUP_DIR_REPLACE}/g" INPUT
        #sed -i "s/__work_dir__/${WORK_DIR_REPLACE}/g" INPUT
        sed "s,__start_date__,${start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
        sed "s,__init_date__,${start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
        #sed "s,__init_date__,${INT2LM_init_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
        sed "s,__ext_dir__,${BASE_EXTDIR},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
        sed "s,__in_cat_dir__,${BASE_FORCINGDIR}/ERA5/${cur_year},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
        sed "s,__lm_cat_dir__,${BASE_RUNDIR_TSMP}/laf_lbfd_int2lm_juwels2019a_ouput/${cur_year},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
      
        cd ${BASE_RUNDIR_INT2LM}
	rm -rf YU*  
	srun ./${int2lm_exe}
        # exit loop / script, if something crashed int2lm
        if [[ $? != 0 ]] ; then exit 1 ; fi
	wait
done
