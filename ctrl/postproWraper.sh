#!/bin/bash
#
# author: Niklas WAGNER
# e-mail: n.wagner@fz-juelich.de
# version: 2020-12-11
#
# USAGE:
# >> ./$0 YDATE_START CURRENT_DATE YYYY_MM
# >> ./$0 1980010100  1982020100   1982_02
# YDATE_START = initDate of simulation
# CURRENT_DATE = current date of simulation
# YYYY_MM = different representation of current date
# The naming is choosen because the PostPro function from CCLM is used
# which assumes those names

# Move to directory where the script is located.
tmp_filename=$0
exe_dir="${tmp_filename%/*}"
cd $exe_dir
cwd=$(pwd)/postpro

echo "--- source export_paths.ksh"
source ${exe_dir}/export_paths.ksh
echo "--- source loadenvs"
source ${cwd}/loadenvs

# ${NCO_BINDIR} is expected by the CCLM postpro
tmp_NCO_BINDIR=$(which ncrcat)
NCO_BINDIR="${tmp_NCO_BINDIR%/*}"
echo "--- set NCO_BINDIR: ${NCO_BINDIR}"
tmp_NC_BINDIR=$(which ncdump)
NC_BINDIR="${tmp_NC_BINDIR%/*}"
echo "--- set NC_BINDIR: ${NC_BINDIR}"
tmp_CDO_BINDIR=$(which cdo)
CDO_BINDIR="${tmp_CDO_BINDIR%/*}"
CDO=${tmp_CDO_BINDIR} # postpro functions need this as "CDO"
echo "--- set CDO: ${CDO}"

NBOUNDCUT=4
IE_TOT=444
JE_TOT=432
let "IESPONGE = ${IE_TOT} - NBOUNDCUT - 1"
let "JESPONGE = ${JE_TOT} - NBOUNDCUT - 1"
# OUTDIR and YYYY_MM are separated becasue 'functions.sh' need this
YDATE_START=$1   # YYYYMMDDHH
CURRENT_DATE=$2  # YYYYMMDDHH
YYYY_MM=$3       # YYYY_MM 
OUTDIR="${BASE_POSTPRODIR}"
INPDIR="${BASE_RUNDIR_TSMP}/sim_output_heter_geology_improved_with_pfl_sink/ToPostPro"
mkdir ${OUTDIR}/${YYYY_MM}

export IGNORE_ATT_COORDINATES=0  # setting for better rotated coordinate handling in CDO
source ${cwd}/functions.sh

#... cut of the boundary lines from the constant data file
if [ ! -f ${OUTDIR}/${YYYY_MM}/lffd${YDATE_START}c.nc ]
then
  ncks -h -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} ${INPDIR}/${YYYY_MM}/cosmo_out/lffd${YDATE_START}c.nc ${OUTDIR}/${YYYY_MM}/lffd${YDATE_START}c.nc
fi

###### START tmp
#exit 0
###### END tmp

