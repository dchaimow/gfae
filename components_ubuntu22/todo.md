# TODO:
- [x] basic_ubuntu22.def
- [x] conda_ubuntu22.def
- [x] afni_ubuntu22.def
- [x] ants_ubuntu22.def
- [x] fsl_ubuntu22.def
- [x] freesurfer_ubuntu22.def
- [x] spm12cat12_ubuntu22.def
- [x] workbench_ubuntu22.def
- [x] ciftify_ubuntu22.def
- [x] firefox_ubuntu22.def
- [x] gradunwarp
- [x] laynii
- [x] pydeface
- [x] itk-snap
- [x] check all definition files again for specific version definitions
- [x] combine and add: jq, convert3d, dcm2niix, parallel (to basic?), analysis repos


# notes and issues:
* basic: (DONE) need to change prompt so that history up/down assume the right prompt length (e.g. https://superuser.com/questions/382456/why-does-this-bash-prompt-sometimes-keep-part-of-previous-commands-when-scrollin)
* basic: (DONE) consider adding emacs (and vim), games?
* conda: some packages that are being installed are a very standard minimum, but there are also packages and required versions that are needed for some subsequent installations (e.g. gradunwarp)
* conda: nibabel 5.2.1 installed, but nibabel <= 3.2 may be required (gradunwarp), need to test if everything works
* afni: had to upgrade R to 4.4.0 for all R packages to install (also did conda deactivate before that, not sure if necessary)
* afni: installation instructions for ubuntu 22 used ubuntu 16 installation parameter
* afni: firefox is being apt-get installed but it is only a link to snap installation (which probably does not work inside singularity) -> later figure out how to install browser and change afni installation accordingly
* afni: starting guis shows libGL error: No matching fbConfig or visuals found AND libGL error: failed to load driver: swrast (at least when running ssh from mac, seems ok sshing from MPI CBS linux)
* ants: first installed from sources but then simply used binaries compiled for ubuntu 22
* fsl: used already installed miniforge (standard installation installs miniconda, which is currently blocked at the MPI)
* freesurfer: installed version 7.3.2 as 7.4 seems to have a prefix issue in mris_convert which makes it incompatible with ciftify, most older versions do not have ubuntu packages, later consider to also have older versions (HCP recommnds FS6), possibly compare pipelines and check when 7.5 comes out wheter mris_convert behaviour changed back (or ciftify changed)
* freesurfer: in centos installations I used `export XDG_RUNTIME_DIR=/tmp/.run_$(uuidgen)`, this didn't seem to be necessary here
* cat12: cat12 server disappeared, have to try later again [used local copy of software for now]
* workbench: it was easiest to use neurodebian which had a working package for the newest version, otherwise it was very difficult to figure out all requirements -> workbench binarier are directly in /usr/bin not under /opt!
* ciftify: ciftify wants the msm version from github.com/ecr05/MSM_HOCR, not the one already installed in fsl (not sure whether thats still important with new fsl versions?), in order for ciftify to use the right version (because fsl msm is in the path) we copy the fsl msm to msm_fsl and replace it with the msm binary from github.com/ecr05/MSM_HOCR (given all this I am acqtually not sure which msm our older ciftify installation or the one in Leipzig used)
* firefox: installed firefox-esr from alternative repository (ubuntu provides snap which doesnt work inside apptainer)
* nighres: needs to be compiled (only got it working before conda install using ubuntu python, java, etc.) and then pip installed from the build directory (e.g. after setting up conda and conda environment), build directory is left in /opt/nighres_build so that it can be easily installed into new conda environments (cd /opt/nighres_build; pip install .)

when creating full container on login node (from ptmp but using normal tmp):
INFO:    Creating SIF file...
FATAL:   While performing build: while creating squashfs: create command failed: exit status 1: 
Write failed because No space left on device

FATAL ERROR:Failed to write to output filesystem

-> Got it to work on ptmp by setting:
``` bash
export APPTAINER_TMPDIR=~/ptmp/tmp
export APPTAINER_CACHEDIR=~/ptmp/tmp
```
Resulting in xattr warnings, but it seemed to work.

# Software versions
* Ubuntu 22.04, updated on 2024-08-31
* Condaforge 24.3.0
    * python
    * nipype
    * ...
    * plus further dependencies
* AFNI: latest (2024-08-31 = ...)
* R: updated to 4.4. 
* ANTS: 2.5.3
* gradunwarp: SHA ff082ef59af628806aae7f5d767bcf867674ac0c
* FSL: 6.0.7.13
* Freesurfer: 7.3.2
* Connectome workbench: 2.0.0
* MSM: v3.0FSL (from github.com/ecr05/MSM_HOCR)
* ciftify: ... (pip)
* firefox ESR: ...
* itk-snap: 4.0.2
* laynii: 2.7.0
* GNU parallel
* jq: 1.7.1
* dcm2niix: v1.0.20240202
* convert3d: 1.0.0
