#!/bin/bash
#
# This master bash script runs stripsplit_doit.sh in each
# system directory listed in file 'd'.
#
# (c) 2019 cameron f abrams cfa22@drexel.edu
#
DIRS=`cat d`
NREP=5
for d in ${DIRS[*]}; do
   cd $d
   echo "$d"
   for rep in `seq 1 $NREP`; do
      ../stripsplit_doit.sh -r $rep
   done
   cd ..
done