echo "- Start processing COSMO outpur"
echo "--- Starting CCLM default output timeseries"
timeseries RAIN_CON  cosmo_out
timeseries RAIN_GSP  cosmo_out
timeseries SNOW_CON  cosmo_out
timeseries SNOW_GSP  cosmo_out
timeseries TOT_PREC  cosmo_out
#
timeseries ALHFL_S   cosmo_out
timeseries ALWD_S    cosmo_out
timeseries ALWU_S    cosmo_out
timeseries ASOB_S    cosmo_out
timeseries ASOB_T    cosmo_out
timeseries ASOD_T    cosmo_out
timeseries ATHB_S    cosmo_out
timeseries ATHB_T    cosmo_out
timeseries ASHFL_S   cosmo_out
timeseries ASWDIFD_S cosmo_out
timeseries ASWDIFU_S cosmo_out
timeseries ASWDIR_S  cosmo_out
timeseries CLCT      cosmo_out
timeseries DURSUN    cosmo_out
timeseries PMSL      cosmo_out
timeseries PS        cosmo_out
timeseries QV_2M     cosmo_out
timeseries T_2M      cosmo_out
timeseries U_10M     cosmo_out
timeseries V_10M     cosmo_out
timeseries RELHUM_2M cosmo_out
timeseries ALB_RAD   cosmo_out
#
timeseries AEVAP_S   cosmo_out
#timeseries AUMFL_S   cosmo_out# not calculated
#timeseries AVMFL_S   cosmo_out# not calculated
timeseries CLCH      cosmo_out
timeseries CLCL      cosmo_out
timeseries CLCM      cosmo_out
timeseries H_SNOW    cosmo_out
timeseries HPBL      cosmo_out
timeseries RUNOFF_G  cosmo_out
timeseries RUNOFF_S  cosmo_out
timeseries SNOW_MELT cosmo_out
timeseries T_S       cosmo_out
timeseries TQC       cosmo_out
timeseries TQI       cosmo_out
timeseries TQV       cosmo_out
timeseries W_I       cosmo_out
timeseries W_SO      cosmo_out
timeseries W_SNOW    cosmo_out
timeseries W_SO_ICE  cosmo_out
#
timeseries TMAX_2M   cosmo_out
timeseries TMIN_2M   cosmo_out
timeseries VMAX_10M  cosmo_out
timeseries VABSMX_10M  cosmo_out

#LPo added 14.12.2020
timeseries FIS cosmo_out
timeseries TQR cosmo_out
timeseries TWATER cosmo_out
timeseries TQS cosmo_out
timeseries TDIV_HUM cosmo_out
timeseries TCM cosmo_out
timeseries TCH cosmo_out
timeseries HBAS_CON cosmo_out
timeseries HTOP_CON cosmo_out
timeseries CEILING cosmo_out
timeseries CAPE_ML cosmo_out
timeseries CIN_ML cosmo_out
timeseries CAPE_MU cosmo_out
timeseries CIN_MU cosmo_out
timeseries TKE_CON cosmo_out
timeseries TD_2M cosmo_out
timeseries QV_2M cosmo_out
timeseries HBAS_SC cosmo_out
timeseries HTOP_SC cosmo_out
timeseries CAPE_CON cosmo_out

echo "--- Starting CCLM default output timeseriesp"
PLEVS=(5 200. 500. 850. 925. 1000) # list of pressure levels. Must be the same as or a subset
                                   # of the plev list in the specific GRIBOUT
echo "--- -- using PLEVS: ${PLEVS[@]}"
timeseriesp T        cosmo_out  PLEVS[@]
timeseriesp U        cosmo_out  PLEVS[@]
timeseriesp V        cosmo_out  PLEVS[@]
timeseriesp FI       cosmo_out  PLEVS[@]
timeseriesp QV       cosmo_out  PLEVS[@]
timeseriesp RELHUM   cosmo_out  PLEVS[@]

echo "--- Starting calculate further fields"
windspeed10M
derotatewind10M
winddir10M
snowfraction
addfields ASWDIR_S ASWDIFD_S ASWD_S
subtractfields ASOD_T ASOB_T ASOU_T
addfields RUNOFF_S RUNOFF_G RUNOFF_T
addfields RAIN_CON SNOW_CON PREC_CON
addfields SNOW_GSP SNOW_CON TOT_SNOW
addfields TQC TQI TQW

# NWR 20201130
# there is an error of calculating windspeed on p-lev
# so I tunred this off to make progress.
# I guess this is OK for the moment, as Carina also did
# not saved windspeed (only compenents) with here dataset
#windspeedp PLEVS[@]
#derotatewindp PLEVS[@]
#winddirp PLEVS[@]

# NWR 20201130
# We dont write out any z-lvl so below is obsolete
#windspeedz ZLEVS[@]
#derotatewindz ZLEVS[@]
#winddirz ZLEVS[@]

dtr

# needs forever but only saves ~ 1GB
#echo "--- Start compressing COSMO"
#echo "**** internal netCDF compression"
#cd ${OUTDIR}/${YYYY_MM}
#
#FILELIST=$(ls -1)
#for FILE in ${FILELIST}
#do
#  # skipp if $FILE is not a regular file
#  [[ ! -f ${FILE} ]] && continue
#  ${CDO} -f nc4 -z zip_4 copy ${FILE} tmp.nc
#  mv tmp.nc ${FILE}
#done

