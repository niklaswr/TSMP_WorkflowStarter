#!/usr/bin/ksh
#
#SBATCH --job-name="AUX_gunzip"
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

cd $1
DIR=$1
MAX_PARALLEL=48
nroffiles=$(ls $DIR|wc -w)
(( setsize=nroffiles/MAX_PARALLEL ))
ls -1 $DIR/* | xargs -n $setsize | while read workset; do
  gunzip $workset&
done
wait
