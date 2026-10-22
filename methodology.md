# Methodology so far — plain-language guide

## 1. Research question

This project explores which child, maternal, and household characteristics are associated with **severe wasting among children under five** in a MICS child dataset. It is observational research: it can identify patterns and associations, but it cannot by itself prove cause and effect.

## 2. Dataset and outcome

The project uses `MICS-child-ISRC.dta`, a Stata-format child dataset. Current output tables report 22,311 eligible records and 552 severe-wasting cases. The outcome is `severe_wasting`, intended to indicate severe wasting based on weight-for-height z-score. Confirm its exact coding and cut-off in the source codebook before final reporting.

## 3. Data preparation

The Python notebook reads the Stata file, excludes records missing key survey design variables or the outcome, and excludes non-positive child weights. Variables derived from the same weight-for-height measurement (such as `whz2`, `mod_wasting`, `any_wasting`, and `wast_cat`) are excluded as predictors to avoid outcome leakage.

Some feeding and dietary variables are mainly collected for infants. They should be analyzed in the correct age subpopulation, not treated as ordinary all-child variables.

The current R output reports 22,311 eligible children / 552 cases and a complete-case core model of 22,017 children / 543 cases.

## 4. Why survey design matters

MICS is not a simple random sample. The analysis uses:
- **Weight (`chweight`):** accounts for differences in selection probabilities.
- **Cluster / primary sampling unit (`hh1`):** children from the same cluster may be more alike.
- **Stratum (`strata`):** groups used in the sample design and variance estimation.

The project includes the Stata reference:

```stata
svyset hh1 [pweight = chweight], strata(strata) singleunit(centered)
```

The R script uses the `survey` package to represent the cluster, stratum, and weight. It currently sets `survey.lonely.psu = "adjust"`, which is not automatically identical to Stata's `singleunit(centered)`. Compare estimates between R and Stata.

## 5. Analyses completed so far

### Descriptive and univariate analysis
The Python notebook summarizes the sample and explores severe-wasting prevalence across groups. It reports preliminary patterns involving age, sex, recent illness, wealth, and some infant feeding or antenatal-care variables. These one-predictor analyses do not adjust for all other characteristics.

### Multivariable regression
The existing notebook fits logistic regression models with several predictors. The R output tables on this branch include a survey-design logistic model and a modified-Poisson model.

Current provisional output:
- Design-weighted severe-wasting prevalence: **2.52%**.
- Age OR in the linear core model: **0.80 per additional year** (95% CI 0.74–0.86).
- Girls versus boys: adjusted OR **0.72** (95% CI 0.58–0.88).
- Joint test for division: p = 0.0176.
- Joint tests for wealth, education, maternal age, and toilet category are not significant at 5%.
- Natural-spline age test: p < 0.001, suggesting age is not adequately described by a straight-line effect alone.

These estimates are provisional: the local R run is blocked by Windows Application Control on `readr.dll`, and the committed outputs have not yet been independently reproduced on the current machine or compared with Stata.

### Sensitivity outcomes
Current files report weighted prevalence of about 10.37% for moderate wasting and 12.88% for any wasting. Verify the outcome definitions and coding against the codebook.

### Prediction experiment
The secondary Python notebook reports weighted random-forest ROC-AUC around 0.536 using cluster-grouped folds. The main notebook reports in-sample AUC around 0.635 for a different model/sample. These are not directly comparable and do not yet establish a reliable prediction tool.

## 6. What the results suggest

Age and sex are the clearest preliminary correlates. The age relationship appears non-linear, so a flexible age term should be considered in the primary model. The division joint test suggests geographic variation. Evidence for wealth, education, recent illness, maternal age overall, and toilet category overall is less conclusive. Isolated category-level results need caution when the overall factor test is not significant or categories are small.

No causal interpretation is supported.

## 7. Limitations and unresolved work

1. **Reproducibility:** local R execution is blocked by Windows application control. Regenerate the committed CSVs using the current script.
2. **Survey validation:** compare prevalence, standard errors, confidence intervals, coefficients, and tests with Stata `svy:`. Lonely-PSU settings may differ.
3. **Coding:** verify outcome definition, predictor labels, category references, and alternative outcomes against the source codebook.
4. **Age non-linearity:** the spline test suggests the linear age term alone may be too restrictive.
5. **Sparse events:** only 552 cases are reported in the eligible sample; small categories can yield unstable estimates.
6. **Missing data:** the core model excludes incomplete cases. Infant feeding variables have roughly 60% missingness in the full file because they are mainly collected for younger children.
7. **Notebook reproducibility:** some cells use variables not defined in the visible run order; the secondary GLM has very large coefficients and missing standard errors for some sparse terms.
8. **Prediction:** held-out PSU-grouped validation, precision–recall metrics, and held-out calibration are still needed.
9. **Multiple testing and causality:** pre-specify key hypotheses, emphasize intervals, and describe results as associations.

## 8. Next steps

1. Resolve the Windows DLL block with appropriate security/administrator support; do not disable security globally.
2. Run the R script and compare its generated CSVs with the committed outputs.
3. Compare key estimates with Stata `svy:`.
4. Use flexible age modelling and review sparse categories, missingness, and convergence.
5. Re-run the notebooks from a clean kernel and fix reproducibility/model-diagnostic issues.
6. Update interpretation only after validation.

## Bottom line

The exploratory phase has identified age and sex as important patterns to investigate and has produced an R follow-up script plus output tables. The work is not yet at final-results stage: reproducibility and comparison with Stata are essential next steps.
