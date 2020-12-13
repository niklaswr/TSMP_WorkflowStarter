#########################################################
#... function for correcting CDO created netCDF
#########################################################
function cdocor {
  # CALL: inparameter infile outparameter outfile

  inparameter=$1
  infile=$2
  outparameter=$3
  outfile=$4

  #... set the _FillValue to -1.E20
  set +e
  fillvalue=$(${NC_BINDIR}/ncdump -h ${outfile} | grep ${outparameter}:_FillValue)
  if [ "${fillvalue}" ]
  then
    ${CDO} -s setmissval,-1.E20 ${outfile} ${outfile}_tmp
    mv ${outfile}_tmp ${outfile}
  fi
  set -e
  # get the coordinates from the original file
  COORDINATES=$(${NC_BINDIR}/ncdump -h ${infile} | grep ${inparameter}:coordinates | cut -d'"' -f2)
  # only if coordinates exists a correction is necessary
  if [ "${COORDINATES}" ]
  then
    ${NCO_BINDIR}/ncatted -h -a coordinates,${outparameter},o,c,"${COORDINATES}" ${outfile}
    # if the rotated_pole variable exists exclude it from the copy list
    ${NC_BINDIR}/ncdump -h ${outfile} | grep "rotated_pole ;" > /dev/null
    if [ $? -ne 0 ]
    then
      COORDINATES=$(echo ${COORDINATES} | tr ' ' ','),rotated_pole
    else
      COORDINATES=$(echo ${COORDINATES} | tr ' ' ',')
    fi
    # copy coordinates from old to new file
    ${NCO_BINDIR}/ncks -h -A -C -v ${COORDINATES} ${infile} ${outfile}
  fi
}

#########################################################
#... functions for building time series
#      these are the essential functions to create the *_ts.nc files on post/YYYY_MM
#      the input quantities of for these functions are the lffdYYYYMMDDHH[MMSS] output files from CCLM
#########################################################

#... building a time series for a given quantity
function timeseries {
  PARAM=$1
  cd ${INPDIR}/${YYYY_MM}/$2
  ${NCO_BINDIR}/ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v $1 lffd*[!cpz].nc ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
  ${NCO_BINDIR}/ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole lffd${CURRENT_DATE}.nc ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
  # in case cell_methods exists the value of the time variable is replaced by the value of middle of the time interval
  if [ "$(${NC_BINDIR}/ncdump -h ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc | grep ${PARAM}:cell_methods | grep time)" != "" ]
  then
    ${NCO_BINDIR}/ncwa -h -C -v time_bnds -a bnds ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc tmp.nc
    ${NCO_BINDIR}/ncrename -h -v time_bnds,time tmp.nc
    ${NCO_BINDIR}/ncatted -h -a ,time,d,,, tmp.nc
    ${NCO_BINDIR}/ncks -h -A tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
    if [ ${CURRENT_DATE} -eq ${YDATE_START} ]
    then
      ${NCO_BINDIR}/ncks -h -O -d time,1,  ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc tmp.nc
      mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
    fi
    rm -f tmp.nc
  else
  # otherwise, i.e. for intantaneous values, time_bnds are deleted
    ${NCO_BINDIR}/ncatted -h -a bounds,time,d,, ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
    ${NCO_BINDIR}/ncks -h -x -v time_bnds ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc tmp.nc
    mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}_ts.nc
  fi
}

function timeseriesp {
  PARAM=$1
  # NWR 20201130
  # the below command destroys the PLEV array... 
  # So I commented this out
  #declare -a PLEVS=("${!3}")
  NPLEV=1
  while [ ${NPLEV} -le ${PLEVS[0]} ]
  do
    PASCAL=$(python -c "print(${PLEVS[$NPLEV]} * 100.)")
    PLEV=$(python -c "print(int(${PLEVS[$NPLEV]}))")
    cd ${INPDIR}/${YYYY_MM}/$2
    # NWR 20201204
    # do also cut dim srlon and srlat
    ${NCO_BINDIR}/ncrcat -h -O -d srlon,${NBOUNDCUT},${IESPONGE} -d srlat,${NBOUNDCUT},${JESPONGE} -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d pressure,${PASCAL},${PASCAL} -v ${PARAM} lffd*p.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
    #${NCO_BINDIR}/ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d pressure,${PASCAL},${PASCAL} -v ${PARAM} lffd*p.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
    # NWR 20201204
    # do also cut dim srlon and srlat
    ${NCO_BINDIR}/ncks -h -A -d srlon,${NBOUNDCUT},${IESPONGE} -d srlat,${NBOUNDCUT},${JESPONGE} -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole lffd${CURRENT_DATE}p.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
    #${NCO_BINDIR}/ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole lffd${CURRENT_DATE}p.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
    # in case cell_methods exists the value of the time variable is replaced by the value of middle of the time interval
   if [ "$(${NC_BINDIR}/ncdump -h ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc | grep ${PARAM}:cell_methods | grep time)" != "" ]
    then
      ${NCO_BINDIR}/ncwa -h -C -v time_bnds -a bnds ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc tmp.nc
      ${NCO_BINDIR}/ncrename -h -v time_bnds,time tmp.nc
      ${NCO_BINDIR}/ncatted -h -a ,time,d,,, tmp.nc
      ${NCO_BINDIR}/ncks -h -A tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
      if [ ${CURRENT_DATE} -eq ${YDATE_START} ]
      then
        ${NCO_BINDIR}/ncks -h -O -d time,1,  ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc tmp.nc
        mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
      fi
      rm -f tmp.nc
   else
  # otherwise, i.e. for intantaneous values, time_bnds are deleted
      ${NCO_BINDIR}/ncatted -h -a bounds,time,d,, ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
      ${NCO_BINDIR}/ncks -h -x -v time_bnds ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc tmp.nc
      mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
   fi
    ${NCO_BINDIR}/ncwa -O -a pressure,$1 ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc tmp.nc
    ${NCO_BINDIR}/ncatted -O -a cell_methods,$1,d,, tmp.nc
    ${NCO_BINDIR}/ncatted -O -a cell_methods,pressure,d,, tmp.nc
    ${NCO_BINDIR}/ncatted -O -a coordinates,$1,o,c,'lon lat pressure' tmp.nc
    cp tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${PLEV}p_ts.nc
    rm tmp.nc
    let "NPLEV = NPLEV + 1"
  done
}

