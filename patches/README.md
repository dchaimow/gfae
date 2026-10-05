# Patches

## `ciftify-2.3.3-modern.patch`

ciftify 2.3.3 (PyPI sdist, sha256 `c80c410aebcdd8653406f166608a2bd4d6b2f2b7bdc1640bd7ed6c15df45815a`) is the last
release (2020) and is no longer maintained. This patch makes it work with current versions of its dependencies, so that
it can stay in the conda base environment next to other current tools. Apply to the unpacked sdist with `patch -p1`,
then install with `pip install --no-deps`.

| Change | Needed for | Files |
|---|---|---|
| `nibabel.gifti.giftiio.read()` → `nib.load()`, unused `giftiio` imports removed | nibabel ≥ 4 (every ciftify command failed on import) | `niio.py`, `bin/ciftify_peaktable.py`, `bin/ciftify_PINT_vertices.py`, `bin/ciftify_surface_rois.py` |
| `getArraysFromIntent()` → `get_arrays_from_intent()`, `get_labeltable()` → `.labeltable` | nibabel ≥ 4 | `niio.py`, `bin/ciftify_peaktable.py` |
| `get_affine()`/`get_header()` → `.affine`/`.header`; `get_data()` → `np.asanyarray(img.dataobj)` (same values and dtype as `get_data()`) | nibabel ≥ 4/5 | `niio.py`, `bin/ciftify_falff.py` |
| `Index.get_values()` → `Index.to_numpy()` | pandas ≥ 1.0 (`ciftify_statclust_report`, `ciftify_peaktable`, `ciftify_atlas_report` were already broken with pandas 2.2) | `bin/ciftify_statclust_report.py`, `bin/ciftify_atlas_report.py`, `report.py` |
| `DataFrame.append()` → `pd.concat()` | pandas ≥ 2.0 | `bin/ciftify_statclust_report.py`, `bin/ciftify_peaktable.py` |
| set → list as `.loc` column indexer | pandas ≥ 2.0 | `bin/ciftify_PINT_vertices.py` |
| `delim_whitespace=True` → `sep=r'\s+'` | pandas ≥ 3.0 | `niio.py` |
| area column initialised as float (`-999.0`) | pandas ≥ 3.0 (no implicit upcasting) | `bin/ciftify_statclust_report.py`, `bin/ciftify_atlas_report.py` |
| `pkg_resources` → `importlib.metadata` | setuptools ≥ 82 | `config.py` |
| after `mris_convert -c`, an output named `lh.<name>`/`rh.<name>` is renamed to the expected `<name>` (only if the expected file is missing, so any FreeSurfer version works) | FreeSurfer ≥ 7.4 (`ciftify_recon_all` failed at the thickness/curvature/sulc maps); the same workaround as in HCP Pipelines (`FreeSurfer2CaretConvertAndRegisterNonlinear.sh`) | `bin/ciftify_recon_all.py` |
| invalid escape sequences (regex patterns as raw strings, backslashes in the ASCII logos doubled; output unchanged) | Python ≥ 3.12 (SyntaxWarning) | `config.py`, `utils.py`, `bin/ciftify_PINT_vertices.py` |

Not fixed: the entry point `ciftify_dlabel_report` refers to a module that is missing from the 2.3.3 release itself.

Checked (October 2026) with Python 3.12, numpy 2.5, nibabel 5.4, pandas 2.3, nilearn 0.14: all modules compile with
SyntaxWarnings as errors, and all commands load (`--help`).
