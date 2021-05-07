#!/bin/bash
set -e

generate_docker() {
    docker run --rm repronim/neurodocker:master generate docker \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt \
           --install git make gcc g++ zlib1g-dev \
           --freesurfer version=7.1.1 \
           --copy license.txt /license.txt \
           --env FS_LICENSE=/license.txt \
           --fsl version=6.0.3 \
           --ants version=2.3.1 \
           --afni version=latest \
           --run-bash 'cd /opt && 
                       git clone https://github.com/layerfMRI/laynii && 
                       cd /opt/laynii && 
                       make all' \
           --env 'PATH=/opt/laynii:$PATH'
}

generate_singularity() {
    docker run --rm repronim/neurodocker:master generate singularity \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt \
           --install git make gcc g++ zlib1g-dev \
           --freesurfer version=7.1.1 \
           --copy license.txt /license.txt \
           --env FS_LICENSE=/license.txt \
           --fsl version=6.0.3 \
           --ants version=2.3.1 \
           --afni version=latest \
           --run-bash 'cd /opt && 
                       git clone https://github.com/layerfMRI/laynii && 
                       cd /opt/laynii && 
                       make all' \
           --env 'PATH=/opt/laynii:$PATH'
}

generate_docker > Dockerfile
generate_singularity > Singularity


# dcm2niix
# freesurfer
# miniconda
# spm12

# python: nipype, nilearn, nibabel
