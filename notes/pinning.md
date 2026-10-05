# Notes: pinning and building the gfae containers

Background, lessons and pitfalls for maintaining `gfae_ubuntu22.def` and `gfae_matlab_ubuntu22.def`. What is
pinned and how is summarized in `README.md` ("Pinning"); this file has the reasons and the history.

The pinning techniques were first developed for the fully pinned project container of the Finn et al. (2019)
replication (repository `finn-et-al-2019_replication`, `container/pfc-layer-wm-replication.def`, September 2026)
and then applied to gfae (October 2026).

## ciftify and nibabel

- ciftify 2.3.3 imports `nibabel.gifti.giftiio`, which was removed in nibabel 4: it needs nibabel < 4 (3.2.2
  works). With a newer nibabel, ciftify fails with an error about `nibabel.gifti.giftiio`.
- ciftify must stay runnable from the conda base environment (no separate environment for it). The Ubuntu 22.04
  recipes therefore keep nibabel 3.2.2 in base. The Ubuntu 24.04 recipes instead patch ciftify
  (`patches/ciftify-2.3.3-modern.patch`, see `patches/README.md`), so that it works with nibabel 5, numpy 2,
  pandas 2.3, setuptools ≥ 82 and FreeSurfer ≥ 7.4.
- Independent of nibabel, `ciftify_statclust_report`, `ciftify_peaktable` and `ciftify_atlas_report` don't work
  with pandas ≥ 1.0 (`Index.get_values()`), i.e. also not in the 22.04 images (pandas 2.2.2); the patch fixes them.
- Cause of the breakage in the unpinned recipe: later `pip install`s of unpinned packages pulled newer
  dependencies and pip silently upgraded nibabel in the base environment.

## State of earlier images

Images in `/home/rglz/containers/` (history in `gfae_log.md` there).

| Image | State |
|---|---|
| `gfae_20240902T132553Z` | ciftify works: python 3.11.9, nibabel 3.2.2, conda 24.7.1. Source of the pins in `pins/` |
| `gfae_20241105T141406Z` | as above, without the baked-in fmri-analysis |
| `gfae_20260509T025235Z` | ciftify broken: python 3.12, nibabel 5.4.2, numpy 2.4.6 (although the recipe asked for `numpy<2`), pydeface 2.1.0. AFNI 26.1.02, Workbench 2.1.0 |
| `gfae_20260520T002955Z` | **no FSL**: `/opt/fsl` contains only `bin/msm`. The FSL installation failed, and the build continued because `%post` had no `set -e` |
| `gfae_matlab_20260511T032335Z` | MATLAB R2024b Update 9, otherwise like `gfae_20260509` |

## Pinning techniques

- **Base image by digest:** `ubuntu@sha256:962f6cad…` (`jammy-20260410`). A newer 22.04 image conflicted with
  the snapshot date of the apt packages.
- **apt packages from a snapshot:** `https://snapshot.ubuntu.com/ubuntu/20260509T000000Z/`. The snapshot needs
  https: install `ca-certificates` from the regular archive first, then switch the sources (and set
  `Acquire::Check-Valid-Until "false"`).
- **conda:** Miniforge 24.3.0-0; `auto_update_conda false`; no `conda update conda` (in the 2026 images it
  updated conda to 26.x); the whole base environment from `pins/` as `name==version=build`.
- **pip:** `--no-deps --no-build-isolation`. Without `--no-build-isolation`, packages built from source (docopt,
  traits, nighres, gradunwarp) would be built against the newest setuptools/numpy from PyPI instead of the
  pinned ones (numpy 2 vs. 1.26.4 would break compiled extensions).
- **Pins of the base environment:** `pins/make_base_env_pins.py` reads `conda-meta/*.json` and the pip metadata
  of an existing image. In `gfae_20240902`, pip had replaced conda's traits 6.4.3 by 6.3.2 (nipype 1.8.5
  requires `traits<6.4`); packages installed by pip are therefore pinned in the pip file, which is installed
  after the conda packages, reproducing that state.