function timeseriesz {
  PARAM=$1
  declare -a ZLEVS=("${!3}")
  set +e
  ncdump -h ${INPDIR}/${YYYY_MM}/$2/lffd${CURRENT_DATE}z.nc | grep float\ ${PARAM} | grep height > /dev/null 2>&1
  ERROR_STATUS=$?
  set -e
  if [ ${ERROR_STATUS}  -eq 0 ]
  then
    HEIGHT=height
    NN=
  else
    HEIGHT=altitude
    NN=NN
  fi
  NZLEV=1
  while [ ${NZLEV} -le ${ZLEVS[0]} ]
  do
    ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
    cd ${INPDIR}/${YYYY_MM}/$2
    ${NCO_BINDIR}/ncrcat -h -O -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -d ${HEIGHT},${ZLEV}.,${ZLEV}. -v ${PARAM} lffd*z.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
    ${NCO_BINDIR}/ncks -h -A -d rlon,${NBOUNDCUT},${IESPONGE} -d rlat,${NBOUNDCUT},${JESPONGE} -v lon,lat,rotated_pole lffd${CURRENT_DATE}z.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
    # in case cell_methods exists the value of the time variable is replaced by the value of middle of the time interval
   if [ "$(${NC_BINDIR}/ncdump -h ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc | grep ${PARAM}:cell_methods | grep time)" != "" ]
    then
      ${NCO_BINDIR}/ncwa -h -C -v time_bnds -a bnds ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc tmp.nc
      ${NCO_BINDIR}/ncrename -h -v time_bnds,time tmp.nc
      ${NCO_BINDIR}/ncatted -h -a ,time,d,,, tmp.nc
      ${NCO_BINDIR}/ncks -h -A tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
      if [ ${CURRENT_DATE} -eq ${YDATE_START} ]
      then
        ${NCO_BINDIR}/ncks -h -O -d time,1,  ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc tmp.nc
        mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
      fi
      rm -f tmp.nc
   else
  # otherwise, i.e. for intantaneous values, time_bnds are deleted
      ${NCO_BINDIR}/ncatted -h -a bounds,time,d,, ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
      ${NCO_BINDIR}/ncks -h -x -v time_bnds ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc tmp.nc
      mv tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
   fi
    ${NCO_BINDIR}/ncwa -O -a ${HEIGHT},$1 ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc tmp.nc
    ${NCO_BINDIR}/ncatted -O -a cell_methods,$1,d,, tmp.nc
    ${NCO_BINDIR}/ncatted -O -a cell_methods,${HEIGHT},d,, tmp.nc
    ${NCO_BINDIR}/ncatted -O -a coordinates,$1,o,c,"lon lat ${HEIGHT}" tmp.nc
    cp tmp.nc ${OUTDIR}/${YYYY_MM}/${PARAM}${ZLEV}z${NN}_ts.nc
    rm tmp.nc
   let "NZLEV = NZLEV + 1"
  done
}

#########################################################
#... functions for calculating additional quantities
#      these functions are for quantities which are no output quantities of CCLM
#      the calculations use *_ts.nc files from post/YYYY_MM
#########################################################

#... wind speed in 10m height
function windspeed10M {
echo calculate 10m wind speed ... 
cd ${OUTDIR}/${YYYY_MM}
uvresfile=UV_10M_ts.nc
varname=VABS_10M
outfile=${varname}_ts.nc
infile1=U_10M_ts.nc
infile2=V_10M_ts.nc
if [ ! -e ${outfile} ] ; then
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    cp  ${infile1} ${uvresfile}
    ${NCO_BINDIR}/ncks -h -A -v V_10M ${infile2} ${uvresfile}
    ${CDO} -s expr,${varname}'=(U_10M^2+V_10M^2)^0.5;' ${uvresfile} ${outfile}
    #... correct CDO created netCDF
    cdocor U_10M ${infile1} ${varname} ${outfile}
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_speed' -a long_name,${varname},o,c,'wind speed at 10m height'  ${outfile}
    rm   ${uvresfile}
    echo "Calculated wind speed at 10m height."
  else
    echo "Input fields U_10 and V_10M for calculating wind speed at 10m height are missing"
  fi
fi
}

