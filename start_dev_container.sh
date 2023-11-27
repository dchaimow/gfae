#!/bin/bash
container_file=${1:-gfae.sif}

mkdir -p code
singularity shell --bind code:/opt/code ${container_file} 
