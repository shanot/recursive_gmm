#!/bin/zsh

profile_cmd="/usr/bin/time -v"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4
MaxArraySize=100000

#get_max_jobs(){
#	max_jobs=${MaxArraySize}
#	for id in $(squeue -h | awk '{print $1}')
#	do
#		max_jobs=$((max_jobs-$(scontrol show job $id | grep NumCPUs | cut -d '=' -f 3 | cut -d ' ' -f 1)))
#	done
#	echo ${max_jobs}
#}
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

mkdir -p converged
${gmconvert} -imap ${map_name} -zth ${threshold} -oimap threshold.map -ogmm /dev/null -ng 0
for ((i=$i0 ; i<=N ; i++))
do
	n=$((n_gaussians**i))
	n=$((i))
	jobname=${map_name}_${n}

	n_jobs=1
	if ((i==1))
	then
		echo ${profile_cmd} ${gmconvert} -imap ${map_name} -ogmm $n/${n}_0.gmm -ng ${n_gaussians} -zth ${threshold}
		echo ${gmconvert}  -igmm $n/${n}_0.gmm -imap ${map_name} -omap /dev/null
	else
		n_prev=$((i-1))
		gmm_name=${n_prev}/${n_prev}.gmm
		#n_jobs=$(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_name})
		n_jobs=0
		for gmm_file in $(cat ${n_prev}/not_converged.txt)
		do
			n_jobs=$((n_jobs + $(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_file}) ))
		done
		echo echo ${gmm_name} '$((SLURM_ARRAY_TASK_ID-1+offset))' \> 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt'  
		echo ${profile_cmd} ${gmconvert} -imap ${map_name}  -gmml 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt' -oimap $n/'sub_$((SLURM_ARRAY_TASK_ID+offset-1)).mrc' -ogmm $n/${n}_'$((SLURM_ARRAY_TASK_ID-1+offset))'.gmm -ng ${n_gaussians} -zth ${threshold}
		echo ${gmconvert}  -igmm $n/${n}_'$((SLURM_ARRAY_TASK_ID-1+offset)).gmm' -imap $n/'sub_$((SLURM_ARRAY_TASK_ID+offset-1)).mrc' -omap /dev/null
	fi > tmp.txt
	mkdir -p $n
	max_jobs=$(get_max_jobs)
	if ((n_jobs>100000))
	then
		break
	fi
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
		sbatch -o ${n}/"slurm-%a_${j}.out" $jobfile
	done
	jobids=$(squeue -O arrayjobid -u $(whoami) -n ${jobname} -S i -h | tr '\n' ':' | tr -d ' ')
	jobids=${jobids%?}
	echo waiting for jobids=$jobids
	#not ok is because kawabata exits 1
	srun --job-name 'post' --dependency=afternotok:${jobids} --export=ALL,map_name=${map_name},n=${n},bindir=${bindir} --pty ${bindir}/postprocess.sh
done