#... derotate 10m rotated wind components to geographical lat/lon
function derotatewind10M {
echo derotate 10m wind components ... 
cd ${OUTDIR}/${YYYY_MM}
uvresfile=UV_10M_ts.nc
outfile=UVlonlat_10M_ts.nc
varnameUROT=U_10M
varnameVROT=V_10M
varnameULON=ULON_10M
varnameVLAT=VLAT_10M
infile1=${varnameUROT}_ts.nc
infile2=${varnameVROT}_ts.nc
#if [ ! -e ${outfile} ] ; then
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    cp  ${infile1} ${uvresfile}
    ${NCO_BINDIR}/ncks -h -A -v ${varnameVROT} ${infile2} ${uvresfile}
    # NWR 20201130
    # I added 'export' because I guess this is needed and does not work otherwise
    export IGNORE_ATT_COORDINATES_SAVE=${IGNORE_ATT_COORDINATES}
    export IGNORE_ATT_COORDINATES=1
    ${CDO} -s rotuvb,${varnameUROT},${varnameVROT} ${uvresfile} temp1.nc
    # NWR 20201130
    # I added 'export' because I guess this is needed and does not work otherwise
    export IGNORE_ATT_COORDINATES=${IGNORE_ATT_COORDINATES_SAVE}
    ${NCO_BINDIR}/ncrename -h -O -v ${varnameUROT},${varnameULON} -v ${varnameVROT},${varnameVLAT} temp1.nc
    ${NCO_BINDIR}/ncks -h -O -v ${varnameULON},${varnameVLAT},rotated_pole temp1.nc ${outfile}
    ${NCO_BINDIR}/ncks -h -A -v lat,lon,height_10m ${uvresfile} ${outfile}
    # repair rotated ULON
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameULON},o,c,'eastward_wind' -a long_name,"${varnameULON}",o,c,'eastward component of 10m wind' -a units,${varnameULON},o,c,'m s-1' -a coordinates,${varnameULON},c,c,'lon lat height_10m' ${outfile}
    # repair rotated VLAT
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameVLAT},o,c,'northward_wind' -a long_name,"${varnameVLAT}",o,c,'northward component of 10m wind' -a units,${varnameVLAT},o,c,'m s-1' -a coordinates,${varnameVLAT},c,c,'lon lat height_10m' ${outfile}
    # extract ULON and VLAT onto extra files
    ${NCO_BINDIR}/ncks -h -O -x -v ${varnameVLAT} ${outfile} ${varnameULON}_ts.nc
    ${NCO_BINDIR}/ncks -h -O -x -v ${varnameULON} ${outfile} ${varnameVLAT}_ts.nc
    rm ${uvresfile} temp1.nc ${outfile}
    echo "The wind components at 10m height were rotated to an unprojected geographical coordinate system (WGS84 system)".
  else
    echo "Input fields" ${varnameUROT} "and" ${varnameVROT} "for rotating wind components at 10m height are missing"
  fi
#fi
}

#... wind direction in 10m height
function winddir10M {
echo calculate 10m wind direction ...
cd ${OUTDIR}/${YYYY_MM}
varname=WDIRGEO_10M
varnameULON=ULON_10M
varnameVLAT=VLAT_10M
uvlonlatfile=UVlonlat_10M_ts.nc
outfile=${varname}_ts.nc
infile1=${varnameULON}_ts.nc
infile2=${varnameVLAT}_ts.nc
if [ ! -e ${outfile} ] ; then
#  if [ ! -f ${uvlonlatfile} ] ; then
    if [ -f ${infile1} -a -f ${infile2} ] ; then
      cp ${infile1} ${uvlonlatfile}
      ${NCO_BINDIR}/ncks -h -A -v ${varnameVLAT} ${infile2} ${uvlonlatfile}
    else
      echo "Input fields for calculating wind direction at 10m height are missing"
    fi
#  else
    ${NCO_BINDIR}/ncap2 -O -s "${varname}=float(45.0/atan(1.0)*atan2(ULON_10M,VLAT_10M)+180.0)" ${uvlonlatfile} ${uvlonlatfile}
#    ${CDO} chname,ULON_10M,${1} -addc,180 -mulc,57.29578 -atan2 -selvar,ULON_10M ${uvlonlatfile} -selvar,VLON_10M ${uvlonlatfile} ${outfile}
    ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole,height_10m ${uvlonlatfile} ${outfile}
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_from_direction' -a long_name,${varname},o,c,'wind direction at 10m height' -a units,${varname},o,c,'deg' -a coordinates,${varname},c,c,'lon lat height_10m' ${outfile}
    rm ${uvlonlatfile}
    echo "The wind direction at 10m height was determined w.r.t. the geographical WGS84 system."
#  fi
fi
}

