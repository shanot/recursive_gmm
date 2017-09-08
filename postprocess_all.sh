#!/bin/zsh


profile_cmd="/usr/bin/time -v"



n_gaussians=$3
N=$4
MaxArraySize=10000

get_max_jobs(){
	echo ${MaxArraySize}
}

i0=1
if [ -n "$5" ]
then
	i0=$5
fi

echo $i0

bindir=${0:h}
impdir=~/imp-fast/
gmconvert=~/gmconvert_MAX_SAM/gmconvert

N=$(ls -d [0-9]*/[0-9]* |wc -l)

i=0
for f in $(ls -d [0-9]*/[0-9]* | tr '/' ' ' | sort -gk 2 | tr ' ' '/')
do
	i=$((i+1))
	echo ${i}/${N} $f
	root_dir=$(echo $f | cut -d '/' -f 1)
	n=$(echo $f | cut -d '/' -f 2)
	map_name=threshold.map

	cd $root_dir
	#!/bin/bash

	source ~/modules.sh

	#~/gmconvert_MAX_SAM/gmconvert -igmm ${n}/${n}.gmm -imap threshold.map -omap ${n}/${n}.gmm.mrc |tee ${n}/gmmscore_threshold

	e2proc3d.py ${map_name} ${n}/${n}.gmm.mrc.fsc --calcfsc ${n}/${n}.gmm.mrc
	e2proc3d.py ${n}/${n}.gmm.mrc tmp.map --calcsf ${n}/${n}.gmm.mrc.sf
	rm tmp.map
	awk '$2<=0.143 && y>0.143{print 1.0/(x+(0.143-y)*($1-x)/($2-y))} {x=$1;y=$2}' <  ${n}/${n}.gmm.mrc.fsc > ${n}/${n}.gmm.resolution

	cd -
done
