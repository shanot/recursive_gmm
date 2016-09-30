#!/bin/zsh

profile_cmd="/usr/bin/time -v"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4

bindir=${0:h}
impdir=~/imp_sam-fast/

if [[ ! -f ${map_name}_X.npy ]]
then
	${impdir}/setup_environment.sh python ${bindir}/mrc2npy.py ${map_name} ${threshold}
fi


for ((i=1 ; i<=N ; i++))
do
	n=$((n_gaussians**i))
	jobname=${map_name}_${n}
	jobfile=input_${jobname}.sh

	n_jobs=1
	if ((i==1))
	then
		echo ${profile_cmd} ${impdir}/setup_environment.sh python ${bindir}/job.py $map_name $threshold $n
	else
		gmm_name=${n_prev}/${n_prev}.txt
		n_jobs=$(cat ${gmm_name} |wc -l)
		echo "#n_jobs=${n_jobs}"
		echo ${profile_cmd} ${impdir}/setup_environment.sh python ${bindir}/job.py $map_name $threshold $n $gmm_name '$((${SGE_TASK_ID}-1))'
	fi > tmp.txt
	${bindir}/make_array_from_cmds.sh $jobname 100 ${n_jobs} < tmp.txt > $jobfile
	mkdir -p $n
	date
	qsub $jobfile
	ret=0
	while ((ret!=1337))
	do
		ret=$(qrsh -q desktop.q -N cat_${n} -cwd -hold_jid ${jobname} ${bindir}/cat.sh ${n})
	done
	${bindir}/cat_pickle.py ${n}
	n_prev=${n}
	rm ${n}/*.gmm
	rm -f *.{e,o}[3-9]*
done
