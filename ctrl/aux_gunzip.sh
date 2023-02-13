#!/bin/bash
#
#SBATCH --job-name="AUX_gunzip"
#SBATCH --nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=128
#SBATCH --time=01:00:00
#SBATCH --partition=dc-cpu-devel
#SBATCH --account=slts
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
#
# USAGE: 
# >> sbatch ./$0 TARGET/FILES/WILDCARDS/ARE/POSSIBL*
# >> sbatch ./aux_gzip_general.ksh /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run_TSMP/laf_lbfd/201[8,9]

parallelGzip() (
  # Simple run gzip on inFile
  tmpInFile=$1
  gunzip ${tmpInFile} 
)

MAX_PARALLEL=${SLURM_NTASKS}
echo "MAX_PARALLEL: $MAX_PARALLEL"
inFiles=$@
echo "${inFiles[@]}"
# set some helper-vars
tmp_parallel_counter=0
for inFile in $inFiles
do
  echo "DEBUG: inFile ${inFile}"
  parallelGzip ${inFile} &
  # Count how many tasks are already started, and wait if MAX_PARALLEL
  # (set to max number of available CPU) is reached.
  (( tmp_parallel_counter++ ))
  if [ $tmp_parallel_counter -ge $MAX_PARALLEL ]; then
    # If MAX_PARALLEL is reached wait for all tasks to finsh before continue
    wait
    tmp_parallel_counter=0
  fi
done
wait