#... snow fraction from W_SNOW values
function snowfraction {
echo calculate snow fraction ...
cd ${OUTDIR}/${YYYY_MM}
varnamew=W_SNOW
varnamef=FR_SNOW
outfile=${varnamef}_ts.nc
infile1=${varnamew}_ts.nc
if [ ! -e ${outfile} ] ; then
  if [ -f ${infile1} ] ; then
    cp  ${infile1} temp1.nc
    ${NCO_BINDIR}/ncap2 -O -s "SNOW_flg = float(${varnamew} > 0.0000005); SNOW = float(${varnamew}/0.015); where(SNOW>1.0) SNOW=1.0f; where(SNOW<0.01) SNOW=0.01f; ${varnamef}=float(SNOW*SNOW_flg)" temp1.nc temp1.nc
    ${NCO_BINDIR}/ncks -h -O -v ${varnamef},lat,lon,rotated_pole temp1.nc ${outfile}
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnamef},o,c,'surface_snow_area_fraction' -a long_name,${varnamef},o,c,'Snow Area Fraction' -a units,${varnamef},o,c,'1'  ${outfile}
    echo snowfraction ${outfile}
    rm   temp1.nc
    echo "The snow area fraction was calculated with the internally used method."
  else
    echo "Input field " ${varnamew} " for calculating snow area fraction is missing"
  fi
fi
}

#... add to fields
function addfields {
echo calculate ${3}=${1}+${2} ...
cd ${OUTDIR}/${YYYY_MM}
infile1=${1}_ts.nc
infile2=${2}_ts.nc
outfile=${3}_ts.nc
if [ ! -e ${outfile} ] ; then
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    echo "Create " ${3}
    cp  ${infile1} temp1.nc
    ${NCO_BINDIR}/ncks -h -A -v ${2} ${infile2} temp1.nc
    ${NCO_BINDIR}/ncap2 -O -s "${3}=${1}+${2}" temp1.nc temp1.nc
    ${NCO_BINDIR}/ncks -h -O -v ${3},lat,lon,rotated_pole temp1.nc ${outfile}
    case ${3} in
    'ASWD_S')
      ${NCO_BINDIR}/ncatted -h -a long_name,ASWD_S,m,c,"averaged total downward sw radiation at the surface" -a standard_name,ASWD_S,o,c,"surface_downwelling_shortwave_flux_in_air" ASWD_S_ts.nc
      ;;
    'RUNOFF_T')
      ${NCO_BINDIR}/ncatted -h -a long_name,RUNOFF_T,m,c,"total runoff" -a standard_name,RUNOFF_T,o,c,"total_runoff_amount" RUNOFF_T_ts.nc
      ;;
    'PREC_CON')
      ${NCO_BINDIR}/ncatted -h -a long_name,PREC_CON,m,c,"convective precipitation" -a standard_name,PREC_CON,o,c,"convective_precipitation_amount" PREC_CON_ts.nc 
      ;;
    'TOT_SNOW')
      ${NCO_BINDIR}/ncatted -h -a long_name,TOT_SNOW,m,c,"total snowfall" -a standard_name,TOT_SNOW,o,c,"total_snowfall_amount" TOT_SNOW_ts.nc
      ;;
    'TQW')
      ${NCO_BINDIR}/ncatted -h -a long_name,TQW,m,c,"vertical integrated cloud condensed water" -a standard_name,TQW,o,c,"atmosphere_cloud_condensed_water_content" TQW_ts.nc
      ;;
    esac
   rm  temp1.nc
  else
    echo "Input fields " ${1} " and " ${2} " for calculating " ${3} " are missing"
  fi
else
    echo $(basename ${outfile}) " already exists"
fi
}

#... substract two fields
function subtractfields {
echo calculate ${3}=${1}-${2} ...
cd ${OUTDIR}/${YYYY_MM}
RETURN_VAL=0
infile1=${1}_ts.nc
infile2=${2}_ts.nc
outfile=${3}_ts.nc
if [ ! -e ${outfile} ] ; then
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    echo "Create " ${3}
    cp  ${infile1} temp1.nc
    ${NCO_BINDIR}/ncks -h -A -v ${2} ${infile2} temp1.nc
    ${NCO_BINDIR}/ncap2 -O -s "${3}=${1}-${2}" temp1.nc temp1.nc
    ${NCO_BINDIR}/ncks -h -O -v ${3},lat,lon,rotated_pole temp1.nc ${outfile}
    case ${3} in
    'ASOU_T')
      ${NCO_BINDIR}/ncatted -h -a long_name,ASOU_T,m,c,"averaged solar upward radiation at top" -a standard_name,ASOU_T,m,c,"toa_outgoing_shortwave_flux" ASOU_T_ts.nc
      ;;
    esac
    rm  temp1.nc
  else
    echo "Input fields " ${1} " and " ${2} " for calculating " ${3} " are missing"
  fi
else
    echo $(basename ${outfile}) " already exists"
fi
}

