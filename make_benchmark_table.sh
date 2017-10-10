#!/bin/bash

while read -a l
do
	emd=${l[0]}
	
	w=$(grep molWtTheo ${emd}/header/emd-${emd}.xml | head -n1 | cut -d '>' -f 2 | cut -d '<' -f 1)

	res=$(grep resolutionByAuthor ${emd}/header/emd-${emd}.xml | head -n1 | cut -d '>' -f 2 | cut -d '<' -f 1)
	res_method=$(grep resolutionMethod ${emd}/header/emd-${emd}.xml | head -n1 | cut -d '>' -f 2 | cut -d '<' -f 1)


	#here we get the minimum in the plot of resolution vs #Gaussian
	gmm_data=$(awk -v r=${res} 'function abs(x){return x<0?-x:x} BEGIN{m=1000} abs($3-r)<m && abs(abs($3-r)-m)/r>0.1{m=abs($3-r); b=$0} END{print b}' < ${emd}/tmp.txt  | tr -d '"' | awk '{print $1,$2,$3}' | sed -e 's/  */ ; /g')

	iteration=$(cut -d ';' -f1 <<< ${gmm_data} | tr -d ' ')


	CC=$(awk '/^CC /{print $2}' ${emd}/${iteration}/gmmscore_threshold)

	echo "${emd} ; ${w} ; ${res} ; ${res_method} ; ${gmm_data} ; ${CC}"
done 
