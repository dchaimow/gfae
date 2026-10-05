# general fMRI analysis environment
This repository contains the Apptainer definition files of **gfae**, a container with fMRI analysis software (AFNI, FSL, FreeSurfer, ANTs, Connectome Workbench, ciftify, CAT12/SPM, LAYNII, nighres, …), and a variant with MATLAB.

**Current recipes: Ubuntu 24.04** (`gfae-base_ubuntu24.def` → `gfae_ubuntu24.def` → `gfae_matlab_ubuntu24.def`), with current software versions, see below. Built images and their history: `/home/rglz/containers/` and `gfae_log.md` there.

The repository is also a toolbox for building containers:
* `notes/pinning.md`: how and why everything is pinned, what was tested, and the build pitfalls met so far (with fixes), kept up to date with every recipe change.
* Variants of the whole recipe for other systems: `gfae_ubuntu22.def`, `gfae_matlab_ubuntu22.def` (Ubuntu 22.04, tested and pinned, see below) and `gfae_rocky9_wip.def` (Rocky Linux 9, work in progress). The Ubuntu base is not a fixed choice, but the one that has worked so far; the system is therefore part of the file names.
* Manually tested recipes for single components, as reference when building new containers: `components_ubuntu22/` (Ubuntu 22.04), `components_rocky8/` (Rocky Linux 8), `components_misc/`.
* `build.sh` (builds, tests and names images), `pins/` (version pins and lock files), `patches/` (ciftify patch), `bashrc_conda` (prompt setup used by the recipes; `bashrc` is an older version).

## Ubuntu 24.04 recipes (current)

Three definition files, each built on top of the image of the previous one (`Bootstrap: localimage`), so that the frequently changed software can be rebuilt without recompiling AFNI:

1. `gfae-base_ubuntu24.def`: Ubuntu 24.04 with all apt packages (from the Ubuntu snapshot of 2026-09-18), R 4.6.1 with AFNI's R packages, AFNI 26.2.09 (compiled, incl. SUMA).
2. `gfae_ubuntu24.def`: everything else (see below).
3. `gfae_matlab_ubuntu24.def`: MATLAB R2026a Update 5 and SPM 25.01.02 for MATLAB.

