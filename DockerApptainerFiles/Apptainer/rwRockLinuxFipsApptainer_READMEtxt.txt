# FIPS 140 compatible Apptainer def building for CHPC Redwood

# From Robben Migacz: https://gist.github.com/robbenmigacz/d6b95d867c02a4629f144f3324105e97


# Modify Robben's starter script and execute the following on RW

module load apptainer
unset APPTAINER_BINDPATH SINGULARITY_BINDPATH
apptainer build rocky_python_snakemake_crossmap.sif rocky_python_snakemake_crossmap.def


####### Robben's def file 5 May 2025 ###########

Bootstrap: docker
From: rockylinux:9

%environment
    export PATH=/BioApps/venv/Snakemake/bin:$PATH
    export PATH=/BioApps/venv/CrossMap/bin:$PATH

%post
    dnf -y update

    # Install development tools and Python dependencies
    dnf -y groupinstall "Development Tools"
    # Note that the default version of Python, 3.9, is incompatible with
    # Snakemake because of a version conflict with a dependency; use 3.11
    dnf -y install \
        python3.11 \
        python3.11-pip \
        python3.11-devel \
        wget \
        ca-certificates \
        libffi-devel \
        bzip2-devel \
        xz-devel \
        zlib-devel \
        openssl-devel
	
	# Install without recompiling
    python3.11 -m venv /BioApps/venv/Snakemake
    /BioApps/venv/Snakemake/bin/pip install --upgrade pip
    /BioApps/venv/Snakemake/bin/pip install snakemake
    /BioApps/venv/Snakemake/bin/snakemake --version

    # Install with compiling since some CrossMap dependencies were built with FIPS-incompatible OpenSSL
    python3.11 -m venv /BioApps/venv/CrossMap
    /BioApps/venv/CrossMap/bin/pip install --upgrade pip setuptools wheel
    /BioApps/venv/CrossMap/bin/pip install --no-binary :all: CrossMap -vv
    /BioApps/venv/CrossMap/bin/CrossMap --version