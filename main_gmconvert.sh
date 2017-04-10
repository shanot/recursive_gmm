#!/bin/zsh

profile_cmd="/usr/bin/time -v"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4
MaxArraySize=10000

get_max_jobs(){
	max_jobs=${MaxArraySize}
	for id in $(squeue -h | awk '{print $1}')
	do
		max_jobs=$((max_jobs-$(scontrol show job $id | grep NumCPUs | cut -d '=' -f 3 | cut -d ' ' -f 1)))
	done
	echo ${max_jobs}
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

for ((i=$i0 ; i<=N ; i++))
do
	n=$((n_gaussians**i))
	n_prev=$((n_gaussians**(i-1)))
	jobname=${map_name}_${n}

	n_jobs=1
	if ((i==1))
	then
		echo ${profile_cmd} ${gmconvert} -imap ${map_name} -ogmm $n/$n.gmm -ng ${n} -zth ${threshold}
	else
		gmm_name=${n_prev}/${n_prev}.txt
		n_jobs=$(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_name})
		gmm_list=${n_prev}/GMM.list
		echo echo ${gmm_name} '$((SLURM_ARRAY_TASK_ID-1+offset))' \> 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt'  
		echo ${profile_cmd} ${gmconvert} -imap ${map_name}  -gmml 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt' -ogmm $n/${n}_'$((SLURM_ARRAY_TASK_ID-1+offset))'.gmm -ng ${n_gaussians} -zth ${threshold}
	fi > tmp.txt
	mkdir -p $n
	max_jobs=$(get_max_jobs)
	for ((j=0 ; j<n_jobs ; j=j+max_jobs))
	do
		jobfile=input_${jobname}_${j}.sh
		k=$max_jobs
		if ((j+k > n_jobs))
		then
			k=$((n_jobs - j))
		fi
		echo j=$j, k=$k, jobfile=$jobfile, n_jobs=${n_jobs}
		${bindir}/make_array_from_cmds.sh $jobname $k $j < tmp.txt > $jobfile
		date
		sbatch -o ${n}/"slurm-%a_${i}.out" $jobfile
	done
	rm tmp.txt
	jobids=$(squeue -O arrayjobid -u $(whoami) -n ${jobname} -S i -h | tr '\n' ':' | tr -d ' ')
	jobids=${jobids%?}
	echo waiting for jobids=$jobids
	#not ok is because kawabata exits 1
	srun --job-name 'cat' --dependency=afternotok:${jobids} date
	cat ${n}/${n}*.gmm > ${n}/${n}.txt
	${bindir}/gmconvert2imp.sh  ${n}/${n}.txt >  ${n}/${n}_imp.txt
done
