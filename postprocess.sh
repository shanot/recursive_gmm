#!/bin/bash

source ~/modules.sh

if [[ ! -f ${n}/${n}.gmm ]]
then
	cat ${n}/${n}*.gmm > ${n}/${n}.gmm
fi
${bindir}/gmconvert2imp.sh  ${n}/${n}.gmm >  ${n}/${n}_imp.gmm

~/gmconvert_MAX_SAM/gmconvert -igmm ${n}/${n}.gmm -imap threshold.map -omap ${n}/${n}.mrc -zth $(cat cutoff.txt) |tee gmmscore_threshold

e2proc3d.py ${map_name} ${n}/${n}_imp.gmm.mrc.fsc --calcfsc ${n}/${n}_imp.gmm.mrc
awk '$2<=0.143 && y>0.143{print 1.0/(x+(0.143-y)*($1-x)/($2-y))} {x=$1;y=$2}' <  ${n}/${n}_imp.gmm.mrc.fsc > ${n}/${n}_imp.gmm.resolution

