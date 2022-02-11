#!/bin/bash
#
# author: Niklas Wagner
# e-mail: n.wagner@fz-juelich.de
# last modified: 2022-02-11
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate,CTRLDIR=$BASE_CTRLDIR \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_simulation.sh
#
# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command 
# 1) CTRLDIR (tell the program where the ctrl dir of the workflow sit)
# 2) startDate (tell the program for which month to start the sim)
echo "--- source environment"
source ${CTRLDIR}/export_paths.ksh
source ${BASE_CTRLDIR}/start_helper.sh

cd $BASE_CTRLDIR
./starter_prepo.sh $BASE_CTRLDIR $startDate
wait

exit 0
