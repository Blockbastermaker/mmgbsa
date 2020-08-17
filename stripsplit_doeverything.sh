#!/bin/bash
#
# This master bash script runs stripsplit_doit.sh in each
# system directory listed in file 'd'.
#
# (c) 2019,2020 cameron f abrams cfa22@drexel.edu
#

dirfile=d

NREP=5

while [ "$#" -gt 0 ]; do
  case "$1" in
    -nr) NREP="$2"; shift 2;;
    -d) dirfile="$2"; shift 2;;
    *) echo "unrecognized argument: $1"
  esac
done

DIRS=`cat $dirfile`
# cd into each directory listed in the dirfile, and in each
# run stripsplit on all replicas from 1 to NREP
for d in ${DIRS[*]}; do
   cd $d
   echo "$d"
   for rep in `seq 1 $NREP`; do
      ../stripsplit_doit.sh -r $rep
   done
   cd ..
done
