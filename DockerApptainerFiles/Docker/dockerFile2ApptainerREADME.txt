# Major issues with this approach for Redwood
# Some python apps must be recompiled on a FIPS 140 enabled machine, e.g. CrossMap, but not Snakemake
# Thus build this directly on Redwood using an Apptainer def File like https://gist.github.com/robbenmigacz/d6b95d867c02a4629f144f3324105e97





# david.nix@hci.utah.edu 22 April 2025

########## Creating a Apptainer from a Dockerfile ###########

# login to hci-zion and build your dockerfile, see https://github.com/HuntsmanCancerInstitute/Workflows/tree/master/DockerFiles
nano fibsSnakemake_10.dockerfile

# build it and save the sha256 name
docker build -f fibsSnakemake_10.dockerfile .

# run it, w/ or w/o --rm!, check it looks good
docker run --rm -it -v /home/u0028003:/home/u0028003 sha256:4a9560d5e82a6867ac300a60ed241838305e8a2b5a2877e22634cc3445aea3a6

# commit the one run w/o --rm
docker commit d636ab674755 hcibioinformatics/public:fipsSnakemake_10

# push it to the repo 
docker push hcibioinformatics/public:fipsSnakemake_10

# login to redwood, pull, and run it as an apptainer
module load apptainer
apptainer pull docker://hcibioinformatics/public:fipsSnakemake_10
apptainer run public_fipsSnakemake_10.sif

# in the container, activate the venv, and run it
source /BioApps/venv/Snakemake/bin/activate
snakemake --cores 2 --snakefile TestSnakemake/test.sm