#... wind speed on pressure levels
function windspeedp {
  echo calculate wind speed on p-levels ...
  # NWR 20201130
  # the below command destroys the PLEV array...
  # So I commented this out
  #declare -a PLEVS=("${!1}")
varname=VABS
NPLEV=1
while [ ${NPLEV} -le ${PLEVS[0]} ]
do
  PLEV=$(python -c "print(int(${PLEVS[$NPLEV]}))")
  infile1=${OUTDIR}/${YYYY_MM}/U${PLEV}p_ts.nc
  infile2=${OUTDIR}/${YYYY_MM}/V${PLEV}p_ts.nc
  outfile=${OUTDIR}/${YYYY_MM}/${varname}${PLEV}p_ts.nc
  uvresfile=${OUTDIR}/${YYYY_MM}/UV${PLEV}p_ts.nc
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    cp  ${infile1} ${uvresfile}
    ${NCO_BINDIR}/ncks -h -A -v V ${infile2} ${uvresfile}
    ${CDO} -s expr,${varname}'=(U^2+V^2)^0.5;' ${uvresfile} ${outfile}
    #... correct CDO created netCDF
    cdocor U ${infile1} ${varname} ${outfile}
#    ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole ${uvresfile} ${outfile}
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_speed' -a long_name,${varname},o,c,'wind speed'  ${outfile}
    rm ${uvresfile}
  else
    echo "ERROR: Input fields U"${PLEV}" and V"${PLEV}" for calculating wind speed at "${PLEV}"hPa are missing"
  fi
  let "NPLEV = NPLEV + 1"
done
}

#... wind speed on z levels
function windspeedz {
  echo calculate wind speed on height levels ...
  declare -a ZLEVS=("${!1}")
  ERROR_STATUS=$?
  set -e
  if [ -f ${OUTDIR}/${YYYY_MM}/U${ZLEV}z_ts.nc ]
  then
    HEIGHT=height
    NN=
  else
    HEIGHT=altitude
    NN=NN
  fi
  varname=VABS
  NZLEV=1
  while [ ${NZLEV} -le ${ZLEVS[0]} ]
  do
    ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))") 
    infile1=${OUTDIR}/${YYYY_MM}/U${ZLEV}z${NN}_ts.nc
    infile2=${OUTDIR}/${YYYY_MM}/V${ZLEV}z${NN}_ts.nc
    outfile=${OUTDIR}/${YYYY_MM}/${varname}${ZLEV}z${NN}_ts.nc
    uvresfile=${OUTDIR}/${YYYY_MM}/UV${ZLEV}z${NN}_ts.nc
  if [ -f ${infile1} -a -f ${infile2} ] ; then
    cp  ${infile1} ${uvresfile}
    ${NCO_BINDIR}/ncks -h -A -v V ${infile2} ${uvresfile}
    ${CDO} -s expr,${varname}'=(U^2+V^2)^0.5;' ${uvresfile} ${outfile}
    #... correct CDO created netCDF
    cdocor U ${infile1} ${varname} ${outfile}
#    ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole ${uvresfile} ${outfile}
    ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_speed' -a long_name,${varname},o,c,'wind speed'  ${outfile}
    rm ${uvresfile}
  else
    echo "ERROR: Input fields U"${ZLEV}" and V"${ZLEV}" for calculating wind speed at "${ZLEV}"m are missing"
  fi
     let "NZLEV = NZLEV + 1"
  done
}

#... derotate rotated wind components on p-level to geographical lat/lon
function derotatewindp {
  echo derotate wind speed on p-levels ...
  # NWR 20201130
  # the below command destroys the PLEV array...
  # So I commented this out
  #declare -a PLEVS=("${!1}")
  varnameUROT=U
  varnameVROT=V
  varnameULON=ULON
  varnameVLAT=VLAT
  NPLEV=1
  while [ ${NPLEV} -le ${PLEVS[0]} ]
  do
    PLEV=$(python -c "print(int(${PLEVS[$NPLEV]}))")
    outfile=${OUTDIR}/${YYYY_MM}/UVlonlat${PLEV}p_ts.nc
    if [ ! -e ${outfile} ] ; then
      uvresfile=UV${PLEV}p_ts.nc
      infile1=${OUTDIR}/${YYYY_MM}/U${PLEV}p_ts.nc
      infile2=${OUTDIR}/${YYYY_MM}/V${PLEV}p_ts.nc
      if [ -f ${infile1} -a -f ${infile2} ] ; then
        cp  ${infile1} ${uvresfile}
        ${NCO_BINDIR}/ncks -h -A -v ${varnameVROT} ${infile2} ${uvresfile}
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES_SAVE=${IGNORE_ATT_COORDINATES}
        export IGNORE_ATT_COORDINATES=1
        ${CDO} -s rotuvb,${varnameUROT},${varnameVROT} ${uvresfile} temp1.nc
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES=${IGNORE_ATT_COORDINATES_SAVE}
        ${NCO_BINDIR}/ncrename -h -O -v ${varnameUROT},${varnameULON} -v ${varnameVROT},${varnameVLAT} temp1.nc
        ${NCO_BINDIR}/ncks -h -O -v ${varnameULON},${varnameVLAT},rotated_pole temp1.nc ${outfile}
        ${NCO_BINDIR}/ncks -h -A -v lat,lon,pressure ${uvresfile} ${outfile}
        # repair rotated Ulat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameULON},o,c,'eastward_wind' -a long_name,"${varnameULON}",o,c,'eastward wind component' -a units,${varnameULON},o,c,'m s-1' -a coordinates,${varnameULON},c,c,'lon lat' ${outfile}
        # repair rotated Vlat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameVLAT},o,c,'northward_wind' -a long_name,"${varnameVLAT}",o,c,'northward wind component' -a units,${varnameVLAT},o,c,'m s-1' -a coordinates,${varnameVLAT},c,c,'lon lat' ${outfile}
        rm ${uvresfile} temp1.nc
        # extract U and V into extra files
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameVLAT} ${outfile} ${varnameULON}${PLEV}p_ts.nc
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameULON} ${outfile} ${varnameVLAT}${PLEV}p_ts.nc
        echo "The wind components at "${PLEV}"hPa were rotated to an unprojected geographical coordinate system (WGS84 system)".
      else
        echo "Input fields" ${varnameUROT} "and" ${varnameVROT} "for rotating wind components at "${PLEV}"hpa are missing"
      fi
    fi
    rm ${outfile}
    let "NPLEV = NPLEV + 1"
  done
}