echo "- Start processing ParFlow variables"
cd ${cwd}
outVar="press"
ncgen -7 -o "${OUTDIR}/${YYYY_MM}/${outVar}.nc" "${cwd}/def.cdl"
#python ${cwd}/netCDF_select.py -i ${OUTDIR}/${YYYY_MM}/T_S_ts.nc \
#	-o ${OUTDIR}/${YYYY_MM}/${outVar}.nc --blacklist T_S time time_bnds
python ${cwd}/Pfb2NetCDF.py -v ${outVar} -i ${INPDIR}/${YYYY_MM}/parflow_out \
	-o ${OUTDIR}/${YYYY_MM} --model "ParFlow" --YearMonth ${YYYY_MM} \
	-nc 0 --dumpinterval 3 \
	-sn pgw -ln "Groundwater Pressure" -u "m H2O"
outVar="satur"
ncgen -7 -o "${OUTDIR}/${YYYY_MM}/${outVar}.nc" "${cwd}/def.cdl"
#python ${cwd}/netCDF_select.py -i ${OUTDIR}/${YYYY_MM}/T_S_ts.nc \
#	-o ${OUTDIR}/${YYYY_MM}/${outVar}.nc --blacklist T_S time time_bnds
python ${cwd}/Pfb2NetCDF.py -v ${outVar} -i ${INPDIR}/${YYYY_MM}/parflow_out \
	-o ${OUTDIR}/${YYYY_MM} --model "ParFlow" --YearMonth ${YYYY_MM} \
	-nc 0 --dumpinterval 3 \
	-sn sgw -ln "Groundwater Saturation" -u "-"
outVar="et"
ncgen -7 -o "${OUTDIR}/${YYYY_MM}/${outVar}.nc" "${cwd}/def.cdl"
#python ${cwd}/netCDF_select.py -i ${OUTDIR}/${YYYY_MM}/T_S_ts.nc \
#        -o ${OUTDIR}/${YYYY_MM}/${outVar}.nc --blacklist T_S time time_bnds
python ${cwd}/Pfb2NetCDF.py -v ${outVar} -i ${INPDIR}/${YYYY_MM}/parflow_out \
        -o ${OUTDIR}/${YYYY_MM} --model "CLM" --YearMonth ${YYYY_MM} \
        -nc 0 --dumpinterval 3 \
        -sn et -ln "evap_trans" -u "-" # --level "-1"
#ncdump ${template_netCDF} > def.cdl
#ncgen -o NEWFILE def.cdl

echo "- Start processing CLM variables"
cd ${cwd}
#outVar="WT TSA TBOT QFLX_SNOW_GRND QFLX_RAIN_GRND QFLX_EVAP_TOT H2OSNO FSR FSH FSDS FLDS FIRA FGR FGEV FCTR FCEV time time_bounds"
outVar="ZBOT WT WIND TSA THBOT TBOT SNOW RAIN QFLX_SNOW_GRND QFLX_RAIN_GRND QFLX_EVAP_TOT QBOT H2OSNO FSR FSH FSDS FLDS FIRA FGR FGEV FCTR FCEV time time_bounds"
ncgen -7 -o "${OUTDIR}/${YYYY_MM}/CLM_Template.nc" "${cwd}/def.cdl"
#python ${cwd}/netCDF_select.py -i ${OUTDIR}/${YYYY_MM}/TMAX_2M_ts.nc -o ${OUTDIR}/${YYYY_MM}/CLM_Template.nc --blacklist TMAX_2M time time_bnds
python ${cwd}/CLMpostpro.py -v ${outVar} -i ${INPDIR}/${YYYY_MM}/clm_out \
	-o ${OUTDIR}/${YYYY_MM} \
	--templateFile ${OUTDIR}/${YYYY_MM}/CLM_Template.nc -nc 0 

exit 0
