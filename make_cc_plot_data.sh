#!/bin/bash
for d in $(cut -d ' ' -f 1 $1)
do
	if [[ -d $d ]]
	then
		r=$(cat $d/resolution.txt)
		molWt=$(grep molWtTheo $d/header/*xml | head -n 1 | cut -d '>' -f2 | cut -d '<' -f 1)
		echo 0 \"${r}A \#${d}\"
		for f in $(ls -v $d/[0-9]*/gmmscore_threshold)
		do
			if (( $(grep -c '^CC' $f)>0 ))  
			then
				echo $(awk -v molWt=${molWt} '/^#Ngauss /{N=$2} /^CC /{print N/molWt,$2} ' $f)
				#echo $(awk '/^#Ngauss /{N=$2} /^CC /{print N,$2} ' $f)
			fi
		done
		echo -e '\n\n'
	fi
done
