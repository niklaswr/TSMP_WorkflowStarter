#!/usr/bin/ksh
#
#SBATCH --job-name="AUX_gzip"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --time=01:00:00
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=slts
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> sbatch ./$0 NCPU TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# >> sbatch ./aux_gzip_general.ksh 48 /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run_TSMP/laf_lbfd/201[8,9]

MAX_PARALLEL=$1
echo "MAX_PARALLEL: $MAX_PARALLEL"
shift 1
FILES=($@)
echo "${FILES[@]}"
nroffiles=${#FILES[@]}
echo "nroffiles: $nroffiles"
(( setsize=nroffiles/MAX_PARALLEL +1))
echo "setsize: $setsize"
for (( n=0; n<=$nroffiles; n=n+$setsize ))
do
  subsetFILES=${FILES[@]:$n:$setsize}
  gunzip $subsetFILES &
done
wait

