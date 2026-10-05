#!/bin/bash
shopt -s extglob

export APPTAINER_TMPDIR=~/ptmp/tmp
export APPTAINER_CACHEDIR=~/ptmp/tmp
export APPTAINER_BINDPATH=

if [ $# -lt 1 ]; then
  echo "usage: $0 <definition file> [image name]   (e.g. $0 gfae_ubuntu24.def gfae)"
  exit 1
fi
deffile=$1
name=${2-$(basename $deffile .def)}

if output=$(git status --porcelain) && [ -z "$output" ]; then
  # Working directory clean
  git_sha=$(git rev-parse HEAD)
else
  # Uncommitted changes
  git_sha=UNAVAILABLE
fi

# Layered recipes (Bootstrap: localimage): the base image (From:, e.g. a link gfae-base.sif to the built image) must
# have the sha256 recorded in the definition file as "# base-sha256: <sha256>"
if grep -q "^Bootstrap: localimage" $deffile; then
  base=$(awk '/^From:/ {print $2; exit}' $deffile)
  expected=$(sed -n 's/^# base-sha256: //p' $deffile)
  actual=$(sha256sum "$base" | cut -d' ' -f1) || exit 1
  if [ "$actual" != "$expected" ]; then
    echo "base image $base ($(readlink -f $base)) has sha256 $actual,"
    echo "but $deffile expects base-sha256: $expected"
    exit 1
  fi
  echo "base image $base: sha256 matches"
fi

# Build the container
# - into a temporary file name (not <name>.sif, which may be the link to an image used as base of the next layer)
# - without running %test, so that the image is kept if a test fails
# - with --force: overwrites a left-over temporary file, and lets the labels of a layer replace labels of the same
#   name inherited from its base image (e.g. Description)
building_fname=${name}_building.sif
apptainer build --fakeroot --force --notest $building_fname $deffile || exit 1

# Name the container with the build date, its md5 and the git sha
md5=$(md5sum $building_fname | cut -d' ' -f1)
build_date=$(date -u +"%Y%m%dT%H%M%SZ")
final_fname=${name}_${build_date}_md5${md5}_git${git_sha}.sif
mv ${building_fname} ${final_fname}

# Run the %test section of the definition file
if apptainer test ${final_fname}; then
  echo "tests passed: ${final_fname}"
else
  echo "TESTS FAILED: ${final_fname}"
  exit 1
fi