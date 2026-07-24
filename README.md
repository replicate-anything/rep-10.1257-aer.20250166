# rep-10.1257-aer.20250166

replicateEverything study repo for:

> Hahn, R. W., Hendren, N., Metcalfe, R. D., & Sprung-Keyser, B. "A Welfare Analysis
> of Policies Impacting Climate Change." *American Economic Review* (forthcoming).
> DOI: [10.1257/aer.20250166](https://doi.org/10.1257/aer.20250166)

Source materials: [OpenICPSR deposit 239169-V1](https://www.openicpsr.org/openicpsr/project/239169/version/V1/view).

## Status: v1 scaffold (main text only)

This repo declares a **wrapper-script-granularity** DAG (14 steps) covering Table 1,
Table 2, and Figures 1-8 of the main text. It deliberately does **not** cover the
~19 appendix tables, ~11 appendix figures, the 1000-rep bootstrap (App. Table 4 CIs),
or the MATLAB-dependent publication-bias branch - those are Phase 2. See
`onboarding_notes/openicpsr-aer-239169.md` in the monorepo for the full onboarding
history and rationale.

The original deposit has ~100 policy-specific `.do` files (one per climate/energy
policy in the sample) feeding a small number of wrapper scripts
(`wrapper/metafile.do`, `figtab/*.do`) - **not** one script per table/figure. This
repo mirrors that structure rather than inventing ~100 DAG nodes.

## Known limitations (read before running)

1. **Mathematica required for the headline numbers.** ~10 of the ~100 policy
   do-files (EV/hybrid/solar learning-by-doing) shell out to `wolframscript`
   (`code/original/cost_curve/*.wls`). `compute_mvpf_main` will fail on those
   policies without Mathematica installed. There is no all-Stata substitute that
   reproduces the *headline* Table 1/Figures numbers - turning learning-by-doing off
   entirely (`compute_mvpf_no_lbd`) reproduces a documented **robustness**
   specification instead.
2. **`policy_details_v3.xlsx` is missing from the OpenICPSR deposit.** `fig_4`,
   `fig_7`, `fig_8`, `tab_1`, and `tab_2` all hard-depend on this file (policy labels
   + categories) via an inner `merge`, and it is not present anywhere in 239169-V1
   despite being referenced repeatedly in the author README. See `data/README.md`
   for detail. These 5 steps cannot run until it is sourced from the authors/OpenICPSR.
3. **No baked "gold" outputs shipped in the deposit.** `data/4_results`,
   `5_graphs/figures_main`, `6_tables/tables_main`, etc. are empty placeholders in
   the original deposit - there is no in-repo precomputed number/figure/table to
   check against. Substantive tests will need to reference the **published paper**
   (once accessible) rather than an in-deposit artifact.
4. **Nothing in `code/` has been executed yet.** No Stata, MATLAB, or Mathematica
   is installed on the machine that built this scaffold - see
   `onboarding_notes/openicpsr-aer-239169.md` for the probe results and the exact
   point every step currently fails at.

## Layout

```
replication.yml          full metadata + steps: DAG (well-commented, see file)
code/
  helpers/init_study_paths.do   sets ${github}/${dropbox}/... globals for the
                                 unmodified author code (used by every runner)
  clean_data.do, macros.do, compute_mvpf_main.do, compute_mvpf_no_lbd.do
  fig_1.do ... fig_8.do, tab_1.do, tab_2.do        thin per-step runners
  original/                unmodified author code (ado/, calculations/,
                            cost_curve/, data_cleaning/, figtab/, policies/
                            harmonized/, wrapper/) - ~2 MB, needed because
                            metafile.do's "all_programs" loops over every
                            policy do-file in policies/harmonized
data/
  1_assumptions/, 2a_causal_estimates_papers/      root inputs (committed, ~38 MB)
  5_graphs/figures_data/, 6_tables/tables_templates/   small shipped inputs
  0_log/, 2b_.../, 3_.../, 4_results/, 5_graphs/figures_main/,
  6_tables/tables_main/                            writable staging dirs (empty)
  README.md                 what's included/excluded + the policy_details_v3 gap
outputs/                    replicateEverything DAG artifacts (empty until baked)
tests/testthat/              smoke tests (yaml + code links; full runs skipped -
                              no Stata/Mathematica in CI yet)
```

## Running (once Stata/Mathematica are available)

```r
library(replicateEverything)
options(replicateEverything.registry_root = "../registry",
        replicateEverything.study_folders_root = "..")
check_study_compatibility("10.1257/aer.20250166")
run_replication("10.1257/aer.20250166", "clean_data", given = "nothing")
run_replication("10.1257/aer.20250166", "fig_1")   # light: single-policy recompute
build_study_outputs("rep-10.1257-aer.20250166", install_deps = TRUE)  # everything
```
