#!/bin/bash
shopt -s extglob

export APPTAINER_TMPDIR=~/ptmp/tmp
export APPTAINER_CACHEDIR=~/ptmp/tmp
export APPTAINER_BINDPATH=

deffile=${1-gfae.def}
container_fname=${2-$(basename $deffile .def)}.sif

if output=$(git status --porcelain) && [ -z "$output" ]; then
  # Working directory clean
  git_sha=$(git rev-parse HEAD)
else
  # Uncommitted changes
  git_sha=UNAVAILABLE
fi

# Build the container
apptainer build --fakeroot $container_fname $deffile

# Name the container with the git sha and build date
md5=$(md5sum $container_fname | cut -d' ' -f1)
build_date=$(date -u +"%Y%m%dT%H%M%SZ")
mv ${container_fname} ${container_fname%.sif}_${build_date}_md5${md5}_git${git_sha}.sif