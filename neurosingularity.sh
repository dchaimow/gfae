#!/bin/bash
set -e

export SINGULARITY_CACHEDIR=$(pwd)/tmp
export SINGULARITY_TMPDIR=$(pwd)/tmp

singularity -q run docker://repronim/neurodocker:master generate singularity \
            --base debian:stretch \
            --pkg-manager apt \
            --install git make gcc g++ zlib1g-dev \
            --freesurfer version=7.1.1 \
            --copy license.txt /license.txt \
            --env FS_LICENSE=/license.txt \
            --fsl version=6.0.3 \
            --ants version=2.3.1 \
            --afni version=latest \
            > Singularity


#            --run-bash 'cd /opt && 
#                        git clone https://github.com/layerfMRI/laynii && 
#                        cd /opt/laynii && 
#                        make all' \
#            --env 'PATH=/opt/laynii:$PATH' \

# --fsl version=6.0.3 \
#            --afni version=latest \
#            --ants version=2.3.1 \
#            --run-bash 'cd /opt && \
#                        git clone https://github.com/layerfMRI/laynii && \
#                        cd /opt/laynii && \
#                        make all' \
#            --env 'PATH=/opt/laynii:$PATH' \
#            --fsl version=6.0.3 \


# install_parameters="
#                  --base debian:buster
#                  --pkg-manager apt
#                  --afni version=latest
#                  --ants version=2.3.1
#                  --dcm2niix version=latest
#                  --freesurfer version=7.1.1
#                  --copy license.txt /opt/freesurfer-7.1.1/
#                  --fsl version=6.0.3
#                  --miniconda create_env=neuro \
#                              conda_install='python 3.8 numpy pandas scipy traits nilearn \
#                                             scikit-learn nipype jupyter nibabel'
#                  --spm12 version=r7771"

# todo: LAYNII, ITK-SNAP


#generate_docker() {
#    singularity -q run docker://repronim/neurodocker:0.7.0 generate docker ${install_parameters}
#}

#generate_singularity() {
#    singularity -q run docker://repronim/neurodocker:0.7.0 generate singularity ${install_parameters}
#}

#generate_docker > Dockerfile
#generate_singularity > Singularity
