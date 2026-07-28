# rep-10.1257-aer.20250166

replicateEverything study repo for:

> Hahn, R. W., Hendren, N., Metcalfe, R. D., & Sprung-Keyser, B. "A Welfare Analysis
> of Policies Impacting Climate Change." *American Economic Review* (forthcoming).
> DOI: [10.1257/aer.20250166](https://doi.org/10.1257/aer.20250166)

Source materials: [OpenICPSR deposit 239169-V1](https://www.openicpsr.org/openicpsr/project/239169/version/V1/view).

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

## LBD cost-curve rewrite (R default)

The deposit's learning-by-doing (LBD) cost-curve kernel is four Mathematica
scripts under `code/original/cost_curve/` (`.wls`), called from Stata
`cost_curve_masterfile.ado`. For **live** replication this study defaults to an
**R reimplementation** with the same CLI → CSV contract:

| Path | Location | When used |
|------|----------|-----------|
| **R (default)** | `code/cost_curve/` (`cost_curve_simple.R`, `cost_curve_masterfile.R`) | Unset env / `REPLICATE_COST_CURVE_ENGINE=r` |
| **Mathematica (original)** | `code/original/cost_curve/*.wls` | `REPLICATE_COST_CURVE_ENGINE=mathematica` |

Switching is only in the Stata bridge (`cost_curve_masterfile.ado`); policy
`.do` files are unchanged. Optional yaml step `cost_curve_mathematica` is marked
`incomplete` / `requires_engine: mathematica` (Shiny wrench on that path only).
Default LBD steps (`compute_mvpf_main`, fig_1/2/3/6, aggregates) are **not**
wrenched for Mathematica.

**Requirements for the R path:** `Rscript` on PATH; CRAN package `deSolve`
(for the NDSolve-equivalent masterfile path). Declared under `paper.dependencies`.

**Validation status:** R scripts return finite DP / Dπ / DE[, DFE] CSVs on
smoke scalars. Full numerical match to Mathematica (high WorkingPrecision /
StiffnessSwitching) is **not** claimed without side-by-side checks on a machine
with `wolframscript`. Spot-check when Mathematica is available; treat live
results as operable replication pending that audit. Full `compute_mvpf_main`
is a long ~100-policy batch - bake when you can; light figs are the practical
smoke test.

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
