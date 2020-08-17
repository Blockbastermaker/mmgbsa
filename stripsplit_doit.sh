#!/bin/bash
#
# STRIPSPLIT (c) 2019, 2020 cameron f abrams  cfa22@drexel.du
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

PSF=my_4h8w_i.psf
PDB=my_4h8w_i.pdb
COOR=sol.coor
DCDPAT='prod-s%i-rep%i.dcd'  # first integer is stage number, second is replica number

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r) rep="$2"; shift 2;;
    -s) SCRIPT="$2"; shift 2;;
    -pdb) PDB="$2"; shift 2;;
    -psf) PSF="$2"; shift 2;;
    -coor) COOR="$2"; shift 2;;
    -dcdpat) DCDPAT="$2"; shift 2;;

    --rep=*) rep="${1#*=}"; shift 1;;
    --script=*) SCRIPT="${1#*=}"; shift 1;;
    *) echo "unrecognized argument: $1"
  esac
done

# if no 'complex.psf' file exists, assume this is the first time stripsplit is being run in this directory
# so create the target.psf, ligand.psf, and complex.psf files
if [ ! -f complex.psf ]; then
   MKPSF=1
fi
echo "Strip-splitting replica $rep"
if [[ "$rep" == "1" ]] && [[ "$MKPSF" == "1" ]]; then
   vmd -dispdev text -e ../$SCRIPT -args --mkpsf --dcdfmt $DCDPAT --rep $rep --stride $stride --nstages $nstag --psf $PSF --pdb $PDB --coor $COOR &> stripsplit-rep${rep}.log
else
   vmd -dispdev text -e ../$SCRIPT -args --dcdfmt $DCDPAT --rep $rep --stride $stride --nstages $nstag --psf $PSF --pdb $PDB --coor $COOR &> stripsplit-rep${rep}.log
fi

