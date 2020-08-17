# mmgbsa
MMGB/SA calculations on NAMD-generated trajectories

Cameron F. Abrams  cfa22@drexel.edu

### How does this work?

1. Use NAMD2 to generate MD trajectories of fully solvated ligand/protein complex systems.  This implementation expects there to be separate directories for each system, under which are files for several replica simulations.

2. Use `stripsplit` to generate solvent-free trajectories of ligand-only, protein-only, and protein-ligand complex, along with PSF/PDB pairs for each.

3. Use `mmgbsa` to run NAMD2 over each to compute energies.
