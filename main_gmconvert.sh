#!/bin/zsh

profile_cmd="/usr/bin/time -v"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4

bindir=${0:h}
impdir=~/imp_sam-fast/
gmconvert=~/gmconvert_MAX/gmconvert

for ((i=1 ; i<=N ; i++))
do
	n=$((n_gaussians**i))
	jobname=${map_name}_${n}
	jobfile=input_${jobname}.sh

	n_jobs=1
	if ((i==1))
	then
		echo ${profile_cmd} ${gmconvert} -imap ${map_name} -ogmm $n/$n.gmm -ng ${n} -zth ${threshold}
	else
		gmm_name=${n_prev}/${n_prev}.txt
		n_jobs=$(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_name})
		gmm_list=${n_prev}/GMM.list
		echo echo ${gmm_name} '$((${SLURM_ARRAY_TASK_ID}-1))' \> 'tmp_${SLURM_ARRAY_TASK_ID}.txt'  
		echo ${profile_cmd} ${gmconvert} -imap ${map_name}  -gmml 'tmp_${SLURM_ARRAY_TASK_ID}.txt' -ogmm $n/${n}_'$((${SLURM_ARRAY_TASK_ID}-1))'.gmm -ng ${n_gaussians} -zth ${threshold}
	fi > tmp.txt
	${bindir}/make_array_from_cmds.sh $jobname 100 ${n_jobs} < tmp.txt > $jobfile
	rm tmp.txt
	mkdir -p $n
	date
	sbatch $jobfile | tee sbatch.out
	jobid=$(awk '{print $NF}' < sbatch.out)
	rm sbatch.out
	echo jobid=$jobid
	#not ok is because kawabata exits 1
	srun --job-name 'cat' --dependency=afternotok:${jobid} date
	cat ${n}/${n}*.gmm > ${n}/${n}.txt
	${bindir}/gmconvert2imp.sh  ${n}/${n}.txt >  ${n}/${n}_imp.txt
	n_prev=${n}
done
