#!/bin/bash


bindir=$(dirname $0)

source ${bindir}/modules.sh

for f in $(cat)
do
	echo $f
	rsync -a -v -z --delete rsync.ebi.ac.uk::pub/databases/emdb/structures/EMD-${f}/ $f
	cd $f
	links http://www.ebi.ac.uk/pdbe/entry/emdb/EMD-$f/analysis > header/map_analysis.txt
	cutoff=$(awk '/contour/{print $4}' < header/map_analysis.txt)
	resolution=$(sed -ne 's/[<>/ ]//g' -ne 's/resolutionByAuthor//gp' header/emd-${f}.xml)
	echo ${cutoff} > cutoff.txt
	echo ${resolution} > resolution.txt
	gunzip -c map/emd_${f}.map.gz > emd_${f}.map
	${bindir}/recursive_gmconvert.sh emd_${f}.map $cutoff $1 $2
	cd -
done
