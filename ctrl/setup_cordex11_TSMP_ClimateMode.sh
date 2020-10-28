#!/bin/bash -x
#L.Poshyvailo -- 2020; modification for continuous runs -- help of A.Strube (FZ JSC), 2020, idea -- L.Poshyvailo, 2020
# NWR 20201019: mod. for ERA5Clima
# USAGE: $0 $(pwd)

CTRLDIR=$1
source ${CTRLDIR}/export_paths.ksh

WORK_DIR="${BASE_RUNDIR_TSMP}"
#WORK_DIR="/p/scratch/cjibg35/tsmapforecast/LPO_COSMO/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005/run"
SETUP_DIR="${BASE_CTRLDIR}/submit_TSMP_hist_rcp_continuous_years_months_sinks/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005/one_month_run"
#SETUP_DIR="/p/scratch/cjibg35/tsmpforecast/LPO_COSMO/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005/src/terrsysmp_current_pfl_sink/bldsva/submit_TSMP_hist_rcp_continuous_years_months_sinks/HiCam-CORDEX_EUR-11_MPI-ESM-LR_historical_r1i1p1_FZJ-IBG3-TSMP120EC_v00aJuwelsCpuProdTt-1949_2005/one_month_run" #is not used in "one-month run"

#---------------insert here initial, start and final dates of TSMP simulations----------
initDate="1980-01-01 00" #start of the whole TSMP simulation
cur_year=1980


#--------------- Adds a backslash in front of each slash, to make sed work--------------
WORK_FOLDER="sim_output_heter_geology_improved_with_pfl_sink"
#WORK_FOLDER="sim_output_heter_geology_improved_with_pfl_sink"
template_FOLDER="template_experiment_TSMP_climate_mode_heter_geology_improved_with_pfl_sink_14102020"
#template_FOLDER="template_experiment_TSMP_climate_mode_heter_geology_improved_with_pfl_sink"

WORK_DIR_REPLACE=$(echo $WORK_DIR | sed 's/\//\\\//g')
SETUP_DIR_REPLACE=$(echo $SETUP_DIR | sed 's/\//\\\//g')

