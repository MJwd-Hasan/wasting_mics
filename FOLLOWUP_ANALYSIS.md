# Follow-up survey-design analysis

This repository now includes `analysis_followup.R`, a reproducible follow-up pipeline intended to address the statistical and reproducibility issues identified in `eda.ipynb`.

## What it adds

The script writes separate CSV outputs for:

- Sample flow, event counts, and overall design-weighted severe-wasting prevalence.
- Design-based subgroup prevalence estimates and uncertainty.
- Predictor missingness and complete-case sample flow.
- A survey-design-based logistic regression with odds ratios and confidence intervals.
- A modified Poisson model for adjusted prevalence ratios.
- Joint Wald tests for categorical terms.
- Exploratory univariate survey tests with Benjamini–Hochberg FDR adjustment.
- An age non-linearity check using a natural spline and predicted age curve.
- A small set of hypothesis-driven interactions, where the required variables exist.
- In-sample weighted calibration deciles and Brier score.
- Alternative-endpoint prevalence checks for `mod_wasting` and `any_wasting`, if present.

The script deliberately does **not** automatically fit a multilevel model or claim out-of-sample predictive performance. Those require additional model assumptions and validation design.

## Run it

From the repository root, with R installed and the dataset available locally:

```bash
Rscript analysis_followup.R MICS-child-ISRC.dta outputs
```

Install the required packages once:

```r
install.packages(c("haven", "dplyr", "survey", "splines"))
```

The script writes results under `outputs/`. Do not commit restricted or identifiable microdata or generated files containing sensitive row-level data.

## Survey design and interpretation

The script specifies:

- PSU / cluster: `hh1`
- Stratum: `strata`
- Weight: `chweight`
- Lonely-PSU option: `survey.lonely.psu = "adjust"`

The existing Stata reference uses `singleunit(centered)`. Confirm that the R handling and key point estimates, standard errors, confidence intervals, and tests match Stata's `svy:` results before publication. The exact behavior of Taylor-linearized variance estimates depends on design metadata and coding; do not describe the Python cluster-robust GLM as a full complex-survey variance estimator.

## Important safeguards

1. `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat` are not used as predictors of `severe_wasting`. The alternative wasting outcomes are examined only as separate sensitivity endpoints.
2. The model is limited to the available candidate predictors and complete cases; inspect `sample_flow.csv` and `missingness.csv` before interpreting results.
3. The parity category recoding is only a sensitivity/estimation convenience for the sparse zero category. Check the source codebook and report the recoding explicitly.
4. Interaction tests are exploratory and should be interpreted with caution given the small number of severe-wasting events. Avoid data-driven interaction fishing.
5. The calibration table and Brier score are **in-sample** diagnostics, not evidence of generalizable predictive performance. For prediction, add PSU-grouped cross-validation and report weighted ROC-AUC, precision–recall metrics, and calibration on held-out clusters.
6. FDR-adjusted univariate tests are exploratory; prioritize effect sizes and confidence intervals over significance thresholds.
7. Alternative outcome coding must be verified against the source codebook before using the sensitivity outputs.

## Recommended validation before writing results

- Run the original notebook from a clean kernel and repair its undefined variables separately; this script does not silently rewrite notebook history.
- Compare overall and subgroup prevalence with Stata `svy:` results using the documented design.
- Compare coefficients, standard errors, and confidence intervals for a pre-specified core model in Stata and R.
- Review sparse cells, model convergence, complete-case loss, and any warnings before reporting.
- Treat association estimates as observational associations, not causal effects.