| Software | Version |
|---|---|
| conda base environment (command line tools; analysis libraries belong into project environments) | Python 3.12, numpy 2.5, nibabel 5.4, pandas 2.3, nipype 1.10, jupyterlab 4.6 (`pins/ubuntu24/`) |
| ciftify | 2.3.3 with `patches/ciftify-2.3.3-modern.patch` (current nibabel/numpy/pandas, FreeSurfer ≥ 7.4) |
| FSL | 6.0.7.23 |
| FreeSurfer | 8.2.0 (with the patch archive of 2026-06-25; incl. SynthSeg, SynthStrip, SynthMorph) |
| Connectome Workbench | 2.2.1 |
| MSM | v3.0FSL (replaces FSL's `msm`, which is kept as `msm_fsl`) |
| ANTs | 2.6.5 |
| CAT12.9 with SPM25 | standalone (`spm25`, `cat_standalone.sh`), MATLAB Runtime R2023b |
| nighres | 1.5.2 (commit f1e4264), as wheels for Python 3.11–3.13 in `/opt/nighres/wheels` (see below) |
| gradunwarp | 1.2.3+ (commit da4ceba, incl. the fixes of September 2026) |
| pydeface | 2.1.0 |
| data/BIDS tools | datalad 1.6.5 + git-annex, heudiconv 1.5.1, dcm2bids 3.3.1, BIDS validator 3.0.2 (`bids-validator-deno`), templateflow 25.1.1 |
| LAYNII | 2.10.0 |
| ITK-SNAP | 4.4.0 |
| convert3d | 1.4.4 |
| dcm2niix / niimath / jq | v1.0.20260724 / v1.0.20260924 / 1.8.2 |
| PALM | git commit 9086eff (2026-07-13), with GNU Octave 8.4 |
| Firefox ESR | 153.4.0 |

Changes compared with the Ubuntu 22.04 variant that change results: FreeSurfer 8 (recon-all with SynthSeg/SynthStrip), CAT12.9 (vs. 12.8.2), ANTs 2.6 (changed defaults of `antsRegistrationSyN*.sh`), gradunwarp fixes.

**nighres in a project environment** (inside the container): `pip install --no-deps /opt/nighres/wheels/nighres-1.5.2-cp312-cp312-linux_x86_64.whl` (wheel matching the environment's Python), plus its dependencies `nibabel scipy matplotlib psutil dipy "antspyx==0.6.3"` and `numpy<2.4` (required by ANTsPy). The container sets `JCC_JDK` to the Java runtime of nighres.

**TemplateFlow:** templates are downloaded to `~/.cache/templateflow`, unless `TEMPLATEFLOW_HOME` is set (e.g. `APPTAINERENV_TEMPLATEFLOW_HOME=<shared directory>` outside the container).

**Pinning:** all software versions are pinned, so that a rebuild produces the same software:
* the base image by digest, and all apt packages from a dated snapshot of the Ubuntu archive (`snapshot.ubuntu.com`), which apt prefers over all other sources
* the conda environments from lock files (exact package URLs with sha256, installed with micromamba without solving), generated from `pins/ubuntu24/base_env.yml` and the nighres specifications with `pins/ubuntu24/make_locks.sh`; pip packages by version with hashes, without dependencies
* all downloads by version, verified by their sha256 checksum (the build fails if a file changed); git sources by commit
* R by package version (CRAN apt repository), the R packages from a dated CRAN snapshot (Posit Package Manager)
* not pinned: the MathWorks package manager `mpm` (only available in its current version; MATLAB itself is pinned by `--release=R2026aU5`)

To update a component, change its version, URL and checksum together (`sha256sum` of the new file). `%post` stops at the first error (`set -euo pipefail`). How and why, what was tested, build pitfalls: `notes/pinning.md`.

**Building:** `build.sh` builds an image with `--fakeroot`, names it `<name>_<build time>_md5<checksum>_git<commit>.sif` (commit only if the repository has no uncommitted changes), then runs its `%test` section (`apptainer test`); if a test fails, the image is kept and the script reports `TESTS FAILED`. Builds need internet access (on nyx: the login node, in tmux, with `nice`); gfae-base takes several hours (AFNI is compiled). Build the layers in order and link each built image to the name the next definition file expects (`gfae-base.sif`, `gfae.sif`); record its sha256 as `# base-sha256:` in the next definition file, `build.sh` checks it:
```bash
./build.sh gfae-base_ubuntu24.def gfae-base
ln -sfn gfae-base_<time>_md5<…>_git<…>.sif gfae-base.sif && sha256sum gfae-base.sif   # -> base-sha256 in gfae_ubuntu24.def
./build.sh gfae_ubuntu24.def gfae
ln -sfn gfae_<…>.sif gfae.sif && sha256sum gfae.sif                                  # -> base-sha256 in gfae_matlab_ubuntu24.def
./build.sh gfae_matlab_ubuntu24.def gfae_matlab
```

## Ubuntu 22.04 variant (frozen)

`gfae_ubuntu22.def` and `gfae_matlab_ubuntu22.def` are complete, tested and pinned recipes for Ubuntu 22.04: single files without layers; the MATLAB variant is the same recipe plus MATLAB R2024b and SPM 25.01.02 for MATLAB (keep the two in sync). Build: `./build.sh gfae_ubuntu22.def gfae`. Differences from the 24.04 recipes:
* conda base environment pinned to an older state (python 3.11, numpy 1.26, nibabel 3.2.2) with unpatched ciftify 2.3.3, which needs nibabel < 4 (its report commands `ciftify_statclust_report`, `ciftify_peaktable`, `ciftify_atlas_report` don't work with pandas 2); pinned by `name==version=build` specifications (`pins/base_env_conda_pins.txt`, `pins/base_env_pip_pins.txt`, generated from an existing image with `pins/make_base_env_pins.py`), which conda still solves, instead of lock files
* AFNI 26.1.02, FSL 6.0.7.13, FreeSurfer 7.3.2, Connectome Workbench 2.0.0, ANTs 2.5.3, LAYNII 2.7.0, ITK-SNAP 4.0.2, PALM alpha119, Octave 6.4
* CAT12.8.2 with SPM12, MATLAB Runtime R2017b (needs `libncurses5`, not available on Ubuntu 24.04)
* nighres 1.5.1 built for and installed into the base environment
* Firefox ESR 140 (no longer supported since 2026-09-29)

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
Optionally adapt gfae_ubuntu24.def to your needs first, then
```
./build.sh gfae_ubuntu24.def gfae   # after building gfae-base, see "Ubuntu 24.04 recipes"
```

### 4. Start singularity container and start analyzing/developing
```
./start_dev_container.sh
```

Write scripts and code, etc. in `code/` (bound to `/opt/code/` inside container). Change and commit repo as needed.

### 5. Prepare for distribution
Create new singularity .def file based on gfae_ubuntu24.def.

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
 
