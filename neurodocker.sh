#!/bin/bash
set -e

generate_docker() {
    docker run --rm repronim/neurodocker:master generate docker \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt \
           --afni version=latest \
           --ants version=2.3.4 \
           --fsl version=6.0.4
}

generate_singularity() {
    docker run --rm repronim/neurodocker:master generate singularity \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt \
           --afni version=latest \
           --ants version=2.3.4 \
           --fsl version=6.0.4
}

generate_docker > Dockerfile
generate_singularity > Singularity


# dcm2niix
# freesurfer
# miniconda
# spm12

# python: nipype, nilearn, nibabel
