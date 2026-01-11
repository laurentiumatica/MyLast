#!/bin/bash

../mylast.sh
../mylastb.sh
../mylast.sh -n 3
../mylastb.sh -n 4
../mylast.sh -t "2026-01-10 13:00" -s "2026-01-10 10:00" 
../mylastb.sh -s "2026-01-10 10:00" -t "2026-01-10 13:00"
../mylast.sh -s "2026-01-10 10:00" -t "2026-01-10 13:00" -n 3
../mylastb.sh -s "2026-01-10 10:00" -n 4 -t "2026-01-10 13:00"
../mylast.sh -p "2026-01-10 10:00"
../mylastb.sh -p "2026-01-10 13:00"
../mylast.sh auth.log.sample
../mylastb.sh auth.log.sample
../mylast.sh -n 4 auth.log.sample
../mylastb.sh -n 2 auth.log.sample
../mylast.sh -s "2026-01-04 15:00" auth.log.sample
../mylast.sh -t "2026-01-04 18:00" auth.log.sample
../mylastb.sh -s "2026-01-03 00:00" -t "2026-01-05 00:00" auth.log.sample
../mylast.sh -s "2026-01-04 10:00" -t "2026-01-04 20:00" auth.log.sample
../mylast.sh -p "2026-01-04 16:00" auth.log.sample
../mylastb.sh -p "2026-01-04 20:00" auth.log.sample
../mylast.sh -n 2 -s "2026-01-04 12:00" auth.log.sample
../mylast.sh -t "2026-01-05 10:00" -n 3 auth.log.sample
../mylast.sh -s "2026-01-02 00:00" -t "2026-01-03 00:00" auth.log.sample
../mylast.sh -p "2026-01-04 10:30" auth.log.sample
../mylastb.sh -s "2026-01-04 19:00" auth.log.sample
../mylast.sh -s "2026-01-05 00:00" auth.log.sample
../mylast.sh -n 5 -t "2026-01-04 22:00" auth.log.sample
../mylastb.sh -p "2026-01-03 08:30" auth.log.sample
../mylast.sh auth.log.1.gz
../mylastb.sh auth.log.1.gz
../mylast.sh -n 3 auth.log.1.gz
../mylastb.sh -n 2 auth.log.1.gz
../mylast.sh -s "2026-01-09 10:00" auth.log.1.gz
../mylast.sh -t "2026-01-09 15:00" auth.log.1.gz
../mylastb.sh -s "2026-01-09 11:00" -t "2026-01-09 18:00" auth.log.1.gz
../mylast.sh -s "2026-01-09 08:00" -t "2026-01-09 12:00" auth.log.1.gz
../mylast.sh -p "2026-01-09 11:00" auth.log.1.gz
../mylastb.sh -p "2026-01-09 11:00" auth.log.1.gz
../mylast.sh -n 4 -s "2026-01-09 09:00" auth.log.1.gz
../mylast.sh -t "2026-01-09 16:00" -n 2 auth.log.1.gz
../mylast.sh -s "2026-01-09 14:00" auth.log.1.gz
../mylast.sh -p "2026-01-09 09:45" auth.log.1.gz
../mylastb.sh -t "2026-01-09 12:00" auth.log.1.gz
../mylast.sh -n 2 -s "2026-01-09 15:00" auth.log.1.gz
../mylast.sh -s "2026-01-02 09:00" -t "2026-01-05 00:00" auth.log.sample
../mylast.sh -p "2026-01-03 12:00" auth.log.sample
../mylast.sh -s "2026-01-04 09:00" -t "2026-01-04 19:00" auth.log.sample
../mylast.sh -n 10 auth.log.sample
../mylast.sh -s "2026-01-05 14:00" auth.log.sample
../mylast.sh -p "2026-01-05 16:30" auth.log.sample
../mylast.sh -n 3 -s "2026-01-05 15:00" auth.log.sample
../mylast.sh -s "2026-01-04 14:30" -t "2026-01-04 17:00" auth.log.sample
../mylast.sh -p "2026-01-04 15:30" auth.log.sample
../mylast.sh -s "2026-01-04 15:00" -t "2026-01-04 16:45" auth.log.sample
../mylastb.sh -s "2026-01-03 07:00" -t "2026-01-03 10:00" auth.log.sample
../mylastb.sh -p "2026-01-03 08:30" auth.log.sample
../mylastb.sh -n 1 -s "2026-01-04 19:30" auth.log.sample
../mylast.sh -s "2026-01-04 21:00" -t "2026-01-04 22:30" auth.log.sample
../mylast.sh -p "2026-01-04 21:45" auth.log.sample
../mylast.sh -s "2026-01-09 14:00" auth.log.1.gz
../mylast.sh -p "2026-01-09 16:30" auth.log.1.gz
../mylast.sh -n 2 -s "2026-01-09 15:00" auth.log.1.gz
../mylast.sh -s "2026-01-09 07:00" -t "2026-01-09 17:00" auth.log.1.gz
../mylast.sh -n 6 auth.log.1.gz
../mylast.sh -s "2026-01-09 09:00" -t "2026-01-09 19:00" auth.log.1.gz
../mylast.sh -p "2026-01-09 14:00" auth.log.1.gz
../mylastb.sh -s "2026-01-09 10:30" -t "2026-01-09 18:00" auth.log.1.gz
../mylast.sh -n 5 auth.log.1.gz
../mylast.sh -s "2026-01-09 09:30" -t "2026-01-09 09:31" auth.log.1.gz
../mylast.sh -s "2026-01-09 15:00" -t "2026-01-09 15:01" auth.log.1.gz
../mylast.sh -s "invalid-date" auth.log.sample
../mylastb.sh -t "not-a-date" auth.log.sample
../mylast.sh -p "2026-13-45" auth.log.sample
../mylast.sh -s "abcd1234" -t "2026-01-05 10:00" auth.log.sample
../mylast.sh -n 0 auth.log.sample
../mylast.sh -n -5 auth.log.sample
../mylast.sh -n abc auth.log.sample
../mylastb.sh -n 3.14 auth.log.sample
../mylast.sh fisier_inexistent.log
../mylastb.sh /path/invalid/auth.log
../mylast.sh -n 3 missing_file.log
../mylast.sh -s "2026-01-06 00:00" -t "2026-01-07 00:00" auth.log.sample
../mylast.sh -s "2026-01-10 00:00" auth.log.sample
../mylastb.sh -s "2026-01-06 00:00" -t "2026-01-08 00:00" auth.log.sample
../mylast.sh -p "2026-01-01 10:00" auth.log.sample
../mylast.sh -p "2026-01-04 13:00" auth.log.sample
../mylastb.sh -p "2026-01-02 15:00" auth.log.sample
../mylast.sh -s "2026-01-04 13:00" -t "2026-01-04 13:01" auth.log.sample
../mylast.sh -s "2026-01-05 13:00" -t "2026-01-05 13:30" auth.log.sample
../mylast.sh -s "2026-01-10 00:00" auth.log.1.gz
../mylast.sh -p "2026-01-08 10:00" auth.log.1.gz
../mylastb.sh -s "2026-01-09 06:00" -t "2026-01-09 07:00" auth.log.1.gz
../mylast.sh auth.log.empty
../mylastb.sh auth.log.empty
../mylast.sh -n 5 auth.log.empty
../mylastb.sh -n 3 auth.log.empty
../mylast.sh -s "2026-01-01 00:00" auth.log.empty
../mylast.sh -t "2026-01-10 00:00" auth.log.empty
../mylast.sh -s "2026-01-01 00:00" -t "2026-01-10 00:00" auth.log.empty
../mylastb.sh -s "2026-01-05 00:00" -t "2026-01-08 00:00" auth.log.empty
../mylast.sh -p "2026-01-05 12:00" auth.log.empty
../mylastb.sh -p "2026-01-03 10:00" auth.log.empty
../mylast.sh -n 10 -s "2026-01-01 00:00" auth.log.empty
../mylastb.sh -t "2026-01-10 00:00" -n 5 auth.log.empty
