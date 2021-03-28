#!/bin/bash
set -e

export SINGULARITY_CACHEDIR=$(pwd)/tmp
export SINGULARITY_TMPDIR=$(pwd)/tmp

install_parameters="
                 --base debian:stretch
                 --pkg-manager apt
                 --fsl version=6.0.3
                 --afni version=latest
                 --freesurfer version=6.0.1
                 --copy license.txt /opt/freesurfer-6.0.1/
                 --ants version=2.3.1
                 --dcm2niix version=latest method=source
                 --miniconda create_env=neuro \
                             conda_install='python 3.8 numpy pandas scipy traits nilearn \
                                            scikit-learn nipype jupyter nibabel'
                 --spm12 version=r7771"

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


generate_docker() {
    singularity -q run docker://repronim/neurodocker:0.7.0 generate docker ${install_parameters}
}

generate_singularity() {
    singularity -q run docker://repronim/neurodocker:0.7.0 generate singularity ${install_parameters}
}

generate_docker > Dockerfile
generate_singularity > Singularity
