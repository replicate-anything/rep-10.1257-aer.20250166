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
| `policy_details_v3.xlsx` | deposit `data/` root | `fig_4`/`fig_7`/`fig_8`/`tab_1`/`tab_2` (policy labels/categories; `${code_files}/policy_details_v3.xlsx`) |
| `1_assumptions/` | `data/1_assumptions/` (34 MB) | Every policy do-file (assumptions, program-specific parameters, EV/battery data, marginal damages) |
| `2a_causal_estimates_papers/` | `data/2a_causal_estimates_papers/` (3.4 MB) | Every policy do-file (causal estimates transcribed from the underlying papers) |
| `5_graphs/figures_data/` | same | `fig_2`/`fig_3` (`wind_papers.xlsx`), `fig_5` (`Nudge Estimates.xlsx`), `contour_test.csv` (Phase 2) |
| `6_tables/tables_templates/` | same | `tab_1`/`tab_2` output formatting (author Excel templates) |
| `0_log/`, `2b_causal_estimates_draws/`, `3_bootstrap_draws/`, `5_graphs/figures_main/`, `6_tables/tables_main/` | empty placeholders in the deposit | Writable staging dirs the author scripts expect to already exist; populated by running figure / table steps |
| `4_results/` | empty placeholder in the deposit | **Regenerable author staging** (gitignored). `metafile.do` writes timestamped `<ts>__<nrun>/` folders; connectors keep fixed aliases `full_current_193/` and `full_current_no_lbd/` for hardcoded figtab paths. Claimed DAG sinks: `outputs/compute_mvpf_*/compiled_results_*.dta`. `init_study_paths.do` restores aliases from those outputs when missing. Empty `__resetting_globals` dirs from `macros` / `warm_session` are safe to delete. |

Deliberately **excluded** from this v1 scope (Phase 2 - see `onboarding_notes/openicpsr-aer-239169.md`):

- `policies/robustness` policy do-files and `data/7_publication_bias/` - only used by the
  MATLAB-dependent publication-bias branch and the robustness-only appendix numbers.
- `bootstrapping/` folder - the 1000-rep bootstrap (feeds only an appendix CI table).

## `policy_details_v3.xlsx`

Present at deposit **`data/policy_details_v3.xlsx`** (not under `1_assumptions/`).
Author scripts read `${code_files}/policy_details_v3.xlsx` and
`code_files = dropbox = data/`, so the study path is `data/policy_details_v3.xlsx`.
Copied from `original_studies/239169-V1/data/policy_details_v3.xlsx` after early
onboarding incorrectly concluded it was absent.
