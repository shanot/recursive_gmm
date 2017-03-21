#!/bin/bash

echo "#!/bin/bash
#SBATCH --job-name=$1
#SBATCH --array=1-$3

source ~/modules.sh
"

cat
