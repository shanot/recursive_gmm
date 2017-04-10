#!/bin/bash

for EMDB in [0-9]*
do
	for f in ${EMDB}/[0-9]*
	do
		srun ~/gmconvert_MAX_SAM/gmconvert -igmm $f/$(basename $f).txt -imap ${EMDB}/emd_${EMDB}.map -zth $(cat ${EMDB}/cutoff.txt) |tee $f/gmmscore_threshold &
	done
done
