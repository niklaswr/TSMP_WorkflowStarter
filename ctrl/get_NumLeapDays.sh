#!/bin/bash
#
# author: Niklas WAGNER, Liuba POSHYVAILO
# e-mail: n.wagner@fz-juelich.de, l.poshyvailo@fz-juelich.de
# version: 2020-12-11
# USAGE:
# >> get_numLeapDays "$initDate" "$currDate"
# >> numLeapDays=$?

isleap() { date -d $1-02-29 &>/dev/null && echo "yes" || echo "no"; }

get_numLeapDays() {
  #----------------------------------------------------------------------------
  # CALCULATING NUMBERS of LEAP DAYS between initDate and currDate
  # Based on the date format: YYYY-mm-dd HH
  # NUMBER of LEAP DAYS are needed for TSMP because different component models
  # are using different calender types (with and wthout leap years)
  #----------------------------------------------------------------------------

  initDate=$1
  currDate=$2

  echo "initDate: ${initDate}"
  echo "currDate: ${currDate}"
  # get the year of the init current date
  initYear=$(date '+%Y' -d "$initDate")
  currYear=$(date '+%Y' -d "$currDate")

  # date operators in bash are based on the representation of a date in 
  # "seconds since"
  # resulting integer variables can be added /substracted etc.
  initDate_sec=$(date '+%s' -d "${initDate}")
  initYear_sec=$(date '+%s' -d "${initYear}-01-01 00")
  currDate_sec=$(date '+%s' -d "${currDate}")
  currYear_sec=$(date '+%s' -d "${currYear}-01-01 00")
  diff_day=$(( (currDate_sec - initYear_sec) / (60*60*24) ))
  echo "days between initYear and currDate: ${diff_day} (diff_day)"
  day_currYear=$(( (currDate_sec - currYear_sec) / (60*60*24) ))
  echo "days of current year: ${day_currYear} (day_currYear)"

  # modulo of the difference between initYear and currDate (in days) with 365
  # results in the days of the current year PLUS all leap-days
  # NOTE if intDate is leap-year but started after 29. Feb, this day is
  # included and need to be substracted 
  mod_diff_day=$(( diff_day%365 ))
  echo "diff_day % 365: ${mod_diff_day} (mod_diff_day)"

  # Substracting the days of the current year results in the number of 
  # leap-days, but only those of past years (plus maybe wrong one)...
  numLeapDays=$((mod_diff_day - day_currYear))
  echo "mod_diff_day - day_currYear : ${numLeapDays} (numLeapDays)"

  # ...if the current year is a leap year and and the current date is after 
  # 29. Feb, than the number of the leap-days need to be corrected by 1 
  # (the current leap-day)
  tmp_correct=0
  curr_leap=$(isleap ${currYear})
  init_leap=$(isleap ${initYear})
  if [[ ${curr_leap} -eq "yes" && $(date '+%Y%m%d' -d "$currDate") -ge $(date '+%Y%m%d' -d "${currYear}-03-01 00") ]]; then
    tmp_correct=$((tmp_correct + 1))
  fi
  if [[ ${init_leap} -eq "yes" && $(date '+%Y%m%d' -d "$initDate") -ge $(date '+%Y%m%d' -d "${initYear}-03-01 00") ]]; then
    tmp_correct=$((tmp_correct - 1))
  else
    tmp_correct=$((tmp_correct + 0))
  fi
  numLeapDays_printed=$((numLeapDays + tmp_correct))
  echo "numLeapDays_printed: ${numLeapDays_printed}"
  return $numLeapDays_printed
}

#initDate="1980-02-01 00"
#currDate="1980-03-01 00"
#
##echo "numLeapDaysprinted: ${numLeapDays_FUNK}"

