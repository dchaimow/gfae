#!/bin/bash
set -e

NAME="${1:-neurodocker.def}"
TYPE="${2:-singularity}"

singularity run docker://repronim/neurodocker:latest generate $TYPE \
           --base-image centos:7 \
           --pkg-manager yum \
           --dcm2niix version=latest  \
           --jq version=1.6 \
           --convert3d version=1.0.0 \
           > $NAME
