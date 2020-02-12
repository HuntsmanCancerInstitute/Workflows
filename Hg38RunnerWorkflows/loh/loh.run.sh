#!/bin/bash
#SBATCH --account=hci-kp
#SBATCH --partition=hci-kp
#SBATCH -N 1
#SBATCH -t 2:00:00
set -e; start=$(date +'%s');  touch STARTED




#### Do just once ####

# 1) Install Singularity (https://www.sylabs.io) or load via a module then define the path to the executable
module load singularity/3.5.2
singExec=/uufs/chpc.utah.edu/sys/installdir/singularity3/std/bin/singularity

# 2) Define file paths to "mount" in the container.
db=/uufs/chpc.utah.edu/common/home/u0762203/db
# 3) Modify the workflow xxx.sing file setting the paths to the required resources. These must be within the mounts.

# 4) Build the singularity container, and define the path to the xxx.sif file, do just once after each update.
#$singExec pull docker://qingl0331/qinglhci2019:loh
container=/uufs/chpc.utah.edu/common/home/u0762203/u0762203/project/loh/qinglhci2019_loh.sif


#### Do for every run ####

# 1) Create a folder named as you would like the analysis name to appear. This must reside in the mount paths.

# 2) Copy over the workflow docs: xxx.sing, xxx.sh into the job directory.
# 3) Launch the xxx.sh via slurm's sbatch or run it on your local server.  




#### No need to modify anything below ####

echo -e "\n---------- Starting -------- $((($(date +'%s') - $start)/60)) min"

# Read out params
#name=${PWD##*/} # last dir of current dir, which is single patient dir
jobDir=`readlink -f .` #full path of current dir
SINGULARITYENV_jobDir=$jobDir  SINGULARITYENV_db=$db $singExec exec --containall --bind $db $container bash $jobDir/*.sing

echo -e "\n---------- Complete! -------- $((($(date +'%s') - $start)/60)) min total"

touch COMPLETE 

