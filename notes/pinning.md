# Notes: pinning and building the gfae containers

Background, lessons and pitfalls for maintaining `gfae_ubuntu22.def` and `gfae_matlab_ubuntu22.def`. What is
pinned and how is summarized in `README.md` ("Pinning"); this file has the reasons and the history.

The pinning techniques were first developed for the fully pinned project container of the Finn et al. (2019)
replication (repository `finn-et-al-2019_replication`, `container/pfc-layer-wm-replication.def`, September 2026)
and then applied to gfae (October 2026).

## ciftify and nibabel

- ciftify 2.3.3 imports `nibabel.gifti.giftiio`, which was removed in nibabel 4: it needs nibabel < 4 (3.2.2
  works). With a newer nibabel, ciftify fails with an error about `nibabel.gifti.giftiio`.
- ciftify must stay runnable from the conda base environment (no separate environment for it). As long as
  ciftify 2.3.3 is used, the base environment therefore has to keep nibabel < 4: packages that require newer
  nibabel (e.g. pydeface ≥ 2.1.0, which requires nibabel ≥ 5.3) must stay at older versions in base, or be
  installed into a separate environment themselves.
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
| FSL installer ≥ 3.21 + mamba 1.5.8: `--rc-file` error | `fslinstaller.py … --conda` |
| `set -o pipefail` + `cmd \| head -1`: SIGPIPE fails the build | `awk 'NR == 1'` instead of `head -1` |
| `set -e` does not stop at `! cmd` | use `if cmd; then …; exit 1; fi` in `%test` |
| Removing AFNI's `-dev` build packages also removes packages that depend on them (e.g. `libgl1-mesa-dev`) | gfae keeps the build packages |
| `rPkgsInstall` does not fail when a package fails to install | `%test` loads all AFNI R packages |
| `%test` prints `/root/matlab/startup.m … Read-only file system` | harmless noise from FreeSurfer's environment setup |
| The CAT12 zip contains two folders (`CAT12.8.2_R2017b_MCR_Linux`, `CAT12.8.2_r2166_R2017b_MCR_Linux`) | the recipe uses the `r2166` one |

## Build workflow

- Apptainer has no layer cache: every build reruns all of `%post` (several hours, AFNI is compiled). The cache
  only holds the base image.
- Build with `--notest`, then run `apptainer test image.sif`: a failing test then doesn't discard the image.
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
