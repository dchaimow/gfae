#!/bin/bash

docker run --rm repronim/neurodocker:0.7.0 generate docker \
           --base debian:stretch --pkg-manager apt \
           --fsl version=6.0.3 \
           --miniconda create_env=neuro \
                       conda_install="python=3.8 traits" \
                       pip_install="nipype" > Dockerfile
