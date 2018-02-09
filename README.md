# recursive_gmconvert

Implements divide-and-conquer gmm computation as in [1].

## dependencies

EMAN2 (blake.bcm.edu/emanwiki/EMAN2), used to compute the FSC.

## instalation

1. clone the repository or download the zip and extract it (we refer to the root of the source tree as `SRC_DIR`).
2. compile gmconvert: `cd ${SRC_DIR}/gmconvert/src ; make ; cd -`
3. if you need to run some commands before executing the scripts, place them in modules.sh

## usage:
```
${SRC_DIR}/recursive_gmconvert.sh MAP_NAME THRESHOLD n N i0 SERIAL
```

`MAP_NAME`: the file name of the input EM map

`THRESHOLD`: the density threshold

`n`: number of gaussians per sub-process. 2 or 4 is a good guess.

`N`: number recursion levels.

`i0`: initial recursion level (default: 1)

`SERIAL`: if set to 1, uses the serial implementation (default: 0)

The script creates a sub-directory (called `i`) for each recursion level `i`, and the output files are called `i/i.gmm` and `i_imp.gmm`.
`i/i.gmm` contains the gmm in `gmconvert` format, and `i_imp.gmm` contains the gmm in `IMP` format (the conversion is handeld by `gmconvert2imp.sh`), which can be read in IMP using `IMP.isd.gmm_tools.decorate_gmm_from_text` function.

Unless you set SERIAL to 1, all the scripts assume that you are running a cluster with the `slurm` queuing system.

## References

[1] Bayesian multi-scale modeling of macromolecular structures based on cryo-electron microscopy density maps

Samuel Hanot, Massimiliano Bonomi, Charles H Greenberg, Andrej Sali, Michael Nilges, Michele Vendruscolo, Riccardo Pellarin

doi: https://doi.org/10.1101/113951
