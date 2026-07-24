# Data

Source: [OpenICPSR deposit 239169-V1](https://www.openicpsr.org/openicpsr/project/239169/version/V1/view)
(Hahn, Hendren, Metcalfe & Sprung-Keyser, "A Welfare Analysis of Policies Impacting
Climate Change", AER). No public per-file fetch API (the project page is behind a
Cloudflare/JS bot check), so data is committed here (Pattern B) rather than fetched
live at run time. Full deposit is ~40 MB; everything below is well under GitHub's
50 MB soft limit.

## What's committed here (and why)

| Path | From deposit | Needed by |
|---|---|---|
| `1_assumptions/` | `data/1_assumptions/` (34 MB) | Every policy do-file (assumptions, program-specific parameters, EV/battery data, marginal damages) |
| `2a_causal_estimates_papers/` | `data/2a_causal_estimates_papers/` (3.4 MB) | Every policy do-file (causal estimates transcribed from the underlying papers) |
| `5_graphs/figures_data/` | same | `fig_2`/`fig_3` (`wind_papers.xlsx`), `fig_5` (`Nudge Estimates.xlsx`), `contour_test.csv` (Phase 2) |
| `6_tables/tables_templates/` | same | `tab_1`/`tab_2` output formatting (author Excel templates) |
| `0_log/`, `2b_causal_estimates_draws/`, `3_bootstrap_draws/`, `4_results/`, `5_graphs/figures_main/`, `6_tables/tables_main/` | empty placeholders in the deposit | Writable staging dirs the author scripts expect to already exist; populated by running `compute_mvpf_main` / figure / table steps |

Deliberately **excluded** from this v1 scope (Phase 2 - see `onboarding_notes/openicpsr-aer-239169.md`):

- `policies/robustness` policy do-files and `data/7_publication_bias/` - only used by the
  MATLAB-dependent publication-bias branch and the robustness-only appendix numbers.
- `bootstrapping/` folder - the 1000-rep bootstrap (feeds only an appendix CI table).

## Known gap: `policy_details_v3.xlsx` is missing from the deposit

`figtab/mvpf_plots.do`, `figtab/excel_MVPF_tables_condensed.do`, and
`figtab/cost_per_ton.do` all `import excel "${code_files}/policy_details_v3.xlsx"` and
`merge m:1 program using ..., keep(3)` (an inner join) against it for policy labels,
`broad_category`, and `extended` flags - `excel_MVPF_tables_condensed.do` even
`assert`s the merged sample size. The author README lists this same file as
"Appendix Table 1" (Table 3 in the README), but **it does not exist anywhere in the
unzipped OpenICPSR 239169-V1 archive** under this or any other name we could find.

This blocks `fig_4`, `fig_7`, `fig_8`, `tab_1`, and `tab_2` (see the `KNOWN GAP`
comment in each `code/*.do` runner). We have not fabricated a replacement - the file
should be sourced from the authors or a future OpenICPSR version. `clean_data`,
`macros`, `compute_mvpf_main`, `compute_mvpf_no_lbd`, and the light figures
(`fig_1`, `fig_2`, `fig_3`, `fig_5`, `fig_6`) do not need it.
