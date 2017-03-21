# recursive_gmm

Implements recursive gmm computation as in [1].

usage:
```
main_gmconvert.sh MAP_NAME THRESHOLD n N
```
`n` is the number of gaussians per sub-process. 4 is a good guess.

`N` is how many recursion levels will be performed. The result is gmms of size `n^i` with `1<=i<=N`.

The script creates a sub-directory (called `n^i`) for each recursion level, and the output files are called `n^i.txt` and `n^i_imp.txt`.
`n^i` contains the gmm in `gmconvert` format, and `n^i_imp.txt` contains the gmm in `IMP` format (the conversion is handeld by `gmconvert2imp.sh`.

These scripts assume that `IMP` is installed in `~/imp-fast` and that the `gmconvert` software is installed in `gmconvert_MAX_SAM`.

These scripts also assume that you are running a cluster with the `slurm` queuing system. 


## References

[1] Multi-scale Bayesian modeling of cryo-electron microscopy density maps

Samuel Hanot, Massimiliano Bonomi, Charles H Greenberg, Andrej Sali, Michael Nilges, Michele Vendruscolo, Riccardo Pellarin

bioRxiv 113951; doi: [https://doi.org/10.1101/113951](https://doi.org/10.1101/113951)
