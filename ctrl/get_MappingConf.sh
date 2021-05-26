#!/bin/bash
#
# author: Niklas WAGNER
# e-mail: n.wagner@fz-juelich.de
# version: 2021-05-25
# USAGE:
# 1) >> source get_MappingConf
# 2) >> get_mappingConf PROC_COSMO_X PROC_COSMO_Y PROC_PARFLOW_P PROC_PARFLOW_Q PROC_CLM OUTFILE

get_mappingConf() {
  #----------------------------------------------------------------------------
  # This script does create the 'slm_multiprog_mapping.conf ' needed by TSMP
  # Bases on the individual proc distribution this is written to the form:
  #   0-(XXX-1)     ./lmparbin_pur
  #   XXX-(YYY-1)   ./parflow cordex0.11
  #   YYY-(ZZZ-1)   ./clm
  # Whereby OUTFILE is used as output
  #----------------------------------------------------------------------------

	PROC_COSMO_X=$1
	PROC_COSMO_Y=$2
  PROC_PARFLOW_P=$3
  PROC_PARFLOW_Q=$4
  PROC_CLM=$5
  OUTFILE=$6
  XXX=$((PROC_COSMO_X*PROC_COSMO_Y))
  XXXm1=$((XXX-1))
  YYY=$(( XXX + (PROC_PARFLOW_P*PROC_PARFLOW_Q) ))
  YYYm1=$((YYY-1))
  ZZZ=$(( YYY + PROC_CLM ))
  ZZZm1=$((ZZZ-1))
/bin/cat <<EOM >${OUTFILE}
0-${XXXm1} ./lmparbin_pur
${XXX}-${YYYm1} ./parflow __pfidb__
${YYY}-${ZZZm1} ./clm
EOM

}
