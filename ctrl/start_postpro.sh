#!/bin/bash
# Using a 'strict' bash
set -xe
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> ./$0 $startDate
# >> ./starter_postpro.sh $startDate

###############################################################################
# Prepare
###############################################################################
startDate=$1
echo "###################################################"
echo "START Logging ($(date)):"
echo "###################################################"
echo "--- exe: $0"
echo "--- Simulation    init-date: ${initDate}"
echo "---              start-data: ${startDate}"
echo "---                  CaseID: ${CaseID}"
echo "---            CaseCalendar: ${CaseCalendar}"
echo "---             COMBINATION: ${COMBINATION}"
echo "--- HOST:  $(hostname)"

echo "--- source helper scripts"
source ${BASE_CTRLDIR}/start_helper.sh
source ${BASE_CTRLDIR}/envs/env_postpro

h0=$(date -u -d "$startDate" '+%H')
d0=$(date -u -d "$startDate" '+%d')
m0=$(date -u -d "$startDate" '+%m')
y0=$(date -u -d "$startDate" '+%Y')

###############################################################################
# Post-Pro
###############################################################################
# Place post-processing steps here
# NOTE: scripts HAVE to run on compute-nodes.
# If the script runs in parralel or on single cpu is not important
initDate=${BASE_INITDATE} #DO NOT TOUCH! start of the whole TSMP simulation
formattedStartDate=$(date -u -d "${startDate}" ${dateString})
pfidb="ParFlow_EU11_${formattedStartDate}"
SimresDir="${BASE_SIMRESDIR}/${formattedStartDate}"
ToPostProDir="${BASE_RUNDIR}/ToPostPro/${formattedStartDate}"
PostProStoreDir="${BASE_POSTPRODIR}/${formattedStartDate}"
SLOTHDIR="${BASE_SRCDIR}/SLOTH/sloth"
# Remove ToPostProDir in case already exisit, to avoid conflicts.
# E.g. from some simulation before.
if [[ -d ${ToPostProDir} ]]; then
  rm -rv ${ToPostProDir}
fi
mkdir -vp ${PostProStoreDir} 