- **Downloads:** by version, with sha256 checks (`fetch` helper in `%post`).
- **Git sources:** by commit. The AFNI tag is checked against its commit.
- **nighres:** its `build.sh` clones its java dependencies (cbstools-public, imcn-imaging, fbpa-tools) by branch
  and runs `git pull`; the recipe clones them at the commits of `gfae_20240902`, as local branches named like
  the release branch, and deletes the `git pull` lines. (`dependencies_sha.sh` in nighres is not used by its
  build script.) The JCC extension is built with Ubuntu's python 3.10 and works in conda's python 3.11.
- **AFNI:** only the source of old versions is archived (`pub/dist/tgz/AFNI_ARCHIVE/`, no versioned binaries),
  so it is built from the git tag with CMake + ninja. Atlases/templates from a dated tarball
  (`pub/dist/atlases/afni_atlases_dist_2024_0503.tgz`), unpacked next to the programs.
- **R:** CRAN's apt repository keeps old versions (`r-base-core=4.6.0-4.2204.0`, held with `apt-mark hold`);
  AFNI's R packages via `rPkgsInstall -site` from a dated Posit Package Manager snapshot.
- **FSL:** versioned installer URL `git.fmrib.ox.ac.uk/fsl/conda/installer/-/raw/<version>/fsl/installer/fslinstaller.py`;
  the `-V 6.0.7.13` release manifest pins the FSL packages.
