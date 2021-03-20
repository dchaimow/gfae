#!/bin/bash
set -e

export SINGULARITY_CACHEDIR=$(pwd)/tmp
export SINGULARITY_TMPDIR=$(pwd)/tmp

install_parameters="
                 --base debian:buster
                 --pkg-manager apt
                 --fsl version=6.0.3"

# dcm2niix
# freesurfer
# miniconda
# spm12

# python: nipype, nilearn, nibabel


generate_docker() {
    singularity -q run docker://repronim/neurodocker:0.7.0 generate docker ${install_parameters}
}

generate_singularity() {
    singularity -q run docker://repronim/neurodocker:0.7.0 generate singularity ${install_parameters}
}

generate_docker > Dockerfile
generate_singularity > Singularity
