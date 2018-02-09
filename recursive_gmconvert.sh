#!/bin/zsh

profile_cmd="time"

map_name=$1
threshold=$2
n_gaussians=$3
N=$4
MaxArraySize=100000

get_max_jobs(){
	echo ${MaxArraySize}
}

i0=1
if [ -n "$5" ]
then
	i0=$5
fi

echo $i0

serial=0
if [ -n "$6" ]
then 
	serial=$6
fi

bindir=${0:h}
impdir=~/imp-fast/
gmconvert=${bindir}/gmconvert/gmconvert

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
		n_jobs=0
		for gmm_file in $(cat ${n_prev}/not_converged.txt)
		do
			n_jobs=$((n_jobs + $(awk '/NGAUSS/{s+=$3}END{print s}' ${gmm_file}) ))
		done
		echo echo ${gmm_name} '$((SLURM_ARRAY_TASK_ID-1+offset))' \> 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt'  
		echo ${profile_cmd} ${gmconvert} -imap ${map_name}  -gmml 'tmp_$((SLURM_ARRAY_TASK_ID+offset)).txt' -oimap $n/'sub_$((SLURM_ARRAY_TASK_ID+offset-1)).mrc' -ogmm $n/${n}_'$((SLURM_ARRAY_TASK_ID-1+offset))'.gmm -ng ${n_gaussians} -zth ${threshold}
		echo ${gmconvert}  -igmm $n/${n}_'$((SLURM_ARRAY_TASK_ID-1+offset)).gmm' -imap $n/'sub_$((SLURM_ARRAY_TASK_ID+offset-1)).mrc' -omap /dev/null
	fi > commands_$i.sh
	mkdir -p $n
	max_jobs=$(get_max_jobs)
	if ((serial==0))
	then
		for ((j=0 ; j<n_jobs ; j=j+max_jobs))
		do
			jobfile=input_${jobname}_${j}.sh
			k=$max_jobs
			if ((j+k > n_jobs))
			then
				k=$((n_jobs - j))
			fi
			echo j=$j, k=$k, jobfile=$jobfile, n_jobs=${n_jobs}
			${bindir}/make_array_from_cmds.sh $jobname $k $j < commands_$i.sh > $jobfile
			date
			sbatch -o ${n}/"slurm-%a_${j}.out" $jobfile
		done
		jobids=$(squeue -O arrayjobid -u $(whoami) -n ${jobname} -S i -h | tr '\n' ':' | tr -d ' ')
		jobids=${jobids%?}
		echo waiting for jobids=$jobids
		#not ok is because gmconvert exits 1
		srun --job-name 'post' --dependency=afternotok:${jobids} --export=ALL,map_name=${map_name},n=${n},bindir=${bindir} --pty ${bindir}/postprocess.sh
	else
		for ((j=1 ; j<=n_jobs ; j++))
		do
			echo $j/$n_jobs
			SLURM_ARRAY_TASK_ID=$j; offset=0; source commands_$i.sh > ${n}/"slurm-${j}_0.out" 2>&1
		done
		source ${bindir}/postprocess.sh 
	fi
	mkdir -p plots
	gnuplot ${bindir}/plot_fsc.gpl
done