#... derotate rotated wind components on z-level to geographical lat/lon
function derotatewindz {
  echo derotate wind speed on z-levels ...
  varnameUROT=U
  varnameVROT=V
  varnameULON=ULON
  varnameVLAT=VLAT
  declare -a ZLEVS=("${!1}")
  #... height above ground
  if [ -f ${OUTDIR}/${YYYY_MM}/U${ZLEV}z_ts.nc ]
  then
    HEIGHT=height
    NN=
  ZLEV=$(python -c "print(int(${ZLEVS[1]}))")
  set +e
  NZLEV=1
  while [ ${NZLEV} -le ${ZLEVS[0]} ]
  do
    ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
    outfile=${OUTDIR}/${YYYY_MM}/UVlonlat${ZLEV}z${NN}_ts.nc
    if [ ! -e ${outfile} ] ; then
      uvresfile=UV${ZLEV}z${NN}_ts.nc
      infile1=${OUTDIR}/${YYYY_MM}/U${ZLEV}z${NN}_ts.nc
      infile2=${OUTDIR}/${YYYY_MM}/V${ZLEV}z${NN}_ts.nc
      if [ -f ${infile1} -a -f ${infile2} ] ; then
        cp  ${infile1} ${uvresfile}
        ${NCO_BINDIR}/ncks -h -A -v ${varnameVROT} ${infile2} ${uvresfile}
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES_SAVE=${IGNORE_ATT_COORDINATES}
        export IGNORE_ATT_COORDINATES=1
        ${CDO} -s rotuvb,${varnameUROT},${varnameVROT} ${uvresfile} temp1.nc
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES=${IGNORE_ATT_COORDINATES_SAVE}
        ${NCO_BINDIR}/ncrename -h -O -v ${varnameUROT},${varnameULON} -v ${varnameVROT},${varnameVLAT} temp1.nc
        ${NCO_BINDIR}/ncks -h -O -v ${varnameULON},${varnameVLAT},rotated_pole temp1.nc ${outfile}
        cdocor ${varnameUROT} ${infile1} ${varnameULON} ${outfile}
        cdocor ${varnameVROT} ${infile1} ${varnameVLAT} ${outfile}
        ${NCO_BINDIR}/ncks -h -A -v lat,lon,${HEIGHT} ${uvresfile} ${outfile}
        # repair rotated Ulat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameULON},o,c,'eastward_wind' -a long_name,"${varnameULON}",o,c,'eastward wind component' -a units,${varnameULON},o,c,'m s-1' -a coordinates,${varnameULON},c,c,'lon lat' ${outfile}
        # repair rotated Vlat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameVLAT},o,c,'northward_wind' -a long_name,"${varnameVLAT}",o,c,'northward wind component' -a units,${varnameVLAT},o,c,'m s-1' -a coordinates,${varnameVLAT},c,c,'lon lat' ${outfile}
        rm ${uvresfile} temp1.nc
        # extract U and V into extra files
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameVLAT} ${outfile} ${varnameULON}${ZLEV}z${NN}_ts.nc
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameULON} ${outfile} ${varnameVLAT}${ZLEV}z${NN}_ts.nc
        echo "The wind components at "${ZLEV}"m height were rotated to an unprojected geographical coordinate system (WGS84 system)".
  else
        echo "Input fields" ${varnameUROT} "and" ${varnameVROT} "for rotating wind components at "${ZLEV}"m "${HEIGHT}" are missing"
      fi
    fi
    rm ${outfile}
    let "NZLEV = NZLEV + 1"
  done
  fi

  #... height above NN  
  if [ -f ${OUTDIR}/${YYYY_MM}/U${ZLEV}zNN_ts.nc ]
  then
    HEIGHT=altitude
    NN=NN
  ZLEV=$(python -c "print(int(${ZLEVS[1]}))")
  set +e
  NZLEV=1
  while [ ${NZLEV} -le ${ZLEVS[0]} ]
  do
    ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
    outfile=${OUTDIR}/${YYYY_MM}/UVlonlat${ZLEV}z${NN}_ts.nc
    if [ ! -e ${outfile} ] ; then
      uvresfile=UV${ZLEV}z${NN}_ts.nc
      infile1=${OUTDIR}/${YYYY_MM}/U${ZLEV}z${NN}_ts.nc
      infile2=${OUTDIR}/${YYYY_MM}/V${ZLEV}z${NN}_ts.nc
      if [ -f ${infile1} -a -f ${infile2} ] ; then
        cp  ${infile1} ${uvresfile}
        ${NCO_BINDIR}/ncks -h -A -v ${varnameVROT} ${infile2} ${uvresfile}
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES_SAVE=${IGNORE_ATT_COORDINATES}
        export IGNORE_ATT_COORDINATES=1
        ${CDO} -s rotuvb,${varnameUROT},${varnameVROT} ${uvresfile} temp1.nc
        # NWR 20201130
        # I added 'export' because I guess this is needed and does not work otherwise
        export IGNORE_ATT_COORDINATES=${IGNORE_ATT_COORDINATES_SAVE}
        ${NCO_BINDIR}/ncrename -h -O -v ${varnameUROT},${varnameULON} -v ${varnameVROT},${varnameVLAT} temp1.nc
        ${NCO_BINDIR}/ncks -h -O -v ${varnameULON},${varnameVLAT},rotated_pole temp1.nc ${outfile}
        cdocor ${varnameUROT} ${infile1} ${varnameULON} ${outfile}
        cdocor ${varnameVROT} ${infile1} ${varnameVLAT} ${outfile}
        ${NCO_BINDIR}/ncks -h -A -v lat,lon,${HEIGHT} ${uvresfile} ${outfile}
        # repair rotated Ulat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameULON},o,c,'eastward_wind' -a long_name,"${varnameULON}",o,c,'eastward wind component' -a units,${varnameULON},o,c,'m s-1' -a coordinates,${varnameULON},c,c,'lon lat' ${outfile}
        # repair rotated Vlat
        ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varnameVLAT},o,c,'northward_wind' -a long_name,"${varnameVLAT}",o,c,'northward wind component' -a units,${varnameVLAT},o,c,'m s-1' -a coordinates,${varnameVLAT},c,c,'lon lat' ${outfile}
        rm ${uvresfile} temp1.nc
        # extract U and V into extra files
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameVLAT} ${outfile} ${varnameULON}${ZLEV}z${NN}_ts.nc
        ${NCO_BINDIR}/ncks -h -O -x -v ${varnameULON} ${outfile} ${varnameVLAT}${ZLEV}z${NN}_ts.nc
        echo "The wind components at "${ZLEV}"m height were rotated to an unprojected geographical coordinate system (WGS84 system)".
      else
        echo "Input fields" ${varnameUROT} "and" ${varnameVROT} "for rotating wind components at "${ZLEV}"m "${HEIGHT}" are missing"
        echo ${infile1} ${uvresfile}
      fi
    fi
    rm ${outfile}
    let "NZLEV = NZLEV + 1"
  done
  fi
}


