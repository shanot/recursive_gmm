#!/bin/bash

source ~/modules.sh
unset http_proxy

for f in $(cat)
do
	echo $f
	#curl ftp://ftp.ebi.ac.uk/pub/databases/emdb/structures/EMD-$f/map/emd_$f.map.gz | gunzip -c - > emd_$f.map
	#curl http://www.ebi.ac.uk/pdbe/entry/emdb/EMD-$f/analysis > tmp.html
	#links tmp.html > map_analysis.txt
	#curl "http://www.ebi.ac.uk/pdbe/emdb-entry/EMD-$f/analysis#va_map" > tmp.html
	#curl "http://www.ebi.ac.uk/pdbe/emdb-entry/EMD-$f/analysis#va_map"
	#links tmp.html >> map_analysis.txt
	#cutoff=$(awk '/contour/{print $4}' < map_analysis.txt)
	#resolution=$(awk '/Resolution: /{print $2}' < map_analysis.txt)
	rsync -a -v -z --delete rsync.ebi.ac.uk::pub/databases/emdb/structures/EMD-${f}/ $f
	cd $f
	links http://www.ebi.ac.uk/pdbe/entry/emdb/EMD-$f/analysis > header/map_analysis.txt
	cutoff=$(awk '/contour/{print $4}' < header/map_analysis.txt)
	resolution=$(sed -ne 's/[<>/ ]//g' -ne 's/resolutionByAuthor//gp' header/emd-${f}.xml)
	echo ${cutoff} > cutoff.txt
	echo ${resolution} > resolution.txt
	gunzip -c map/emd_${f}.map.gz > emd_${f}.map
	#cutoff=0.0
	~/recursive_gmm/main_gmconvert.sh emd_${f}.map $cutoff $1 $2
	cd -
done
