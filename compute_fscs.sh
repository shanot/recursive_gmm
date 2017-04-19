#!/bin/bash

source ~/modules.sh

for f in $(find . -name '*.mrc')
do
	e2proc3d.py $(dirname $f)/../threshold.map $f.fsc --calcfsc $f
	awk '$2<=0.143 && y>0.143{print 1.0/(x+(0.143-y)*($1-x)/($2-y))} {x=$1;y=$2}' <  $f.fsc > $f.resolution
done

