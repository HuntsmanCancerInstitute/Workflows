# Docker file to build a fips compatible python dist for use in the PE at CHPC
# Adapted from an Apptainer build file from Robben Migacz https://gist.github.com/robbenmigacz/31801a57ea9a612d1cd7163161219309
# Pushed as hcibioinformatics/public:fibsSmCmUsTxVt_1

FROM ubuntu:24.04

SHELL ["/bin/bash", "-c"]

MAINTAINER DavidNix david.nix@hci.utah.edu

# Set env 
ENV	OPENSSL_CONF	/usr/local/ssl/openssl.cnf
ENV	OPENSSL_MODULES	/usr/local/ssl/lib64/ossl-modules
ENV	LD_LIBRARY_PATH	/usr/local/ssl/lib64:$LD_LIBRARY_PATH
ENV	PATH	/usr/local/ssl/bin:/usr/local/python/bin:$PATH
ENV	DEBIAN_FRONTEND	noninteractive

# Num cores to use with make
RUN MAKE_JOBS=$(nproc)

# Install following Robben's apptainer file
RUN	apt -y update
RUN	apt install -y build-essential wget zlib1g-dev libffi-dev libsqlite3-dev libbz2-dev ca-certificates

# Download and install openssl
WORKDIR	/usr/local/src
RUN	wget https://github.com/openssl/openssl/releases/download/openssl-3.0.16/openssl-3.0.16.tar.gz
RUN	tar xf openssl-3.0.16.tar.gz
WORKDIR /usr/local/src/openssl-3.0.16
RUN	./Configure linux-x86_64 --prefix=/usr/local/ssl --openssldir=/usr/local/ssl enable-fips
RUN	make -j$MAKE_JOBS
RUN	make install_sw
RUN	make install_fips

# Write the openssl.cnf
RUN	cat <<EOF > /usr/local/ssl/openssl.cnf
config_diagnostics = 1
openssl_conf = openssl_init

.include /usr/local/ssl/fipsmodule.cnf

[openssl_init]
providers = provider_sect
alg_section = algorithm_sect

[provider_sect]
fips = fips_sect
default = default_sect

[default_sect]
activate = 1

[algorithm_sect]
default_properties = fips=yes
EOF
RUN	rm -rf /usr/local/src/openssl-3.0.16.tar.gz

# Install Python
WORKDIR	/usr/local/src/
RUN	wget --no-check-certificate https://www.python.org/ftp/python/3.12.10/Python-3.12.10.tgz
RUN	tar xf Python-3.12.10.tgz
WORKDIR /usr/local/src/Python-3.12.10
RUN	./configure --prefix=/usr/local/python --with-openssl=/usr/local/ssl LDFLAGS="-L/usr/local/ssl/lib64" CPPFLAGS="-I/usr/local/ssl/include" PKG_CONFIG_PATH="/usr/local/ssl/lib64/pkgconfig"
RUN	make -j$MAKE_JOBS
RUN	make install
RUN	rm -rf /usr/local/src/Python-3.12.10.tgz
RUN	python3 --version

# Install misc for std CBI containers
RUN	apt-get install -y autoconf automake perl liblzma-dev libcurl4-gnutls-dev libssl-dev libperl-dev libgsl0-dev unzip zip nano openjdk-11-jre graphviz git
RUN	java -version

# Install snakemake in venv, each RUN is a new shell so must && cmds
RUN	python3 -m venv /BioApps/venv/Snakemake
RUN	source /BioApps/venv/Snakemake/bin/activate && \
	pip3 install snakemake && \
	snakemake --version && \
	deactivate

# Install Crossmap, 0.7.0
RUN	python3 -m venv /BioApps/venv/CrossMap
RUN     source /BioApps/venv/CrossMap/bin/activate && \
        pip3 install CrossMap && \
        CrossMap --version && \
        deactivate

# Install latest USeq
COPY	USeq_*zip /BioApps/
WORKDIR /BioApps/
RUN	unzip USeq_*zip
RUN	rm -rf USeq_*zip
RUN	mv USeq_* USeq
RUN	java -jar USeq/Apps/LoH

# Install vt, /BioApps/vt/vt
WORKDIR /BioApps/
RUN	git clone https://github.com/atks/vt.git
WORKDIR /BioApps/vt
RUN	git submodule update --init --recursive
RUN	make -j$MAKE_JOBS
RUN	make test

# Install htslib, /BioApps/HtsLib1.21/bin/
WORKDIR /BioApps/
RUN	wget --no-check-certificate https://github.com/samtools/htslib/releases/download/1.21/htslib-1.21.tar.bz2
RUN	tar xf htslib-1.21.tar.bz2
RUN	mkdir HtsLib1.21
RUN	rm -rf htslib-1.21.tar.bz2
WORKDIR	/BioApps/htslib-1.21
RUN	./configure --prefix=/BioApps/HtsLib1.21
RUN	make -j$MAKE_JOBS
RUN	make install
WORKDIR /BioApps/
RUN	rm -rf htslib-1.21