- **MATLAB:** `mpm install --release=R2024bU9` installs a specific update (mpm rejects updates that don't exist).
  mpm itself is only available in its current version.
- **Firefox:** Mozilla's release archive (`ftp.mozilla.org/pub/firefox/releases/<version>esr/`); the
  mozillateam PPA only keeps the current version, and Ubuntu's firefox is a snap, which does not run in apptainer.

## Still open

- `mpm` is not pinned (no versioned download).
- Downloads still depend on their URLs staying available (e.g. the MathWorks MCR installer, the FreeSurfer deb).
  Keeping the large installers locally and copying them in with `%files` (with the same checksums) would make
  builds independent of the URLs, and faster.

## Build pitfalls (and fixes)

| Problem | Fix |
|---|---|
| AFNI CMake: C compiler not found | `export CC=/usr/bin/gcc CXX=/usr/bin/g++` before cmake |
| AFNI parity check: programs missing, e.g. `3dDeconvolve` | `-DCOMP_GUI=ON` (building without the GUI drops them) |
| AFNI `COMP_RSTATS=ON`: cmake fails without R | install R before building AFNI |
| `3dinfo -ver` is not a valid version query | `afni -ver` |
| **AFNI install leaves its Python scripts without the execute bit** | `chmod a+x /opt/afni/bin/*.py`. Silent failure: `command -v` still finds them, so `%test` runs one (`1d_tool.py -ver`) |
| `AFNI_PLUGINPATH=/opt/afni` (old binary layout) points to the wrong place with the CMake install | leave it unset: AFNI looks for plugins next to its programs and in its lib directory |
| FSL installer ≥ 3.16.6 (the `--rc-file` option came with 3.16.6, not 3.21) + mamba 1.5.8: `--rc-file` error | `fslinstaller.py … --conda` |
| `set -o pipefail` + `cmd \| head -1`: SIGPIPE fails the build | `awk 'NR == 1'` instead of `head -1` |
| `set -e` does not stop at `! cmd` | use `if cmd; then …; exit 1; fi` in `%test` |
| Removing AFNI's `-dev` build packages also removes packages that depend on them (e.g. `libgl1-mesa-dev`) | gfae keeps the build packages |
| `rPkgsInstall` does not fail when a package fails to install | `%post` and `%test` load all AFNI R packages |
| `rPkgsInstall`: `@global_parse: Command not found`, nothing installed (no error) | run it with `/opt/afni/bin` on the `PATH` (it calls other AFNI scripts by name) |
| AFNI R programs: `** ERROR: Failed to load R_io.so` (exit status 78) | the CMake build installs it as `lib/librio.so`, but AFNI's R code looks for `R_io.so` on the `PATH`: link `bin/R_io.so → ../lib/librio.so`; `%test` runs `3dMVM -help` |
| `%test` prints `/root/matlab/startup.m … Read-only file system` | harmless noise from FreeSurfer's environment setup |
| apt: `libjpeg62-dev` (AFNI) conflicts with `libjpeg-turbo8-dev` (required via `libhdf5-dev` by `libgdal-dev` and `liboctave-dev`) | `libjpeg-dev`: AFNI's `find_package(JPEG 62)` also accepts libjpeg-turbo 8 |
| apt: `pkg-config` conflicts with `pkgconf`, which other packages pull in | request `pkgconf` (it provides `pkg-config`) |
| /ptmp file locking failed (`Remote I/O error`), apt could not lock its lists | was a problem of the file system, fixed by the admins (October 2026) |
| The CAT12 zip contains two folders (`CAT12.8.2_R2017b_MCR_Linux`, `CAT12.8.2_r2166_R2017b_MCR_Linux`) | the recipe uses the `r2166` one |

## Build workflow

- Apptainer has no layer cache: every build reruns all of `%post` (several hours, AFNI is compiled). The cache
  only holds the base image.
- Build with `--notest`, then run `apptainer test image.sif`: a failing test then doesn't discard the image.
- Test single stages before a full build, in a sandbox of the base image (minutes instead of hours):
  `apptainer build --fakeroot --sandbox sb docker://ubuntu@sha256:…`, then
  `apptainer exec --fakeroot --writable sb bash script.sh`. E.g. set up the apt sources as in `%post` and run
  `apt-get install -s <all packages>` to check that the package set resolves (`-s` only simulates), or run the
  Miniforge/conda/pip part to check the pins.
- Build on a node with many cores, in tmux or as a job (an interactive build dies when its ssh session closes).
- Set `APPTAINER_TMPDIR`/`APPTAINER_CACHEDIR` to a file system with enough space (`build.sh` uses `~/ptmp/tmp`).
- Keep built images archived; a deleted image means a full rebuild.
- A patch on top of an existing image (`Bootstrap: localimage`) is fast, but the image is then no longer
  described by a single definition file.
- Analysis code (e.g. fmri-analysis) is better kept outside the image (mounted or on the `PATH` at runtime), so
  that the image doesn't pin an old version of it.

## CAT12 in the container

The CAT12 standalone runs in expert mode, which makes nipype's `CAT12Segment` settings silently ineffective (see
`cat12_brainmask.md` in the replication repository). Any project using CAT12 through nipype with these images is
affected.

## Ubuntu 24.04 recipes (October 2026)

Findings while preparing `gfae-base_ubuntu24.def`, `gfae_ubuntu24.def`, `gfae_matlab_ubuntu24.def`:

- **Layers:** `Bootstrap: localimage` copies the base image; nothing is cached otherwise. Each layer writes its
  environment to its own file in `/.singularity.d/env/` (80-gfae-base.sh, 85-gfae.sh, 87-gfae-matlab.sh). With
  Apptainer 1.3.6, a `%environment` section of a layer is appended to that of the base (not replaced), and the
  environment of the base is active during the layer's `%post`. `build.sh` checks the base image against
  `# base-sha256:` in the definition file.
