#!/bin/bash
set -e

generate_docker() {
    docker run --rm repronim/neurodocker:master generate docker \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt 
}

generate_singularity() {
    docker run --rm repronim/neurodocker:master generate singularity \
           --base neurodebian:stretch-non-free \
           --pkg-manager apt 
}

generate_docker > Dockerfile
generate_singularity > Singularity


# dcm2niix
# freesurfer
# miniconda
# spm12

# python: nipype, nilearn, nibabel