# Enter ctrl/postpro/ dir for needed scripts
cd ${BASE_CTRLDIR}/postpro
echo "DEBUG: pwd --> $(pwd)"
################################################################################
# Handle individual components
################################################################################
IFS='-' read -ra components <<< "${COMBINATION}"
for component in "${components[@]}"; do
  ##############################################################################
  # COSMO
  ##############################################################################
  if [ "${component}" = "cos" ]; then
    echo "--- -- - cos"
    echo "DEBUG: Create subdir within ToPostPro"
    mkdir -vp ${ToPostProDir}/cosmo_out
    echo "DEBUG: link raw model output to ToPostPro"
    # Do nothing nutil CMORizer is ready, no double work
    #ln -sf ${SimresDir}/cosmo/* ${ToPostProDir}/cosmo_out/
    # CMOR
  ##############################################################################
  # CLM
  ##############################################################################
  elif [ "${component}" = "clm" ]; then
    echo "--- -- - clm"
    echo "DEBUG: Create subdir within ToPostPro"
    mkdir -vp ${ToPostProDir}/clm_out
    echo "DEBUG: link raw model output to ToPostPro"
    # Do nothing nutil CMORizer is ready, no double work
    #ln -sf ${SimresDir}/clm/* ${ToPostProDir}/clm_out/
    # CMOR
  ##############################################################################
  # ParFlow
  ##############################################################################
  elif [ "${component}" = "pfl" ]; then
    echo "--- -- - pfl"
    echo "DEBUG: Create subdir within ToPostPro"
    mkdir -vp ${ToPostProDir}/parflow_out
    #echo "DEBUG: link raw model output to ToPostPro"
    #ln -sf ${SimresDir}/parflow/* ${ToPostProDir}/parflow_out/

    # .pfb -> .nc
    # add correct grid
    echo "DEBUG: convert .pfb files to .nc and add grid information"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/${pfidb}.out.n.pfb \
      --varname n \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.n.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.n.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.n.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.alpha.pfb \
      --varname alpha \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.alpha.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.alpha.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.alpha.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.mask.pfb \
      --varname mask \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.mask.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.mask.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.mask.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.sres.pfb \
      --varname sres \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.sres.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.sres.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.sres.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.ssat.pfb \
      --varname ssat \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.ssat.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.ssat.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.ssat.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.perm_x.pfb \
      --varname perm_x \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.perm_x.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_x.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_x.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.perm_y.pfb \
      --varname perm_y \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.perm_y.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_y.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_y.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.perm_z.pfb \
      --varname perm_z \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.perm_z.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_z.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.perm_z.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.porosity.pfb \
      --varname porosity \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.porosity.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.porosity.nc_tmp" \
     "${ToPostProDir}/parflow_out/${pfidb}.out.porosity.nc"
    python ${SLOTHDIR}/tmp/Pfb2NetCDF.py \
      --infiles ${SimresDir}/parflow/*.out.specific_storage.pfb \
      --varname specific_storage \
      --outfile ${ToPostProDir}/parflow_out/${pfidb}.out.specific_storage.nc_tmp 
    cdo -L -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.specific_storage.nc_tmp" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.specific_storage.nc"

    # Add time info (refdate and calendar) to ParFlow output, split for 
    # individual variables and merge for one file per simulation length.
    # Therefore loop over all files in simres/ and write output to ToPostPro/
    pflFiles=$(ls ${SimresDir}/parflow/${pfidb}.out.?????.nc)
    bash ${BASE_CTRLDIR}/postpro/addTimeInfoAnsSplitVar.sh ${startDate} \
      ${CaseCalendar} "${ToPostProDir}/parflow_out" ${POST_NTASKS} \
      "${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      ${pflFiles}

    # extract static vars from *.out.00000.nc
    cdo -L -f nc4c -z zip_4 \
      -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      -selvar,slopex "${SimresDir}/parflow/${pfidb}.out.00000.nc" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.slopex.nc"
    cdo -L -f nc4c -z zip_4 \
      -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      -selvar,slopey "${SimresDir}/parflow/${pfidb}.out.00000.nc" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.slopey.nc"
    cdo -L -f nc4c -z zip_4 \
      -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      -selvar,mannings "${SimresDir}/parflow/${pfidb}.out.00000.nc" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.mannings.nc"
    cdo -L -f nc4c -z zip_4 \
      -setgrid,"${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      -selvar,DZ_Multiplier "${SimresDir}/parflow/${pfidb}.out.00000.nc" \
      "${ToPostProDir}/parflow_out/${pfidb}.out.DZ_Multiplier.nc"

    # calc water vars
    python calcParFlowDiagnosticVars.py \
      --pressure "${ToPostProDir}/parflow_out/${pfidb}.out.[0-9]*_pressure.nc" \
      --pressureVarName "pressure" \
      --nFile "${ToPostProDir}/parflow_out/${pfidb}.out.n.nc" \
      --alphaFile "${ToPostProDir}/parflow_out/${pfidb}.out.alpha.nc" \
      --sresFile "${ToPostProDir}/parflow_out/${pfidb}.out.sres.nc" \
      --ssatFile "${ToPostProDir}/parflow_out/${pfidb}.out.ssat.nc" \
      --maskFile "${ToPostProDir}/parflow_out/${pfidb}.out.mask.nc" \
      --permXFile "${ToPostProDir}/parflow_out/${pfidb}.out.perm_x.nc" \
      --permYFile "${ToPostProDir}/parflow_out/${pfidb}.out.perm_y.nc" \
      --permZFile "${ToPostProDir}/parflow_out/${pfidb}.out.perm_z.nc" \
      --porosityFile "${ToPostProDir}/parflow_out/${pfidb}.out.porosity.nc" \
      --specificStorageFile "${ToPostProDir}/parflow_out/${pfidb}.out.specific_storage.nc" \
      --slopexFile "${ToPostProDir}/parflow_out/${pfidb}.out.slopex.nc" \
      --slopeyFile "${ToPostProDir}/parflow_out/${pfidb}.out.slopey.nc" \
      --manningsFile "${ToPostProDir}/parflow_out/${pfidb}.out.mannings.nc" \
      --dzMultFile "${ToPostProDir}/parflow_out/${pfidb}.out.DZ_Multiplier.nc" \
      --dz 2 --dy 12500 --dx 12500 --dt 0.25 \
      --outDir "${ToPostProDir}/parflow_out" \
      --griddesFile "${BASE_GEODIR}/grids/EUR-11_TSMP_FZJ-IBG3_CLMPFLDomain_444x432_griddes.txt" \
      --LLSMFile "${BASE_GEODIR}/land-lake-sea-mask/EUR-11_TSMP_FZJ-IBG3_444x432_LAND-LAKE-SEA-MASK.nc" \
      --outPrepandName "${pfidb}"
    # CMOR
  fi
done

# clean up temp-files
find ${ToPostProDir} -name "*_tmp" -type f -delete

echo "-- START monitoring and monitoring-ts"
newMonitoringDir="${BASE_MONITORINGDIR}/${formattedStartDate}"
# Clean up if already exist, to avoid conflicts.
if [[ -d ${newMonitoringDir} ]]; then
  rm -rf ${newMonitoringDir}
fi
# Create new monitoring dir
mkdir -p ${BASE_MONITORINGDIR}/${formattedStartDate}
# run monitoring_ts script
cd ${BASE_CTRLDIR}/monitoring/
python monitoring_ts.py \
	--configFile ./CONFIG_ts \
	--dataRootDir ${ToPostProDir}/parflow_out \
  --tmpDataDir ${BASE_MONITORINGDIR} \
	--saveDir ${newMonitoringDir}
python monitoring_generic.py \
  --configFile CONFIG_generic \
  --dataRootDir ${SimresDir} \
  --saveDir ${newMonitoringDir} \
  --runName ${CaseID}
#python monitoring.py \
#	--configFile ./CONFIG \
#	--dataRootDir ${ToPostProDir}/parflow_out \
#	#--dataRootDir ${BASE_POSTPRODIR}/${formattedStartDate} \
#  --tmpDataDir ${BASE_MONITORINGDIR} \
#	--saveDir ${newMonitoringDir}
echo "--- END monitoring"

exit 0
