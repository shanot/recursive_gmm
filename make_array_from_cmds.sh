#!/bin/zsh

echo "
#!/bin/zsh
# ---
#$ -N $1
#$ -cwd
#$ -S /bin/zsh
#$ -t 1-$3
#$ -tc $2
#$ -q all.q
# ---
#1=$1
#2=$2
#3=$3
"
echo '
module ()
{
	eval `/usr/bin/modulecmd bash $*`
}

source ~/bin/riccardo_modules.sh
'

cat
