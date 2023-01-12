#!/bin/bash
#
# Owner / author: Niklas WAGNER, n.wagner@fz-juelich.de
# USAGE: 
# >> sbatch --export=ALL,startDate=$startDate, \
#           -o "${BASE_LOGDIR}/%x-out" -e "${BASE_LOGDIR}/%x-err" \
#           --mail-user=$userEmail --account=$computeAcount \
#           start_simulation.sh
#
# IMPORTANT the following variables HAVE TO be set via the
# sbatch --export command 
# 1) ALL (ensure exported variables are passed to each subse. called script)
# 2) startDate (tell the program for which month to start the sim)

cd $BASE_CTRLDIR
./starter_prepo.sh $startDate
wait

exit 0
