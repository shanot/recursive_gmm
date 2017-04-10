#!/bin/bash

echo "#!/bin/bash
#SBATCH --job-name=$1
#SBATCH --array=1-$2

offset=$3

source ~/modules.sh
"

cat
