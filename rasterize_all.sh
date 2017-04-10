#!/bin/zsh
bindir=${0:h}
for f in [0-9]*/*_imp.txt
do
	if [[ (! -f $f.mrc) || ($f -nt $f.mrc) ]]
	then
		~/imp-fast/setup_environment.sh python ${bindir}/rasterize.py $f 2.5 $1 &
	else
		echo $f.mrc done
	fi
done
