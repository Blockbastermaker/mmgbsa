#!/bin/bash
DIRS=`cat d`
#DIRS=( 4h8w_LM 4h8w_LM+H375S LM_H375T )
#DIRS=( LM_H375T )
for d in ${DIRS[*]}; do
   cd $d
   for rep in `seq 1 5`; do
       echo "$d $rep"
       ../mmgbsa_doit.sh -r=$rep -tf=15000 --force
   done
   cd ..
done
