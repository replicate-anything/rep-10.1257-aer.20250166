# rep-10.1257-aer.20250166

replicateEverything study repo for:

> Hahn, R. W., Hendren, N., Metcalfe, R. D., & Sprung-Keyser, B. "A Welfare Analysis
> of Policies Impacting Climate Change." *American Economic Review* (forthcoming).
> DOI: [10.1257/aer.20250166](https://doi.org/10.1257/aer.20250166)

Source materials (dual credit; first is primary for icons / metadata):

1. [Policy-Impacts/mvpf-climate](https://github.com/Policy-Impacts/mvpf-climate)
   (public GitHub; passwordless; includes `policies/robustness/` and
   precomputed `figures_data/avgs_*.dta` absent from the OpenICPSR zip)
2. [OpenICPSR deposit 239169-V1](https://www.openicpsr.org/openicpsr/project/239169/version/V1/view)
   (AER official deposit; Cloudflare-gated)

Study `data/` is Pattern B (committed). GitHub is the materials credit and
gap-fill source for robustness / avgs inputs — not a live fetch step replacing
the committed OpenICPSR-shaped tree.

## Bake timings (audit timeout fallback)

Successful step bake durations are recorded in
`outputs/replication_timings.json`. When the registry audit times out on a
step, Shiny hourglass / long-run warnings prefer that last-known bake time
over the audit patience cap alone (package helpers
`record_study_replication_timing()` / `lookup_study_replication_timing()`).

## Figure bake status (main text)

| Step | Status |
|------|--------|
| fig_1, fig_5, fig_6 | Baked |
| fig_4, fig_7, fig_8 | Baked (after GitHub `avgs_*.dta`) |
| fig_2 | Waterfall 2a baked; 2b elasticity panel still blocked by Windows Stata→Rscript LBD shell in this environment (PATH injection landed in package 0.7.24; re-bake when green) |
| fig_3 | Fig 3b solar elasticities filled from author GitHub bake; 3a waterfall pending same LBD shell fix as fig_2 |
| tab_1 / tab_2 | Not rebaked this pass (tables excluded) |

## Status: v1 scaffold (main text only)

This repo declares a **wrapper-script-granularity** DAG covering Table 1,
Table 2, and Figures 1-8 of the main text. It deliberately does **not** cover the
~19 appendix tables, ~11 appendix figures, the 1000-rep bootstrap (App. Table 4 CIs),
or the MATLAB-dependent publication-bias branch - those are Phase 2. See
`onboarding_notes/openicpsr-aer-239169.md` in the monorepo for the full onboarding
history and rationale.

The original deposit has ~100 policy-specific `.do` files (one per climate/energy
policy in the sample) feeding a small number of wrapper scripts
(`wrapper/metafile.do`, `figtab/*.do`) - **not** one script per table/figure. This
repo mirrors that structure rather than inventing ~100 DAG nodes.

## LBD cost-curve rewrite (R default) - a two-step DAG split, not one multilingual step

The deposit's learning-by-doing (LBD) cost-curve kernel is four Mathematica
scripts under `code/original/cost_curve/` (`.wls`), called from Stata
`cost_curve_masterfile.ado`. For **live** replication this study defaults to an
**R reimplementation** with the same CLI → CSV contract, wired as its own
`replication.yml` step rather than an env-var toggle buried inside a Stata
step:

| Path | DAG step | Location | Status |
|------|----------|----------|--------|
| **R (default)** | `cost_curve_data_r` (`engine: r`) | `code/cost_curve/` (`cost_curve_simple.R`, `cost_curve_masterfile.R`, driven by `build_cost_curve_data.R`) | Runnable |
| **Mathematica (original)** | `cost_curve_mathematica` (`engine: stata`, `requires_engine: mathematica`) | `code/original/cost_curve/*.wls` | `incomplete: true` - Shiny wrench (missing `wolframscript`) |

`cost_curve_data_r` is a genuine, standalone step: it calls the same two R
scripts Stata's `cost_curve_masterfile.ado` shells to (with
`REPLICATE_COST_CURVE_ENGINE` unset / `r`, the live default) on two
illustrative calibration scenarios, and writes
`outputs/cost_curve_data_r/lbd_cost_curve.csv`. `compute_mvpf_main` and the
LBD figures (`fig_1`, `fig_2`, `fig_3`, `fig_6`) declare it as an additional
`parents:` entry, so `describe_study_dag()` shows an explicit
`LBD cost-curve data (R) → Compute MVPF (main, LBD on) → ...` edge. Those
Stata steps still shell to the same R scripts **per policy** at runtime
(~40 calls across ~10 policy do-files, with parameters computed from
Stata-merged, policy-specific data) - that live-`.ado` dispatch is unchanged
and cannot be fully precomputed outside Stata without re-deriving each
policy's locals in R; `cost_curve_data_r` is the standalone build/validation
gate for the shared R kernel, not a full precompute of every per-policy call.
Set `REPLICATE_COST_CURVE_ENGINE=mathematica` to force the original `.wls`
path inside those same Stata steps (only `cost_curve_mathematica` itself
carries the Mathematica wrench - the default R path is never wrenched).

**Requirements for the R path:** `Rscript` on PATH; CRAN package `deSolve`
(for the NDSolve-equivalent masterfile path). Declared under
`paper.dependencies` and on the `cost_curve_data_r` step itself.

**Validation status:** R scripts return finite DP / Dπ / DE[, DFE] CSVs on
smoke scalars. Side-by-side numerical match to Mathematica is optional (the
Mathematica path works when `wolframscript` is available; live default stays
R). Spot-check when Mathematica is available; treat live results as operable
replication pending that audit. Full `compute_mvpf_main` is a long ~100-policy
batch - bake when you can; light figs are the practical smoke test.

> Note: Shiny does not yet render free-text study notes (`paper.abstract`). The
> rewrite explanation lives here in the README (and in `paper.abstract` for
> future wiring). Package UI change is out of scope for this study-only update.

## Known limitations (read before running)

1. **`policy_details_v3.xlsx` is committed** at `data/policy_details_v3.xlsx`
   (deposit data root = `${code_files}`).
2. **No baked "gold" outputs shipped in the deposit.** Checked
   `original_studies/239169-V1/data/4_results` (placeholder.txt only) and study
   `outputs/` (fig_5 / prep markers). Substantive checks should use the
   **published paper**, not an in-deposit artifact, until you bake locally.
3. **`compute_mvpf_no_lbd`** remains the Stata-only **robustness** twin (LBD
   off), not a substitute for headline LBD-on numbers.
4. **Original Mathematica path** still needs `wolframscript` on PATH when
   `REPLICATE_COST_CURVE_ENGINE=mathematica`.

## Layout

```
replication.yml          full metadata + steps: DAG (well-commented, see file)
code/
  helpers/init_study_paths.do   sets ${github}/${dropbox}/... globals
  helpers/require_cost_curve_engine.do   Rscript or wolframscript probe
  cost_curve/                   R LBD kernel (default live path)
  cost_curve/build_cost_curve_data.R   cost_curve_data_r step entry point
  cost_curve_mathematica.do     optional Mathematica path probe (greyed step)
  clean_data.do, macros.do, compute_mvpf_main.do, compute_mvpf_no_lbd.do
  fig_1.do ... fig_8.do, tab_1.do, tab_2.do
  original/                     unmodified author code (incl. cost_curve/*.wls)
data/                       root inputs + writable staging (see data/README.md)
outputs/                    DAG artifacts
tests/testthat/             smoke tests (yaml + code links)
```

## Running

```r
library(replicateEverything)
options(replicateEverything.registry_root = "../registry",
        replicateEverything.study_folders_root = "..")
check_study_compatibility("10.1257/aer.20250166")
run_replication("10.1257/aer.20250166", "clean_data", given = "nothing")
run_replication("10.1257/aer.20250166", "fig_1")   # light: single-policy + R LBD
# Sys.setenv(REPLICATE_COST_CURVE_ENGINE = "mathematica")  # optional original path
```

Or from a shell before Stata:

```bash
# default
unset REPLICATE_COST_CURVE_ENGINE
# or force Mathematica:
export REPLICATE_COST_CURVE_ENGINE=mathematica
```
