#!/bin/zsh

profile_cmd="/usr/bin/time -v"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4

bindir=${0:h}
impdir=~/imp_sam-fast/
gmconvert=/Bis/home/shanot/gmconvert_MAX/gmconvert

for ((i=1 ; i<=N ; i++))
do
	n=$((n_gaussians**i))
	jobname=${map_name}_${n}
	jobfile=input_${jobname}.sh
	jobnum=0
	mkdir -p $n

	n_jobs=1
	if ((i==1))
	then
		echo ${profile_cmd} ${gmconvert} -imap ${map_name} -ogmm $n/${n}_0.gmm -ng ${n} -zth ${threshold}
		echo -n "" > ${n}/${n}_0.parent
		jobnum=1
	else
		for f in $(ls -v ${n_prev}/${n_prev}_[0-9]*.gmm)
		do
			gmm_name=$f
			parent=${n_prev}/$(basename $f .gmm).parent
			n_jobs=$(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_name})
			for ((j=0 ; j<n_jobs ; j++))
			do
				gmml_file=${n}/${n}_${jobnum}.parent
				cat ${parent} > ${gmml_file}
				echo ${gmm_name} ${j} >> ${gmml_file}
				echo ${profile_cmd} ${gmconvert} -imap ${map_name}  -gmml ${gmml_file} -ogmm $n/${n}_${jobnum}.gmm -ng ${n_gaussians} -zth ${threshold}
				jobnum=$((jobnum+1))
			done
		done
	fi > ${jobfile}.lst
	${bindir}/make_array_from_list.sh $jobname 200 $jobnum ${jobfile}.lst > $jobfile
	date
	qsub $jobfile
	ret=0
	while ((ret!=1337))
	do
		ret=$(qrsh -q desktop.q -N cat_${n} -cwd -hold_jid ${jobname} echo 1337)
	done
	cat ${n}/${n}*.gmm > ${n}/${n}.txt
	n_prev=${n}
done
