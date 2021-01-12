#!/bin/bash
#
# author: Liubai POSHYVAILO, Niklas WAGNER
# e-mail: l.poshyvailo@fz-juelich.de, n.wagner@fz-juelich.de
# last modified: 2020-10-30
# USAGE: sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR $0
#
#SBATCH --job-name="int2lm"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --output=int2lm-out.%j
#SBATCH --error=int2lm-err.%j
#SBATCH --time=03:00:00
#SBATCH --partition=batch
##SBATCH --mail-type=ALL
#SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=jibg35
##SBATCH --reservation=maint-centos8

echo "DEBUG: setup environment"
source ${CTRLDIR}/export_paths.ksh
source ${BASE_SRCDIR}/loadenv
export LD_LIBRARY_PATH=${BASE_SRCDIR}/libgrib_api/lib:$LD_LIBRARY_PATH
export PATH=${BASE_SRCDIR}/libgrib_api/bin:$PATH
export GRIB_DEFINITION_PATH=${BASE_SRCDIR}/libgrib_api/share/grib_api/definitions/:${BASE_SRCDIR}/int2lm_170406_2.04a/1.16.0/definitions.edzw:${BASE_SRCDIR}/int2lm_170406_2.04a/1.16.0/definitions
export GRIB_SAMPLES_PATH=${BASE_SRCDIR}/libgrib_api/share/grib_api/samples/:${BASE_SRCDIR}/int2lm_170406_2.04a/1.16.0/samples/

echo "DEBUG: def individual settings"
start_date=$(TZ=UTC date --date "$startDate")
#start_date=$(TZ=UTC date --date "1984-01-01T00:00Z")
cur_year=$(TZ=UTC date '+%Y' --date="${start_date}")
#int2lm_init_date=$(TZ=UTC date '+%Y%m%d%H' -d "1980-01-01T00:00Z")
int2lm_exe="int2lm_204a"
#int2lm_exe="int2lm_200"
int2lm_hstop=240
int2lm_hincbound=3
int2lm_nam_template="INT2LM_template_ERA5"

echo "DEBUG: create INT2LM lm_cat_dir (ex OUTPUT_DIR) dir"
int2lm_LmCatDir="${BASE_RUNDIR_TSMP}/laf_lbfd_int2lm_juwels2019a_ouput/${cur_year}"
mkdir -p ${int2lm_LmCatDir}

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

  cp ${BASE_TEMPLATEDIR}/${int2lm_nam_template} ${BASE_RUNDIR_INT2LM}/INPUT
  #cp INPUT_template INPUT

  sed "s,__start_date__,${int2lm_start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__init_date__,${int2lm_start_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  #sed "s,__init_date__,${int2lm_init_date},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__hstop__,${int2lm_hstop},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__hincbound__,${int2lm_hincbound},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__ext_dir__,${BASE_EXTDIR},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__in_cat_dir__,${BASE_FORCINGDIR}/ERA5/${cur_year},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
  sed "s,__lm_cat_dir__,${int2lm_LmCatDir},g" -i ${BASE_RUNDIR_INT2LM}/INPUT
 
  cd ${BASE_RUNDIR_INT2LM}
  rm -rf YU*  
  srun ./${int2lm_exe}
  # exit loop / script, if something crashed int2lm
  if [[ $? != 0 ]] ; then exit 1 ; fi
  wait

  start_date=$(TZ=UTC date --date="${start_date} + ${int2lm_hstop} hours")
  #start_date=$(TZ=UTC date --date="${start_date} + $(( ${int2lm_hstop} + ${int2lm_hincbound} )) hours")
done
