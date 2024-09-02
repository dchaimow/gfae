#!/bin/bash
shopt -s extglob

export APPTAINER_TMPDIR=~/ptmp/tmp
export APPTAINER_CACHEDIR=~/ptmp/tmp
export APPTAINER_BINDPATH=

deffile=${1-gfae.def}
container_fname=${2-$(basename $deffile .def)}_sandbox

# Build the container
apptainer build --fakeroot --sandbox $container_fname $deffile