#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------
# remember, there are LEAP YEARS: 1948, 1952, 1956, 1960, 1964, 1968, 1972,1976, 1980,1984,1988,1992,1996,2000,2004,2008,2012,2016,2020... 
#---------------------------------------------calculation of the numbers of leap year from the init date to the current date (is needed in tsmp...sh for the calculations of the run-hours; reason: CLM cannot be adjusted to 365-366 days callendar, and bash operationscan be made only in the "proper" calendar -> numLeapDays are needed to calcualte COSMO run-hours correctly (L.Poshyvailo, 2020)
    init_year=`echo $initDate | cut -c1-4`
    init_year_res=$((init_year%4))
    if [ "${init_year_res}" -eq 0 ]; then #if it is equal to 0 then the year is a leap year
	leapyear_marker_init='yes' && M_init=1 #M=1 -- leap year, M=0 -- not leap year
	echo "Init year is a leap year"
	init_month=`echo $initDate | cut -c6-7`
        if [ "${init_month}" -gt 2 ];]; then
	    first_leap_year=$((init_year+4))
	else
	    first_leap_year=${init_year}
	fi
    else
	init_year_res_new=$((4-init_year_res))
	first_leap_year=$((init_year+init_year_res_new))
	echo ${first_leap_year}
    fi

    diff_year=$((cur_year-first_leap_year))

    if [ ${diff_year} -ge 0 ]; then
	diff_year_res=$((diff_year%4))
        if [ ${diff_year_res} -ne 0 ]; then
	    full_diff=$((diff_year/4+1))
	else
            full_diff=$((diff_year/4)) #if diff_year_res=0
	fi
    else
	full_diff=0 #case, when the year is a leap year, but the init_month is after Feb, what means, that there will be no effect of the leap year
    fi

    numLeapDays=${full_diff}
    echo ${numLeapDays}

    #---------------------------------------------
    for mon in {1..1..1} # {1..12..1}; #in 12; in{1..12..1}; # CHANGE LINE below -> dependent jobs  {1..12..1}
    do
	if [ `echo $mon | wc -m` -eq 2 ]; then 
	    cur_month=0${mon}; 
	else 
	    cur_month=${mon}; 
	fi; #---------------------------------------------
	if [ "$mon" -eq 1 ]; then
	    pmon=12; 
	    prev_year=$((cur_year -1 ))
  	else
	    pmon=$((mon-1)); 
	    prev_year=${cur_year}
	fi  #---------------------------------------------		
	if [ `echo $pmon | wc -m` -eq 2 ]; then 
	    prev_month=0${pmon}; 
	else 
	    prev_month=${pmon}; 
	fi; #---------------------------------------------

        cur_year_res=$((cur_year%4))

        if [ "${cur_year_res}" -eq 0 ]; then #if it is equal to 0 then the year is a leap year
	    leapyear_marker_cur='yes' && M_cur=1 #M=1 -- leap year, M=0 -- not leap year
	    echo "Current year is a leap year"
	    if [ "${mon}" -eq 1 ]; then
		numHours=744 && numLeapDays_print=${numLeapDays};
	    elif [ "${mon}" -eq 2 ]; then
		numHours=672 && numLeapDays_print=${numLeapDays}; #numHours=696, if the calendar in TSMP is set to GREGORIAN (365+366 days); currently it is set to 365 days each year, due to CLM issue with the Gregorian calendar
	    elif [ "${mon}" -eq 3 ] || [ "${mon}" -eq 5 ] || [ "${mon}" -eq 7 ] || [ "${mon}" -eq 8 ] || [ "${mon}" -eq 10 ] || [ "${mon}" -eq 12 ]; then
		numHours=744 && numLeapDays_print=$((numLeapDays+1));
	    else
		numHours=720 && numLeapDays_print=$((numLeapDays+1));
	    fi
        elif [ "${cur_year_res}" -ne 0 ]; then #if it is equal to 0 then the year is a leap year
	    leapyear_marker_cur='no' && M_cur=0 && numLeapDays_print=${numLeapDays}; #M=1 -- leap year, M=0 -- not leap year
	    echo "Current year is NOT a leap year"
	    if [ "${mon}" -eq 2 ]; then
		numHours=672;
	    elif [ "${mon}" -eq 1 ] || [ "${mon}" -eq 3 ] || [ "${mon}" -eq 5 ] || [ "${mon}" -eq 7 ] || [ "${mon}" -eq 8 ] || [ "${mon}" -eq 10 ] || [ "${mon}" -eq 12 ]; then
		numHours=744;
	    else  numHours=720;
	    fi
	fi

        echo ${numLeapDays_print}

	expID=TSMP_3.1.0MCT_cordex11_${cur_year}_${cur_month};
	cp -r ${WORK_DIR}/${WORK_FOLDER}/${template_FOLDER} ${WORK_DIR}/${WORK_FOLDER}/${expID}
	wait
	cd ${WORK_DIR}/${WORK_FOLDER}/${expID}
	mkdir ${WORK_DIR}/${WORK_FOLDER}/${expID}/cosmo_out
        submission_file="tsmp_slm_run.bsh"
	sed -i "s/__expId__/${expID}/g" $submission_file
	sed -i "s/__job_name__/${cur_year}_${cur_month}/g" $submission_file
	startDate="${cur_year}-${cur_month}-01 00"
	sed -i "s/__startDate__/${startDate}/g" $submission_file
	sed -i "s/__initDate__/${initDate}/g" $submission_file
	sed -i "s/__cur_year__/${cur_year}/g" $submission_file
	sed -i "s/__cur_month__/${cur_month}/g" $submission_file
	sed -i "s/__prev_year__/${prev_year}/g" $submission_file
	sed -i "s/__prev_month__/${prev_month}/g" $submission_file
	sed -i "s/__numHours__/${numHours}/g" $submission_file
	sed -i "s/__numLeapDays__/${numLeapDays_print}/g" $submission_file  
        sed -i "s/__setup_dir__/${SETUP_DIR_REPLACE}/g" $submission_file
        sed -i "s/__work_dir__/${WORK_DIR_REPLACE}/g" $submission_file
        sed -i "s/__work_folder__/${WORK_FOLDER}/g" $submission_file

	if [ "$mon" -gt 4 ]; then   #change it for the dependent jobs! for {1..12..1}, -gt 1
		echo "Submitting a dependent job"
		jID2=$(sbatch --parsable --dependency=afterok:${jID} tsmp_slm_run.bsh)
		jID=$jID2
		wait
	else
		echo "Submitting an initial job"
		jID=$(sbatch --parsable tsmp_slm_run.bsh)
		wait
	fi
	cd ${SETUP_DIR}
done
