# Generic fmri analysis environment
This is a repo template for container based fMRI analysis development. `gfae.def` defines a singularity container including a set of useful fMRI analysis software. `container_resource` contains singularity definition files for individual software packages, meant to assist in adapting `gfae.def` to your own needs.

Currently `gfae.def` is based on centos 7 and contains:
* conda via mambaforge, with packages installed in base environment (here only explicitly conda installed packages):
  * python
  * nipype
  * notebook
  * jupyterlab
  * numpy (gradunwarp, ciftify, afni)
  * scipy (gradunwarp, ciftify, afni)
  * nibabel=3.2 (gradunwarp, ciftify)
  * seaborn>=0.9.0 (ciftify)
  * nilearn>=0.5.0 (ciftify)
  * matplotlib>=2.2.2 (ciftify, afni)
  * pandas>=0.23.4 (ciftify)
  * flask>=2.1.2 (afni)
  * flask-cors>=3.0.10 (afni)
* FSL 6.0.7.1
* FreeSurfer 7.4.1
* CAT12 and SPM12 together with Matlab 2017b runtime
* gradunwarp (Human Connectome Project version)
* ciftify
* AFNI (neurodocker installation without all R packages)
* ANTs
* ITK-snap 3.8
* c3d
* dcm2niix
* laynii
* dchaimow/fmri-analysis
* firefox

To consider:
* full AFNI installation with R packages
* ITK-snap 4 (may require newer base system)
* nighres
* code editor (e.g. emacs)

## General usage
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
 