#... wind direction on p-level
function winddirp {
  echo calculate wind direction on p-levels ...
  # NWR 20201130
  # the below command destroys the PLEV array...
  # So I commented this out
  #declare -a PLEVS=("${!1}")
   cd ${OUTDIR}/${YYYY_MM}
   varname=WDIRGEO
   varnameULON=ULON
   varnameVLAT=VLAT
   uvlonlatfile=UVlonlat_ts.nc

   NPLEV=1
   while [ ${NPLEV} -le ${PLEVS[0]} ]
   do
     PLEV=$(python -c "print(int(${PLEVS[$NPLEV]}))")
     infile1=${varnameULON}${PLEV}p_ts.nc
     infile2=${varnameVLAT}${PLEV}p_ts.nc
     outfile=${varname}${PLEV}p_ts.nc
     if [ ! -e ${outfile} ] ; then
#       if [ ! -f ${uvlonlatfile} ] ; then
         if [ -f ${infile1} -a -f ${infile2} ] ; then
           cp ${infile1} ${uvlonlatfile}
           ${NCO_BINDIR}/ncks -h -A -v ${varnameVLAT} ${infile2} ${uvlonlatfile}
         else
           echo "Input fields for calculating wind direction at "${PLEV}"hPa are missing"
         fi
#       else
         ${NCO_BINDIR}/ncap2 -O -s "${varname}=float(45.0/atan(1.0)*atan2(ULON,VLAT)+180.0)" ${uvlonlatfile} ${uvlonlatfile}
#         ${CDO} chname,ULON,${1} -addc,180 -mulc,57.29578 -atan2 -selvar,ULON ${uvlonlatfile} -selvar,VLON ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole,pressure ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_from_direction' -a long_name,${varname},o,c,'wind direction' -a units,${varname},o,c,'deg' -a coordinates,${varname},o,c,'lon lat' ${outfile}
         rm ${uvlonlatfile}
        echo "The wind direction at "${PLEV}"hPa was determined w.r.t. the geographical WGS84 system."
#      fi
    fi
      let "NPLEV = NPLEV + 1"
   done
}


