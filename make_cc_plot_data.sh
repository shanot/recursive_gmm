#!/bin/bash
for f in */*/gmmscore_threshold
do
	
	if (( $(grep -c '^CC' $f)>0 ))  
	then
		echo $(dirname $f) $(grep '^CC' $f) $(cat $(dirname $f)/../resolution.txt)
	fi
done | tee tmp.txt | tr '/' ' ' | sort -g -s -k 2 | sort -g -s -k 5 | awk -v a='' -F '[/ ]' '$1!=old{print a} {printf "%s %s %s \"%sÅ (EMDB #%s)\"\n", $1,$2,$4,$5,$1; old=$1}' | tee data.dat
