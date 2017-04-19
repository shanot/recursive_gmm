#!/bin/bash

script="$(readlink -f ${BASH_SOURCE[0]})"
bindir="$(dirname ${script})"

tmpfile=$(mktemp tmp_XXXX.sh)
for f in [0-9]*/*_imp.gmm
do
	if [[ ! -f $f.mrc ]] || [[ $f -nt $f.mrc ]]
	then
		echo ~/imp-fast/setup_environment.sh python ${bindir}/rasterize.py $f 2.5 $1
	fi
done > ${tmpfile}

${bindir}/make_array_from_cmds.sh RASTER 1 0 < ${tmpfile} > test.sh
chmod +x test.sh
srun test.sh
