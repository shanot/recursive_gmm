#!/bin/bash

source ~/modules.sh

bindir=$(dirname $0)

for f in ${n}/slurm*out
do
	gmmfile=$(awk '/IGAUSSFILE/{print $2}' $f)
	gmmCC=$(awk '/^CC /{if($2>0.97){print 1}else{print 0}}' $f)
	if (( $gmmCC ))
	then
		mv $gmmfile converged/
	else
		echo $gmmfile
	fi
done > ${n}/not_converged.txt

if [[ ! -e ${n}/${n}.gmm ]]
then
	cat ${n}/${n}_*.gmm > ${n}/${n}.gmm
	cat converged/*.gmm >> ${n}/${n}.gmm
	${bindir}/gmconvert2imp.sh ${n}/${n}.gmm > ${n}_imp.gmm
fi

${bindir}/gmconvert/gmconvert -igmm ${n}/${n}.gmm -imap threshold.map -omap ${n}/${n}.gmm.mrc |tee ${n}/gmmscore_threshold

e2proc3d.py ${map_name} ${n}/${n}.gmm.mrc.fsc --calcfsc ${n}/${n}.gmm.mrc
e2proc3d.py threshold.map ${n}/${n}.gmm.mrc.threshold.fsc --calcfsc ${n}/${n}.gmm.mrc
e2proc3d.py ${n}/${n}.gmm.mrc tmp.map --calcsf ${n}/${n}.gmm.mrc.sf
awk '$2<=0.143 && y>0.143{print 1.0/(x+(0.143-y)*($1-x)/($2-y))} {x=$1;y=$2}' <  ${n}/${n}.gmm.mrc.fsc > ${n}/${n}.gmm.resolution
awk '$2<=0.143 && y>0.143{print 1.0/(x+(0.143-y)*($1-x)/($2-y))} {x=$1;y=$2}' <  ${n}/${n}.gmm.mrc.threshold.fsc > ${n}/${n}.gmm.threshold.resolution

#rm -f $n/sub*
#rm -rf {.,$n}/tmp*
