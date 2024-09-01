# Generic fmri analysis environment
This is a repo template for container based fMRI analysis development. `gfae.def` defines a apptainer container including a set of useful fMRI analysis software. `container_resource` contains singularity definition files for individual software packages, meant to assist in adapting `gfae.def` to your own needs. Similarly there are folder groupoing definition files for individual components for a specific gfae version (e.g. base image).

Currently `gfae.def` is based on ubuntu 22.04 and contains:
* conda via mambaforge, with packages installed in base environment (here only explicitly conda installed packages):
  * python 3.11.9
  * nipype 1.8.5
  * notebook 7.2.2
  * jupyterlab 4.2.5
  * numpy 1.26.4 (gradunwarp, ciftify, afni)
  * scipy 1.14.1 (gradunwarp, ciftify, afni)
  * nibabel 5.2.1 (gradunwarp, ciftify)
  * seaborn 0.13.2 (ciftify)
  * nilearn 0.10.2 (ciftify)
  * matplotlib 3.9.1 (ciftify, afni)
  * pandas 2.2.2 (ciftify)
  * flask 3.0.3 (afni)
  * flask-cors 5.0.0 (afni)
* FSL 6.0.7.13
* FreeSurfer 7.3.2 (license.txt required to be present in user home directory)
* CAT12.8.2 r2166 and SPM12 r7771 together with Matlab 2017b (v93) runtime
* gradunwarp 1.2.2 (Human Connectome Project version, latest git commit)
* ciftify 2.3.3
* AFNI 24.2.04 (latest)
* ANTs 2.5.3
* ITK-snap 4.0.2
* convert3d 1.0.0
* dcm2niix v1.0.20240202
* pydeface 2.0.2
* laynii 2.7.0
* firefox 115.13.0esr
* gnu parallel 20210822
* emacs 27.1
* vim 8.2
* nighres 1.5.1
* dchaimow/fmri-analysis 6eaf0cd


See also todo.md for installation notes and issues.


## General usage
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
 
