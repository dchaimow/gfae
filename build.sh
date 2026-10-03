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

# Build the container (without running %test, so that the image is kept if a test fails)
apptainer build --fakeroot --notest $container_fname $deffile || exit 1

# Name the container with the git sha and build date
md5=$(md5sum $container_fname | cut -d' ' -f1)
build_date=$(date -u +"%Y%m%dT%H%M%SZ")
final_fname=${container_fname%.sif}_${build_date}_md5${md5}_git${git_sha}.sif
mv ${container_fname} ${final_fname}

# Run the %test section of the definition file
if apptainer test ${final_fname}; then
  echo "tests passed: ${final_fname}"
else
  echo "TESTS FAILED: ${final_fname}"
  exit 1
fi