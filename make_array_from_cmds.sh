#!/bin/bash

echo "#!/bin/bash
#SBATCH --job-name=$1
#SBATCH --array=1-$2

offset=$3
"

echo '
bindir=$(dirname $0)
source ${bindir}/modules.sh
'

cat
