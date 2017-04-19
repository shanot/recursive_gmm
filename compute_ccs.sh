#!/bin/bash

while read f
do
	mrc="$f/$(basename $f).mrc"
	gmm="$f/$(basename $f).gmm"
	output="$f/gmmscore_threshold"
	if [[ ! -f $output ]] || [[ $gmm -nt $output ]]
	then
		srun ~/gmconvert_MAX_SAM/gmconvert -igmm $gmm -imap $f/../threshold.map -omap $mrc -zth $(cat $f/../cutoff.txt) |tee $output &
	else
		echo "skipping $f"
	fi
done < <(find . -type d -regextype posix-awk -regex "./[0-9]+/[0-9]+")
