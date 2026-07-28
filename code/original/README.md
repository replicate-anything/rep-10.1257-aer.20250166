# `code/original/`

replicateEverything provenance: **author-original**, vendored unedited from the
[OpenICPSR deposit 239169-V1](https://www.openicpsr.org/openicpsr/project/239169/version/V1/view)
(Hahn, Hendren, Metcalfe & Sprung-Keyser, "A Welfare Analysis of Policies
Impacting Climate Change", AER). This is the entire deposit `code/` tree
(`ado/`, `calculations/`, `cost_curve/` `.wls`, `data_cleaning/`, `figtab/`,
`policies/harmonized/`, `wrapper/`) — every file here is the author's own code,
called by the thin `connector` runners one level up in `code/`.

**Exception:** a small number of files needed a minimal portability fix to run
on this Stata install (regex `{n}` interval quantifier not supported — see
`code/original/figtab/waterfalls_rep.do` and siblings). Those files carry
their own `* replicateEverything provenance: author-edited` header instead of
relying on this folder note; everything else in this tree is untouched.

See `folder_replication.md` § File provenance headers in the
`replicateEverything` package skills for the convention.
