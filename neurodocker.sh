#!/bin/bash
set -e

docker run --rm repronim/neurodocker:master generate docker \
       --base neurodebian:stretch-non-free \
       --pkg-manager apt \
       --afni version=latest \
       --ants version=2.3.4 \
       --fsl version=6.0.4 \
       > Dockerfile


# dcm2niix
# freesurfer
# miniconda
# spm12

# python: nipype, nilearn, nibabel
