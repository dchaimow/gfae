# Generic fmri analysis environment
This is a repo template for container based fMRI analysis development. `gfae.def` defines a apptainer container including a set of useful fMRI analysis software. `container_resource` contains singularity definition files for individual software packages, meant to assist in adapting `gfae.def` to your own needs. Similarly there are folder groupoing definition files for individual components for a specific gfae version (e.g. base image).

The current recipe is `gfae_ubuntu22.def`. It is based on Ubuntu 22.04, with all software versions pinned (see "Pinning" below), and contains:
* conda (Miniforge 24.3.0-0), with the base environment pinned to that of `gfae_20240902T132553Z` (all packages, see `pins/`), e.g.:
  * python 3.11.9
  * nipype 1.8.5
  * notebook 7.2.2
  * jupyterlab 4.2.5
  * numpy 1.26.4 (gradunwarp, ciftify, afni)
  * scipy 1.14.1 (gradunwarp, ciftify, afni)
  * nibabel 3.2.2 (gradunwarp, ciftify; ciftify requires nibabel < 4)
  * seaborn 0.13.2 (ciftify)
  * nilearn 0.10.2 (ciftify)
  * matplotlib 3.9.1 (ciftify, afni)
  * pandas 2.2.2 (ciftify)
  * flask 3.0.3 (afni)
  * flask-cors 5.0.0 (afni)
* FSL 6.0.7.13
* FreeSurfer 7.3.2 (license.txt required to be present in user home directory)
* CAT12.8.2 r2166 and SPM12 r7771 together with Matlab 2017b (v93) runtime
* gradunwarp 1.2.2 (Human Connectome Project version, commit ff082ef)
* Connectome workbench 2.0.0 (HCP release)
* ciftify 2.3.3, with MSM v3.0FSL (replaces FSL's `msm`, which is kept as `msm_fsl`)
* AFNI 26.1.02 (built from source, incl. SUMA and the R programs; atlases `afni_atlases_dist_2024_0503`)
* R 4.6.0 with the AFNI R packages (CRAN snapshot of 2026-05-09)
* ANTs 2.5.3
* ITK-snap 4.0.2
* convert3d 1.0.0
* dcm2niix v1.0.20240202
* jq 1.7.1
* pydeface 2.0.2
* laynii 2.7.0
* firefox 140.11.0esr (Mozilla release archive)
* gnu parallel 20210822
* emacs 27.1
* vim 8.2
* nighres 1.5.1
* GNU octave 6.4.0
* PALM alpha 119

See also components_ubuntu22/todo.md for installation notes and issues (from the older, unpinned recipes).

## MATLAB variant

There is also a variant that includes MATLAB R2024b Update 9 (installed via mpm) and SPM 25.01.02 for MATLAB (in addition to the standalone SPM12): `gfae_matlab_ubuntu22.def`. It is `gfae_ubuntu22.def` plus the MATLAB parts (keep the two files in sync; `diff` them to see the differences). Note: for MATLAB to run, the path to a valid license file or the address of a license server must be provided via environment variables (e.g. `MLM_LICENSE_FILE`) when starting the container. It is possible to set `APPTAINERENV_MLM_LICENSE_FILE` outside the container to have it available inside the container as `MLM_LICENSE_FILE`.

## Pinning

Both recipes pin all software versions, so that a rebuild produces the same software:
* the base image by digest (`ubuntu:jammy-20260410`), and all apt packages from the Ubuntu snapshot archive (`snapshot.ubuntu.com`, 2026-05-09)
* the conda base environment: `pins/base_env_conda_pins.txt` (all conda packages as `name==version=build`) and `pins/base_env_pip_pins.txt` (all pip packages, installed with `--no-deps`), generated with `pins/make_base_env_pins.py` from the base environment of `gfae_20240902T132553Z`; there is no `conda update`, and pip installs do not change other packages (unpinned pip installs had upgraded nibabel and broken ciftify)
* all downloads by version, verified by their sha256 checksum (the build fails if a file changed); git sources (AFNI, nighres and its java dependencies, gradunwarp) by commit
* R by package version (CRAN apt repository), the R packages from a dated CRAN snapshot (Posit Package Manager)
* not pinned: the MathWorks package manager `mpm` (only available in its current version; MATLAB itself is pinned by `--release=R2024bU9`)

Reasons, history and build pitfalls: `notes/pinning.md`. To update a component, change its version, URL and checksum together (`sha256sum` of the new file). `%post` stops at the first error (`set -euo pipefail`).

Known issues of earlier images (unpinned recipe): `gfae_20260509T025235Z` has nibabel 5.4.2, which breaks ciftify; `gfae_20260520T002955Z` contains no FSL (the FSL installation failed without stopping the build).

## Building

`./build.sh gfae_ubuntu22.def gfae` (or `./build.sh gfae_matlab_ubuntu22.def gfae_matlab`) builds the image with `--fakeroot` and names it `<name>_<build time>_md5<checksum>_git<commit>.sif`. A build takes several hours (AFNI is compiled; use a node with many cores, in tmux or as a job). The `%test` section checks the versions of the main software and that the programs of all packages are available. Building with `--notest` and then running `apptainer test <image>.sif` keeps the image if a test fails.

## General usage as a template for container based development
Currently the repo is mainly used to assist in developing and building `gfae` containters. It could also be used as described below as a template for repositories for (fMRI analysis) container based development. This hasn't been tested recently.

### 1. Dowload script
```
wget https://raw.githubusercontent.com/dchaimow/gfae/master/new_repo_from_gfae_template.sh
chmod +x new_repo_from_gfae_template.sh
```

### 2. Create new local repo from template
```
./new_repo_from_gfae_template.sh my-new-repo
cd my-new-repo
```

### 3. Build singularity container
Optionally adapt gfae.def to your needs first, then
```
./build.sh gfae.def
```

### 4. Start singularity container and start analyzing/developing
```
./start_dev_container.sh
```

Write scripts and code, etc. in `code/` (bound to `/opt/code/` inside container). Change and commit repo as needed.

### 5. Prepare for distribution
Create new singularity .def file based on gfae.def.

Add:
* `%files` section: `code/* /opt/code/`
* `%post` section: `chmod -R 755 /opt/code`  
* optional: add `%runscript` section
  * if conda initialization is needed first put:
   ```
   . /opt/conda/etc/profile.d/conda.sh
   . /opt/conda/etc/profile.d/mamba.sh
   conda activate base
   ```
 
