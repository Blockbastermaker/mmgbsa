#!/bin/bash
#
# MMGBSA_DOIT  (c) 2019 cameron f abrams cfa22@drexel.edu
#
# Use namd2 to peform MMBGSA interaction energy calculations
# on DCD trajectories extracted from raw simulation output DCD's
# using STRIPSPLIT.  This operates on a single replica in a single
# system.
#
# Specify location of namd2 and charmrun executables
NAMD2=/home/cfa/namd/NAMD_2.12_Source/Linux-x86_64-g++/namd2
CHARMRUN=/home/cfa/namd/NAMD_2.12_Source/Linux-x86_64-g++/charmrun
# name of template namd config file for doing MMBGSA
TEMPLATECF=mmgbsa_template.namd
FORCE=NO
DOCALC=YES
TAILFRAMES=1000
# command-line argument parsing
for i in "$@"
do
case $i in
    -r=*|--rep=*)
    REP="${i#*=}"
    shift
    ;;
     -tf=*|--tailframes=*)
    TAILFRAMES="${i#*=}"
    shift
    ;;
    -n=*|--namd2=*)
    NAMD2="${i#*=}"
    shift
    ;;
    -c=*|--charmrun=*)
    CHARMRUN="${i#*=}"
    shift
    ;;
    -t=*|--template=*)
    TEMPLATECF="${i#*=}"
    shift
    ;;
    -f|--force)
    FORCE=YES
    shift
    ;;
    *)
    echo "Unknown option: $i"
    exit -1
    ;;
esac
done

# check to see if calculation was already performed for this replica
final_results_file=m-rep${REP}.rae
if [ -f $final_results_file ]; then
    cp $final_results_file ${final_results_file}.bak
    echo "$final_results_file copied to ${final_results_file}.bak"
    if [ "$FORCE" == "NO" ]; then 
      echo "Final results $final_results_file already exists.  Use --force to force a recalculation."
      DOCALC=NO
    else
      echo "Recalculating."
    fi
fi

# generate the config file for each type of system, run namd2 to compute energies on existing trajectory, 
# extract potential energy from ENERGY lines in namd2 log
if [ "$DOCALC" == "YES" ]; then 
    for sys in ligand target complex; do
       pf=m-${sys}-rep${REP}
       c=${pf}.namd
       l=${pf}.log
       e=${pf}.e
       cat ../${TEMPLATECF} | sed s/%SYS%/${sys}/g | sed s/%REP%/${REP}/g > $c
       $CHARMRUN +p8 $NAMD2 $c > $l
       echo "Generated $l"
       if [ "$sys" == "ligand" ] ; then
          grep ^ENERGY $l | awk '{print $2,$14}' > $e
       else
          grep ^ENERGY $l | awk '{print $14}' > $e
       fi
    done
fi

# perform the running average of the difference (complex)-((ligand)+(target)) 
# potential energies
paste m-ligand-rep${REP}.e m-target-rep${REP}.e m-complex-rep${REP}.e | \
      tail -$TAILFRAMES | awk 'BEGIN{ra=0.0} {ra+=($4-$3-$2); print $1,ra/NR}' > $final_results_file
echo "Generated $final_results_file averaging over $TAILFRAMES finalmost frames."