- **apt on noble:** the sources are in `/etc/apt/sources.list.d/ubuntu.sources` (deb822), not `sources.list`.
  Installing `ca-certificates` from the regular archive (needed for the https-only snapshot) also upgraded `openssl`
  and `libssl3t64` beyond the snapshot, so `libssl-dev` was not installable. Fix: pin the snapshot with
  `Pin-Priority: 1001` and `apt-get --allow-downgrades dist-upgrade`, which returns every package to its snapshot
  version. Package renames: t64 libraries (`libgtk2.0-0t64`, `libasound2t64`, `libglw1t64-mesa`, …),
  `libglut3.12`/`libglut-dev` (freeglut3), `plocate` (mlocate); no `libncurses5` (needed by MATLAB Runtime R2017b),
  no `python3-jcc`.
- **conda lock files:** `conda list --explicit --sha256` writes `URL#<sha256>` (no `sha256:` prefix); micromamba
  2.9 installs such files without solving and rejects a wrong hash (tested). The base environment is created
  directly with micromamba (no Miniforge); it contains `conda`, which FSL's installer (3.21.0, `--miniconda
  /opt/conda --conda`) uses (tested with FSL 6.0.7.23). Solve with `CONDA_OVERRIDE_GLIBC=2.39` on other hosts.
- **nighres:** conda-forge's `jcc` 3.15 requires OpenJDK 8 (its own); `JAVA_HOME`/`JCC_JDK` = the environment
  prefix. The built wheel is tagged `py3-none-any` although its extension is version specific: retag it with
  `python -m wheel tags --python-tag cp3XX --abi-tag cp3XX --platform-tag linux_x86_64`. nighres imports
  `ants.utils` at import time: ANTsPy 0.6.3 still has it (0.5.2 is no longer on PyPI), but requires numpy < 2.4;
  with numpy 2.3 nighres works (tested: VM start, `probability_to_levelset` on synthetic data), despite its
  declared `numpy<2`. The old extension (built with Python 3.10 headers) cannot work in Python ≥ 3.12.
- **FreeSurfer 8.2 vs. ciftify** (tested on `bert` with FreeSurfer 7.3.2 and 8.2.0, `mris_convert`, `mri_convert`,
  `mri_info` and the whole `ciftify_recon_all` incl. MSM): `mris_convert -c` writes `lh.<name>` instead of `<name>`
  (and with a relative output name into the input's directory), still with exit status 0; this is what broke
  ciftify with FreeSurfer ≥ 7.4, fixed in the patch by renaming. Surfaces, maps, volumes and `mri_info` output are
  identical; in parcellations (dlabel), FreeSurfer 8.2 carries the annotation's "Unknown" label over (7.3.2: no
  label), which shifts the label keys by one; all regions are identical.
- **FreeSurfer patches:** `fs820_updates.sh` downloads the current patch archive (name in `.fs820_updates/default`)
  and asks before each file; instead, the recipe applies the pinned `patch_data_20260625.tgz` directly (files of
  `ubuntu24_x86_64/`, md5 from `<file>.checksum`, copied if installed or marked `<file>.force`).
- **CAT12.9 standalone:** `CAT12.9_R2023b_MCR_Linux.zip` contains SPM12 and SPM25 standalones (both Runtime
  R2023b); SPM25 contains CAT12.9 (`spm25 eval "cat_version"` prints `CAT12.9`; CAT's `cat_standalone.sh` uses
  `run_spm25.sh`). The MATLAB Runtime installer (destination `/opt/mcr`) creates `/opt/mcr/R2023b`.
- **mpm:** `--release=R2026aU5` (latest update in October 2026; `R2026aU6` is rejected).
- **PALM:** no release archives after alpha119; the git repository has the gifti code in `lib/@gifti/private`.
  The `palm` launcher falls back to `octave-cli` on the PATH if its configured `OCTAVEBIN` does not exist.
- **Testing without building:** most of the above was tested on /ptmp before any image build: an Ubuntu 24.04
  sandbox for apt (`apt-get install -s`), micromamba environments for conda/pip/nighres, FreeSurfer 8.2 unpacked
  from its deb (`ar p … data.tar.zst | zstd -dc | tar -x`) and run inside the existing jammy image, the MATLAB
  Runtime installed on the host.
