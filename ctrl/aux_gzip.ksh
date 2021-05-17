#!/usr/bin/ksh
#
#SBATCH --job-name="AUX_gzip"
#SBATCH --nodes=1
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=48
#SBATCH --time=01:00:00
#SBATCH --partition=batch
##SBATCH --mail-type=ALL
##SBATCH --mail-user=n.wagner@fz-juelich.de
#SBATCH --account=jibg35

# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2020-12-12
# USAGE: 
# >> sbatch ./$0 NCPU TARGET/DIR
# >> sbatch ./aux_gzip.ksh 48 /p/scratch/cjibg35/tsmpforecast/ERA5Climat_EUR11_ECMWF-ERA5_analysis_FZJ-IBG3/run_TSMP/laf_lbfd/1980/

DIR=$2
cd $DIR
MAX_PARALLEL=$1
nroffiles=$(ls $DIR|wc -w)
(( setsize=nroffiles/MAX_PARALLEL ))
ls -1 $DIR/* | xargs -n $setsize | while read workset; do
  gzip $workset&
done
wait