#... wind direction on z-level
function winddirz {
  echo calculate wind direction on z-levels ...
  varname=WDIRGEO
  varnameULON=ULON
  varnameVLAT=VLAT
  declare -a ZLEVS=("${!1}")
  #... height above ground
  if [ -f ${varnameULON}${ZLEV}z_ts.nc ]
  then
    HEIGHT=height
    NN=
  ZLEV=$(python -c "print(int(${ZLEVS[1]}))")
  set +e
   cd ${OUTDIR}/${YYYY_MM}
   uvlonlatfile=UVlonlat_ts.nc

   NZLEV=1
   while [ ${NZLEV} -le ${ZLEVS[0]} ]
   do
     ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
     infile1=${varnameULON}${ZLEV}z${NN}_ts.nc
     infile2=${varnameVLAT}${ZLEV}z${NN}_ts.nc
     outfile=${varname}${ZLEV}z${NN}_ts.nc
     if [ ! -e ${outfile} ] ; then
#       if [ ! -f ${uvlonlatfile} ] ; then
         if [ -f ${infile1} -a -f ${infile2} ] ; then
           cp ${infile1} ${uvlonlatfile}
           ${NCO_BINDIR}/ncks -h -A -v ${varnameVLAT} ${infile2} ${uvlonlatfile}
  else
           echo "Input fields for calculating wind direction at "${ZLEV}"m "${HEIGHT}" are missing"
  fi
#       else
         ${NCO_BINDIR}/ncap2 -O -s "${varname}=float(45.0/atan(1.0)*atan2(ULON,VLAT)+180.0)" ${uvlonlatfile} ${uvlonlatfile}
#         ${CDO} chname,ULON,${1} -addc,180 -mulc,57.29578 -atan2 -selvar,ULON ${uvlonlatfile} -selvar,VLON ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole,${HEIGHT} ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_from_direction' -a long_name,${varname},o,c,'wind direction' -a units,${varname},o,c,'deg' -a coordinates,${varname},o,c,'lon lat' ${outfile}
         rm ${uvlonlatfile}
        echo "The wind direction at "${ZLEV}"m "${HEIGHT}" was determined w.r.t. the geographical WGS84 system."
#      fi
    fi
      let "NZLEV = NZLEV + 1"
   done
   fi
  #... height above NN
  if [ -f ${varnameULON}${ZLEV}zNN_ts.nc ]
  then
    HEIGHT=height
    NN=NN
   ZLEV=$(python -c "print(int(${ZLEVS[1]}))")
  set +e
   cd ${OUTDIR}/${YYYY_MM}
   uvlonlatfile=UVlonlat_ts.nc

   NZLEV=1
   while [ ${NZLEV} -le ${ZLEVS[0]} ]
   do
     ZLEV=$(python -c "print(int(${ZLEVS[$NZLEV]}))")
     infile1=${varnameULON}${ZLEV}z${NN}_ts.nc
     infile2=${varnameVLAT}${ZLEV}z${NN}_ts.nc
     outfile=${varname}${ZLEV}z${NN}_ts.nc
     if [ ! -e ${outfile} ] ; then
#       if [ ! -f ${uvlonlatfile} ] ; then
         if [ -f ${infile1} -a -f ${infile2} ] ; then
           cp ${infile1} ${uvlonlatfile}
           ${NCO_BINDIR}/ncks -h -A -v ${varnameVLAT} ${infile2} ${uvlonlatfile}
         else
           echo "Input fields for calculating wind direction at "${ZLEV}"m "${HEIGHT}" are missing"
         fi
#       else
         ${NCO_BINDIR}/ncap2 -O -s "${varname}=float(45.0/atan(1.0)*atan2(ULON,VLAT)+180.0)" ${uvlonlatfile} ${uvlonlatfile}
#         ${CDO} chname,ULON,${1} -addc,180 -mulc,57.29578 -atan2 -selvar,ULON ${uvlonlatfile} -selvar,VLON ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncks -h -O -v ${varname},lat,lon,rotated_pole,${HEIGHT} ${uvlonlatfile} ${outfile}
         ${NCO_BINDIR}/ncatted -h -O -a standard_name,${varname},o,c,'wind_from_direction' -a long_name,${varname},o,c,'wind direction' -a units,${varname},o,c,'deg' -a coordinates,${varname},o,c,'lon lat' ${outfile}
         rm ${uvlonlatfile}
        echo "The wind direction at "${ZLEV}"m "${HEIGHT}" was determined w.r.t. the geographical WGS84 system."
#      fi
    fi
      let "NZLEV = NZLEV + 1"
   done
   fi
}

# Calculation of the diurnal temperature range
function dtr {
echo calculate the diurnal temperature range ...
  cdo -s sub ${OUTDIR}/${YYYY_MM}/TMAX_2M_ts.nc ${OUTDIR}/${YYYY_MM}/TMIN_2M_ts.nc ${OUTDIR}/${YYYY_MM}/DTR_2M_ts.nc
  ncrename -h -v TMAX_2M,DTR_2M ${OUTDIR}/${YYYY_MM}/DTR_2M_ts.nc
  ncatted -h -a long_name,DTR_2M,m,c,"diurnal temperature range" ${OUTDIR}/${YYYY_MM}/DTR_2M_ts.nc
  ncatted -h -a cell_methods,DTR_2M,d,, ${OUTDIR}/${YYYY_MM}/DTR_2M_ts.nc
}


