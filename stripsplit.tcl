# stripsplit.tcl (c) 2019 cameron f abrams cfa22@drexel.edu
#
# This VMD script takes as input the full simulation PSF/PDB/COOR input
# files and all output stage-specific DCD's to generate (for one replica designated
# by the caller) stage-specific PSF/PDB/DCD's of ligand, target, and complex.  The
# DCD's are stitched together by the master bash script and a separate set
# of routines use these for MMGBSA interaction energy calculation.
#
package require pbctools
# define the target segids and the ligand segid
set targ_seg G
set lig_seg X
set rep -1
set stride 1
set MKPSF 0
set nstages 10
set PSF md.psf
set PDB md.pdb
set COOR md.coor
set dcdfmt "prod-s%i-rep%i.dcd"
# get the replica number and stride from the command-line
for { set i 0 } { $i < [llength $argv] } { incr i } {
    if { [lindex $argv $i] == "--dcdfmt" } {
       incr i
       set dcdfmt [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--rep" } {
       incr i
       set rep [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--stride" } {
       incr i
       set stride [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--ligseg" } {
       incr i
       set lig_seg [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--targseg" } {
       incr i
       set targ_seg [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--mkpsf" } {
       set MKPSF 1
    }
    if { [lindex $argv $i] == "--nstages" } {
       incr i
       set nstages [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--psf" } {
       incr i
       set PSF [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--pdb" } {
       incr i
       set PDB [lindex $argv $i]
    }
    if { [lindex $argv $i] == "--coor" } {
       incr i
       set COOR [lindex $argv $i]
    }
}
if { ! [file exists $PSF] } {
   puts "Error: $PSF not found."
   exit
}
if { ! [file exists $PDB] } {
   puts "Error: $PDB not found."
   exit
}
if { "$rep" == "-1" } {
   puts "Must specify replica number with --rep #"
   exit
}

if { "$MKPSF" == "1" } {
  package require psfgen
  # load the overall simulation PSF file into psfgen
  readpsf $PSF
  # a function for removing items from a list
  proc lremove {listVariable value} {
      upvar 1 $listVariable var
      set idx [lsearch -exact $var $value]
      set var [lreplace $var $idx $idx]
  }
  # load the base molecule topology and coordinates
  mol load psf $PSF pdb $PDB
  # determine list of unique segids 
  set segids [lsort -unique [[atomselect top all] get segid]]
  mol delete top

  # remove the ligand segid from the list of unique segids
  lremove segids $lig_seg
  # remove the target segids from the list of unique segids
  foreach t $targ_seg {
     lremove segids $t
  }

  # delete all atoms in segids NOT in the ligand or target
  foreach s $segids {
     delatom $s
  }
  # what remains is the PSF of the complex; write it
  writepsf "complex.psf"

  # delete the ligand segid; what remains is the PSF of the target; write it
  delatom $lig_seg
  writepsf "target.psf"
  resetpsf

  # read back in the complex psf; delete target segids; what remains is the ligand PSF; write it
  readpsf "complex.psf"
  foreach t $targ_seg {
     delatom $t
  }
  writepsf "ligand.psf"
  resetpsf
}

# generate PDB files for each type of system from the
# input coordinates in sol.coor
mol new $PSF
mol addfile $COOR
# set the alignment reference from the initial coords and center it
set reference_id [molinfo top get id]
set aln_ref [atomselect $reference_id "segid $targ_seg"]
$aln_ref moveby [vecscale -1 [measure center $aln_ref]]
[atomselect top "segid $targ_seg"] writepdb "target.pdb"
[atomselect top "segid $lig_seg"] writepdb "ligand.pdb"
[atomselect top "segid $targ_seg $lig_seg"] writepdb "complex.pdb"

mol new $PSF
set working_id [molinfo top get id]
for { set st 1 } { $st <= $nstages } { incr st } {
   set dcd [format $dcdfmt ${st} ${rep}] ;#prod-s${st}-rep${rep}.dcd
   if { [file exists $dcd] } {
      animate read dcd $dcd skip $stride waitfor all
   } else {
      puts "Error: $dcd not found."
      exit
   }
}
pbc unwrap -all -sel "segid $targ_seg $lig_seg"
set aln_work [atomselect $working_id "segid $targ_seg"]
set aln_do [atomselect $working_id "segid $targ_seg $lig_seg"]
for { set i 0 } { $i < [molinfo top get numframes]} { incr i } {
    $aln_work frame $i
    $aln_do frame $i
    $aln_do move [measure fit $aln_work $aln_ref]
}
animate write dcd "complex-rep${rep}-formmgbsa.dcd" waitfor all sel $aln_do $working_id
set res_targ [atomselect $working_id "segid $targ_seg"]
animate write dcd "target-rep${rep}-formmgbsa.dcd" waitfor all sel $res_targ $working_id
set res_lig [atomselect $working_id "segid $lig_seg"]
animate write dcd "ligand-rep${rep}-formmgbsa.dcd" waitfor all sel $res_lig $working_id
animate delete beg 0 end [expr [molinfo $working_id get numframes]-1] $working_id
exit

