#!/bin/bash
#
# STRIPSPLIT (c) 2019 cameron f abrams
#
# This script manages execution of the stripsplit.tcl vmd script
# inside of a system directory containing raw simulation trajectories
# (dcd) of nrep replicas split over nstag contiguous stages each.
#
# stripsplit.tcl generates centered, solvent-free dcd trajectories
# containing protein ("target") only, ligand only, and complex.

SCRIPT=stripsplit.tcl
stride=1 # pruned all dcds on 7/31/19
MKPSF=0
rep=-1
nstag=20

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r) rep="$2"; shift 2;;
    -s) SCRIPT="$2"; shift 2;;

    --rep=*) rep="${1#*=}"; shift 1;;
    --script=*) SCRIPT="${1#*=}"; shift 1;;
    *) echo "unrecognized argument: $1"
  esac
done

if [ ! -f complex.psf ]; then
   MKPSF=1
fi
echo "Strip-splitting replica $rep"
if [[ "$rep" == "1" ]] && [[ "$MKPSF" == "1" ]]; then
   vmd -dispdev text -e ../$SCRIPT -args --mkpsf --rep $rep --stride $stride --nstages $nstag --psf my_4h8w_i.psf --pdb my_4h8w_i.pdb --coor sol.coor &> stripsplit-rep${rep}.log
else
   vmd -dispdev text -e ../$SCRIPT -args --rep $rep --stride $stride --nstages $nstag --psf my_4h8w_i.psf --pdb my_4h8w_i.pdb --coor sol.coor &> stripsplit-rep${rep}.log
fi

